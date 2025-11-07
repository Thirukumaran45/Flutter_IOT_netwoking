import 'package:flutter/material.dart';
import 'connection_screen.dart';

class ProtocolSelectionScreen extends StatefulWidget {
  const ProtocolSelectionScreen({super.key});

  @override
  State<ProtocolSelectionScreen> createState() =>
      _ProtocolSelectionScreenState();
}

class _ProtocolSelectionScreenState extends State<ProtocolSelectionScreen> {
  String selectedProtocol = "";

  void selectProtocol(String protocol) {
    setState(() => selectedProtocol = protocol);
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ConnectionScreen(protocol: protocol),
      ),
    );
  }

  Widget protocolButton(String label, IconData icon) {
    final isSelected = selectedProtocol == label;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: 220,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 26),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(
            label,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        style: ElevatedButton.styleFrom(
          elevation: isSelected ? 8 : 3,
          backgroundColor:
              isSelected ? Colors.pinkAccent.shade400 : Colors.pink.shade50,
          foregroundColor:
              isSelected ? Colors.white : Colors.pinkAccent.shade700,
          shadowColor: Colors.pinkAccent.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isSelected
                  ? Colors.pinkAccent.shade700
                  : Colors.pinkAccent.shade100,
              width: 2,
            ),
          ),
        ),
        onPressed: () => selectProtocol(label),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink.shade50,
      appBar: AppBar(
        title: const Text('Select Protocol'),
        centerTitle: true,
        elevation: 3,
        titleTextStyle: const TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
          color: Colors.white,
        ),
      ),
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Colors.pink.shade100,
              Colors.pink.shade50,
              Colors.white,
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.wifi_tethering,
              color: Colors.pinkAccent,
              size: 80,
            ),
            const SizedBox(height: 25),
            const Text(
              "Choose Your Network Protocol",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.pinkAccent,
              ),
            ),
            const SizedBox(height: 30),
            protocolButton("TCP", Icons.cable),
            protocolButton("UDP", Icons.wifi),
            protocolButton("MQTT", Icons.cloud_outlined),
          ],
        ),
      ),
    );
  }
}
