import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chatPage.dart';

class BluetoothConnectionScreen extends StatefulWidget {
  const BluetoothConnectionScreen({super.key});

  @override
  State<BluetoothConnectionScreen> createState() =>
      _BluetoothConnectionScreenState();
}

class _BluetoothConnectionScreenState extends State<BluetoothConnectionScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  List<BluetoothDevice> _bondedDevices = [];
  List<BluetoothDiscoveryResult> _discoveredDevices = [];
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStream;
  bool _isDiscovering = false;

  @override
  void initState() {
    super.initState();
    _initBluetooth();
  }

  Future<void> _initBluetooth() async {
    // Request required permissions
    await [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.location
    ].request();

    final state = await FlutterBluetoothSerial.instance.state;
    setState(() => _bluetoothState = state);

    if (state == BluetoothState.STATE_OFF) {
      await FlutterBluetoothSerial.instance.requestEnable();
    }

    _loadBondedDevices();

    // Listen to Bluetooth state changes
    FlutterBluetoothSerial.instance.onStateChanged().listen((s) {
      setState(() => _bluetoothState = s);
      if (s == BluetoothState.STATE_ON) {
        _loadBondedDevices();
      }
    });
  }

  Future<void> _loadBondedDevices() async {
    try {
      final devices = await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() => _bondedDevices = devices);
    } catch (e) {
      debugPrint("Error getting bonded devices: $e");
    }
  }

  void _startDiscovery() {
    setState(() {
      _isDiscovering = true;
      _discoveredDevices.clear();
    });

    _discoveryStream =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        // Avoid duplicates
        final existingIndex = _discoveredDevices
            .indexWhere((element) => element.device.address == r.device.address);
        if (existingIndex >= 0) {
          _discoveredDevices[existingIndex] = r;
        } else {
          _discoveredDevices.add(r);
        }
      });
    });

    _discoveryStream?.onDone(() {
      setState(() => _isDiscovering = false);
    });
  }

  void _stopDiscovery() {
    _discoveryStream?.cancel();
    setState(() => _isDiscovering = false);
  }

  Future<void> _hostChat() async {
    // Make this phone discoverable for 2 minutes
    final result =
        await FlutterBluetoothSerial.instance.requestDiscoverable(120);
    if (result != 0 && mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const ChatPage(
            isServer: true,
            remoteDevice: null,
          ),
        ),
      );
    }
  }

  void _joinChat(BluetoothDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(
          isServer: false,
          remoteDevice: device,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _discoveryStream?.cancel();
    super.dispose();
  }

  Widget _buildDeviceTile(BluetoothDevice device) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
      child: ListTile(
        leading: const Icon(Icons.bluetooth, color: Colors.pink),
        title: Text(device.name ?? "Unknown Device"),
        subtitle: Text(device.address),
        trailing: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.pink,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          onPressed: () => _joinChat(device),
          child: const Text("Join", style: TextStyle(color: Colors.white)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final discoveredDevices = _discoveredDevices
        .map((r) => r.device)
        .where((d) => d.name != null)
        .toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.pink,
        title: const Text("Bluetooth Chat"),
        actions: [
          IconButton(
            icon: Icon(_isDiscovering ? Icons.stop : Icons.search),
            onPressed: _isDiscovering ? _stopDiscovery : _startDiscovery,
          ),
          IconButton(
            icon: const Icon(Icons.add_link),
            onPressed: _hostChat,
          ),
        ],
      ),
      body: Column(
        children: [
          if (_bluetoothState == BluetoothState.STATE_OFF)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Text("Bluetooth is turned off. Please enable it."),
              ),
            )
          else
            Expanded(
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Discovered Devices",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (discoveredDevices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No nearby devices found."),
                    ),
                  ...discoveredDevices.map(_buildDeviceTile),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      "Paired Devices",
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  if (_bondedDevices.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: Text("No paired devices found."),
                    ),
                  ..._bondedDevices.map(_buildDeviceTile),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
