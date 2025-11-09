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
  late String myClientId;

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
    FocusScope.of(context).unfocus(); // ✅ hide keyboard & remove cursor

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
  log("🟢 Connected to TCP server"); // ✅ add this line
  tcpSocket!.listen((Uint8List data) {
    final message = String.fromCharCodes(data).trim();
    if (message.isNotEmpty) log("Server: $message");
  },
  onError: (e) => showErrorDialog("TCP Error", e.toString()),
  onDone: () => log("Connection closed by server."),
  );
} else if (widget.protocol == "UDP") {
  udpSocket = await RawDatagramSocket.bind(InternetAddress.anyIPv4, 0);
  connected = true;
  log("🟢 Connected to UDP server"); // ✅ add this line
  udpSocket!.listen((event) {
    if (event == RawSocketEvent.read) {
      final datagram = udpSocket!.receive();
      if (datagram != null) {
        log("Server: ${String.fromCharCodes(datagram.data)}");
      }
    }
  });
}
 else if (widget.protocol == "MQTT") {
        myClientId = 'flutter_mqtt_${DateTime.now().millisecondsSinceEpoch}';
        mqttClient = MqttServerClient('test.mosquitto.org', myClientId);

        mqttClient!.logging(on: false);
        mqttClient!.onConnected = () => log("✅ Connected to MQTT broker!");
        mqttClient!.onDisconnected = () => log("❌ Disconnected from MQTT.");

        await mqttClient!.connect();

        mqttClient!.subscribe('test/topic', MqttQos.atMostOnce);

        mqttClient!.updates!.listen((messagesList) {
          final payload = (messagesList[0].payload as MqttPublishMessage).payload.message;
          final messageString = MqttPublishPayload.bytesToStringAsString(payload);
          final splitIndex = messageString.indexOf('::');
          if (splitIndex == -1) return;
          final senderId = messageString.substring(0, splitIndex);
          final actualMessage = messageString.substring(splitIndex + 2);
          if (senderId != myClientId) {
            log(actualMessage);
          }
        });

        connected = true;
        setState(() {});
        log("✅ Connected successfully via MQTT");
      }
      setState(() {}); // ✅ update for disconnect button
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

  String messageWithId = msg;
  if (widget.protocol == "MQTT") {
    messageWithId = "$myClientId::$msg";
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
      final builder = MqttClientPayloadBuilder()..addString(messageWithId);
      mqttClient?.publishMessage(
        'test/topic',
        MqttQos.atMostOnce,
        builder.payload!,
      );
    }

    // ✅ Auto clear text field after send
    messageController.clear();
    
  } catch (e) {
    showErrorDialog("Send Error", e.toString());
  }
}


  void disconnect() {
    if (widget.protocol == "TCP") {
      tcpSocket?.destroy();
    } else if (widget.protocol == "UDP") {
      udpSocket?.close();
    } else if (widget.protocol == "MQTT") {
      mqttClient?.disconnect();
    }
    connected = false;
    setState(() {});
    log("🔴 Disconnected");
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
    final h = MediaQuery.of(context).size.height;
    final w = MediaQuery.of(context).size.width;

    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.protocol} Messenger"),
        actions: [
          if (connected)
            IconButton(
              icon: const Icon(Icons.link_off, color: Colors.white),
              tooltip: "Disconnect",
              onPressed: disconnect,
            ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.pink.shade100, Colors.pink.shade50],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: EdgeInsets.all(w * 0.04),
            child: Column(
              children: [
                SizedBox(height: h * 0.015),
                Card(
                  elevation: 6,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                  child: Padding(
                    padding: EdgeInsets.all(w * 0.04),
                    child: Column(
                      children: [
                        TextField(
                          controller: ipController,
                          enabled: !connected, // ✅ disable when connected
                          decoration: const InputDecoration(
                            labelText: "Server IP",
                            prefixIcon:
                                Icon(Icons.cloud_outlined, color: Colors.pink),
                            focusedBorder: UnderlineInputBorder(
                              borderSide: BorderSide(color: Colors.pinkAccent),
                            ),
                          ),
                        ),
                        SizedBox(height: h * 0.012),
                        TextField(
                          controller: portController,
                          enabled: !connected, // ✅ disable when connected
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
                        SizedBox(height: h * 0.012),
                        ElevatedButton.icon(
                          onPressed: connected ? null : connect,
                          icon: const Icon(Icons.link),
                          label: const Text("Connect"),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.pinkAccent,
                            foregroundColor: Colors.white,
                            minimumSize: Size(w, h * 0.06),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: h * 0.015),
                
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.95),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.grey),
                    ),
                    child: ListView.builder(
                      padding: EdgeInsets.all(w * 0.03),
                      itemCount: messages.length,
                      itemBuilder: (_, i) => Align(
                        alignment: messages[i].startsWith("You")
                            ? Alignment.centerRight
                            : Alignment.centerLeft,
                        child: Container(
                          margin: EdgeInsets.symmetric(vertical: h * 0.005),
                          padding: EdgeInsets.all(w * 0.03),
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
                SizedBox(height: h * 0.01),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: messageController,
                        decoration: InputDecoration(
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          disabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          hintText: "Enter message",
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderSide: BorderSide(color: Colors.pink),
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: w * 0.02),
                    FloatingActionButton(
                      onPressed: sendMessage,
                      backgroundColor: Colors.pinkAccent,
                      child: const Icon(Icons.send, color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
