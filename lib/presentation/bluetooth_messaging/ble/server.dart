import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:permission_handler/permission_handler.dart';

class ServerScreen extends StatefulWidget {
  const ServerScreen({super.key});

  @override
  State<ServerScreen> createState() => _ServerScreenState();
}

class _ServerScreenState extends State<ServerScreen> {
  final FlutterBlePeripheral blePeripheral = FlutterBlePeripheral();
  bool isAdvertising = false;
  final List<String> _messages = [];
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.bluetooth,
      Permission.bluetoothAdvertise,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

Future<void> _startAdvertising(String message) async {
  if (isAdvertising) {
    await _stopAdvertising(); // stop any old ad first
    await Future.delayed(const Duration(seconds: 1)); // 🔹 ensure a clear restart
  }

  final advertiseData = AdvertiseData(
    includeDeviceName: true,
    manufacturerId: 1234,
    manufacturerData: Uint8List.fromList(message.codeUnits),
  );

  await blePeripheral.start(advertiseData: advertiseData);
  setState(() {
    isAdvertising = true;
    _messages.add("📡 $message");
  });

  await Future.delayed(const Duration(milliseconds: 100));
  if (_scrollController.hasClients) {
    _scrollController.animateTo(
      _scrollController.position.maxScrollExtent + 60,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  _messageController.clear();
}

  Future<void> _stopAdvertising() async {
    await blePeripheral.stop();
    setState(() => isAdvertising = false);
  }

@override
void dispose() {
  _stopAdvertising(); // 🔹 make sure advertising is stopped properly
  _messageController.dispose();
  _scrollController.dispose();
  super.dispose();
}


  Widget _buildMessageBubble(String message, bool isSent) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal :40,vertical: 4),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSent ? Colors.pinkAccent : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: Colors.pink.withOpacity(0.2),
              blurRadius: 4,
              offset: const Offset(2, 3),
            ),
          ],
        ),
        child: Text(
          message,
          style: TextStyle(
            color: isSent ? Colors.white : Colors.black87,
            fontSize: 20,
            fontWeight: FontWeight.bold
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text(
          "Server (Peripheral)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(onPressed: (){
          Navigator.of(context).pop();
        }, icon: Icon(Icons.arrow_back)),
        actions: [
          IconButton(
            icon: Icon(
              isAdvertising ? Icons.stop_circle_rounded : Icons.play_circle_fill_rounded,
              size: 28,
            ),
            onPressed: () {
              if (isAdvertising) {
                _stopAdvertising();
              } else {
                final msg = _messageController.text.trim();
                if (msg.isNotEmpty) {
                  _startAdvertising(msg);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Enter a message to advertise")),
                  );
                }
              }
            },
          )
        ],
      ),
      body: Column(
        children: [
          Container(
            width: double.infinity,
            color: Colors.white,
            padding: const EdgeInsets.all(10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  isAdvertising ? Icons.wifi_tethering : Icons.wifi_off_rounded,
                  color: isAdvertising ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  isAdvertising ? "Advertising..." : "Not Advertising",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: isAdvertising ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (_, index) =>
                  _buildMessageBubble(_messages[index], true),
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.1),
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: "Type your message...",
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10,
                        horizontal: 16,
                      ),
                      filled: true,
                      fillColor: Colors.pink[50],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(25),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.pink,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white),
                    onPressed: () {
                      final msg = _messageController.text.trim();
                      if (msg.isNotEmpty) {
                        _startAdvertising(msg);
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Enter a message to advertise")),
                        );
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
