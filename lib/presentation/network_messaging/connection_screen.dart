import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:mqtt_client/mqtt_client.dart';
import 'package:mqtt_client/mqtt_server_client.dart';

class ConnectionScreen extends StatefulWidget {
  final String protocol;
  const ConnectionScreen({super.key, required this.protocol});

  @override
  State<ConnectionScreen> createState() => _ConnectionScreenState();
}

class _ConnectionScreenState extends State<ConnectionScreen> {
  final TextEditingController ipController = TextEditingController();
  final TextEditingController portController = TextEditingController();
  final TextEditingController messageController = TextEditingController();
  final List<String> messages = [];

  Socket? tcpSocket;
  RawDatagramSocket? udpSocket;
  MqttServerClient? mqttClient;
  bool connected = false;

  void log(String msg) => setState(() => messages.add(msg));

  Future<void> showErrorDialog(String title, String message) async {
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text("OK"),
          )
        ],
      ),
    );
  }

  Future<void> connect() async {
    final ip = ipController.text.trim();
    final portText = portController.text.trim();

    if (ip.isEmpty || portText.isEmpty) {
      showErrorDialog("Missing Information", "Please enter both IP and Port.");
      return;
    }

    int? port = int.tryParse(portText);
    if (port == null) {
      showErrorDialog("Invalid Port", "Please enter a valid numeric port.");
      return;
    }

    try {
      if (widget.protocol == "TCP") {
        tcpSocket = await Socket.connect(ip, port);
        connected = true;
        tcpSocket!.listen(
          (Uint8List data) => log("Server: ${String.fromCharCodes(data)}"),
          onError: (e) => showErrorDialog("TCP Error", e.toString()),
          onDone: () => log("Connection closed by server."),
        );
      } else if (widget.protocol == "UDP") {
        udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
        connected = true;
        udpSocket!.listen((event) {
          if (event == RawSocketEvent.read) {
            final datagram = udpSocket!.receive();
            if (datagram != null) {
              log("Server: ${String.fromCharCodes(datagram.data)}");
            }
          }
        });
      } else if (widget.protocol == "MQTT") {
        mqttClient = MqttServerClient('test.mosquitto.org',
            'flutter_mqtt_${DateTime.now().millisecondsSinceEpoch}');
        mqttClient!.logging(on: false);
        mqttClient!.onConnected = () => log("✅ Connected to MQTT broker!");
        mqttClient!.onDisconnected = () => log("❌ Disconnected from MQTT.");
        await mqttClient!.connect();
        mqttClient!.subscribe('test/topic', MqttQos.atMostOnce);
        mqttClient!.updates!.listen((messagesList) {
          final msg =
              (messagesList[0].payload as MqttPublishMessage).payload.message;
          final messageString = MqttPublishPayload.bytesToStringAsString(msg);
          log("MQTT: $messageString");
        });
        connected = true;
      }

      setState(() {});
      log("✅ Connected successfully via ${widget.protocol}");
    } catch (e) {
      await showErrorDialog("Connection Error", e.toString());
    }
  }

  void sendMessage() {
    final msg = messageController.text.trim();
    if (msg.isEmpty) {
      showErrorDialog("Empty Message", "Please type a message before sending.");
      return;
    }
    if (!connected) {
      showErrorDialog("Not Connected", "Connect to a server first.");
      return;
    }

    log("You: $msg");

    try {
      if (widget.protocol == "TCP") {
        tcpSocket?.write(msg);
      } else if (widget.protocol == "UDP") {
        udpSocket?.send(
          msg.codeUnits,
          InternetAddress(ipController.text),
          int.parse(portController.text),
        );
      } else if (widget.protocol == "MQTT") {
        final builder = MqttClientPayloadBuilder()..addString(msg);
        mqttClient?.publishMessage(
          'test/topic',
          MqttQos.atMostOnce,
          builder.payload!,
        );
      }
      messageController.clear();
    } catch (e) {
      showErrorDialog("Send Error", e.toString());
    }
  }

  @override
  void dispose() {
    tcpSocket?.destroy();
    udpSocket?.close();
    mqttClient?.disconnect();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.protocol} Messenger"),
      ),
      body: Container(
        decoration:  BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade100, Colors.pink.shade50], 
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                const SizedBox(height: 12),
                Card(
                  elevation: 6,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        TextField(
                          controller: ipController,
                          decoration: const InputDecoration(
                            labelText: "Server IP",
                            prefixIcon:
                                Icon(Icons.cloud_outlined, color: Colors.pink),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pinkAccent),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: portController,
                          decoration: const InputDecoration(
                            labelText: "Port",
                            prefixIcon:
                                Icon(Icons.numbers, color: Colors.pinkAccent),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pinkAccent),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton.icon(
                          onPressed: connect,
                          icon: const Icon(Icons.link),
                          label: const Text("Connect"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            foregroundColor: Colors.white,
                            minimumSize: const Size.fromHeight(45),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey)
                    ),
                    child: ListView.builder(
                      padding: const EdgeInsets.all(12),
                      itemCount: messages.length,
                      itemBuilder: (_, i) => Align(
                        alignment: messages[i].startsWith("You")
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: messages[i].startsWith("You")
                                ? Colors.pink.shade100
                                : Colors.pink.shade50,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(messages[i]),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: messageController,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                            
                            borderRadius: BorderRadius.circular(12),
                          ) ,
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                            
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: "Enter message",
                          filled: true,
                          fillColor: Colors.white,
                          border:  OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                            
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FloatingActionButton(
                      onPressed: sendMessage,
                      backgroundColor: Colors.pinkAccent,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
