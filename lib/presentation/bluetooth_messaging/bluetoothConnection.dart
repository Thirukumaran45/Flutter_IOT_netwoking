import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'chatPage.dart';

class Bluetoothconnection extends StatefulWidget {
  const Bluetoothconnection({super.key});
  @override
  State<Bluetoothconnection> createState() => _BluetoothconnectionState();
}

class _BluetoothconnectionState extends State<Bluetoothconnection> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  StreamSubscription<BluetoothState>? _btStateSub;
  bool _isDiscovering = false;
  final List<BluetoothDiscoveryResult> _discovered = [];
  StreamSubscription<BluetoothDiscoveryResult>? _discoveryStreamSub;

  @override
  void initState() {
    super.initState();
    FlutterBluetoothSerial .instance.state.then((s) {
      setState(() => _bluetoothState = s);
    });
    _btStateSub = FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() => _bluetoothState = state);
    });
  }

  @override
  void dispose() {
    _btStateSub?.cancel();
    _discoveryStreamSub?.cancel();
    super.dispose();
  }

  Future<void> _requestPermissions() async {
    await [
      Permission.location,
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();
  }

  Future<void> _startDiscovery() async {
    await _requestPermissions();
    setState(() {
      _discovered.clear();
      _isDiscovering = true;
    });

    _discoveryStreamSub =
        FlutterBluetoothSerial.instance.startDiscovery().listen((r) {
      setState(() {
        final exists =
            _discovered.any((d) => d.device.address == r.device.address);
        if (!exists) _discovered.add(r);
      });
    });

    _discoveryStreamSub!.onDone(() {
      setState(() => _isDiscovering = false);
    });
  }

  Future<void> _enableBluetooth() async {
    await FlutterBluetoothSerial.instance.requestEnable();
  }

  Future<void> _disableBluetooth() async {
    await FlutterBluetoothSerial.instance.requestDisable();
  }

  Future<void> _makeDiscoverable() async {
    final seconds =
        await FlutterBluetoothSerial.instance.requestDiscoverable(60);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Discoverable for $seconds seconds')),
    );
  }

// inside _BluetoothconnectionState

Future<void> _hostSession() async {
  // make sure runtime permissions are granted
  await _requestPermissions();

  // Ask system to make this device discoverable for 120 seconds
  // (user will see the OS dialog and must accept)
  final int? seconds = await FlutterBluetoothSerial.instance.requestDiscoverable(120);

  // show a quick notification to the user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Device discoverable for $seconds seconds')),
  );

  // navigate to chat page in host mode
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => const ChatPage(isServer: true),
    ),
  );
}


  void _joinSession(BluetoothDevice device) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ChatPage(remote: device, isServer: false),
      ),
    );
  }

  Widget _buildDeviceTile(BluetoothDiscoveryResult r) {
    return ListTile(
      title: Text(r.device.name ?? "Unknown"),
      subtitle: Text(r.device.address),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
        child: const Text('Join'),
        onPressed: () => _joinSession(r.device),
      ),
    );
  }

  Widget _buildPairedTile(BluetoothDevice d) {
    return ListTile(
      title: Text(d.name ?? "Unknown"),
      subtitle: Text(d.address),
      trailing: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: Colors.pink),
        child: const Text('Join',style: TextStyle(color: Colors.white),),
        onPressed: () => _joinSession(d),
      ),
    );
  }

  Future<List<BluetoothDevice>> _getBonded() async {
    return (await FlutterBluetoothSerial.instance.getBondedDevices());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Bluetooth Chat'),
        backgroundColor: Colors.pink,
        actions: [
          IconButton(
            icon: Icon(_bluetoothState.isEnabled
                ? Icons.bluetooth
                : Icons.bluetooth_disabled),
            onPressed: () async {
              if (_bluetoothState.isEnabled) {
                await _disableBluetooth();
              } else {
                await _enableBluetooth();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.visibility),
            onPressed: _makeDiscoverable,
            tooltip: 'Make discoverable (60s)',
          ),
          IconButton(
            icon: _isDiscovering
                ? const Icon(Icons.stop)
                : const Icon(Icons.search),
            onPressed:
                _isDiscovering ? () => _discoveryStreamSub?.cancel() : _startDiscovery,
          ),
        ],
      ),
      body: Column(
        children: [
          const SizedBox(height: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.pink,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onPressed: _hostSession,
            icon: const Icon(Icons.cast_connected,color: Colors.white,),
            label: const Text("Host Chat Session",style:  TextStyle(color: Colors.white)),
          ),
          const Divider(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _startDiscovery,
              child: ListView(
                children: [
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Discovered devices',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  ..._discovered.map(_buildDeviceTile),
                  const Divider(),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text('Paired devices',
                        style: TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold)),
                  ),
                  FutureBuilder<List<BluetoothDevice>>(
                    future: _getBonded(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final list = snapshot.data!;
                      return Column(children: list.map(_buildPairedTile).toList());
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
