import 'package:flutter/material.dart';
import 'package:iot_app/presentation/bluetooth_messaging/ble/server.dart';
import 'package:iot_app/presentation/bluetooth_messaging/ble/client.dart';
import 'package:iot_app/presentation/bluetooth_messaging/classic/bluetoothConnection.dart';

class ModeSelectionScreen extends StatefulWidget {
  const ModeSelectionScreen({super.key});

  @override
  State<ModeSelectionScreen> createState() => _ModeSelectionScreenState();
}

class _ModeSelectionScreenState extends State<ModeSelectionScreen>
    with SingleTickerProviderStateMixin {

  void _showBleRoleDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.pink[50],
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Select BLE Role",
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.pink),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            const SizedBox(height: 10),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
           backgroundColor: Colors.pinkAccent,

                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.cast_rounded, color: Colors.white),
              label:  Text("Start as Server", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ServerScreen()),
                );
              },
            ),
            const SizedBox(height: 15),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.pinkAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
                minimumSize: const Size(double.infinity, 50),
              ),
              icon: const Icon(Icons.bluetooth_searching_rounded, color: Colors.white),
              label: const Text("Start as Client", style: TextStyle(color: Colors.white,fontWeight: FontWeight.bold)),
              onPressed: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ClientScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [Colors.pinkAccent, Colors.pink.shade200],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.pink.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(2, 5),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 50),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              color: Colors.pink,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text("Select Mode", style: TextStyle(fontWeight: FontWeight.bold)),
        
      ),
      body: Container(
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
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                _buildModeButton(
                  icon: Icons.bluetooth_rounded,
                  label: "BLE",
                  onTap: _showBleRoleDialog,
                ),
                const SizedBox(width: 50,),
                _buildModeButton(
                  icon: Icons.bluetooth_connected_rounded,
                  label: "Classic",
                  onTap: () {
                    Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const BluetoothConnectionScreen()),
                  );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
