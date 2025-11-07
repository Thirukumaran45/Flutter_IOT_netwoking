import 'dart:async' show StreamSubscription;
import 'dart:convert' show utf8;
import 'dart:developer' show log;
import 'dart:typed_data' show Uint8List;

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice? remote;
  final bool isServer;
  const ChatPage({super.key, this.remote, this.isServer = false});


  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  BluetoothConnection? _connection;
  bool _isConnecting = true;
  bool get isConnected => _connection != null && _connection!.isConnected;
  final List<_Msg> _messages = [];
  final TextEditingController _controller = TextEditingController();
  StreamSubscription<Uint8List>? _inputSub;

  // NEW: show local device info on host screen
  String? _localName;
  String? _localAddress;

@override
void initState() {
  super.initState();
  if (widget.isServer) {
    _startServer(); // ✅ Start listening for incoming Bluetooth connections
  } else {
    _connect(); // client
  }
}

  Future<void> _fetchLocalInfo() async {
    try {
      final name = await FlutterBluetoothSerial.instance.name;
      final addr = await FlutterBluetoothSerial.instance.address;
      setState(() {
        _localName = name;
        _localAddress = addr;
      });

      // optionally add a system message with this info
      setState(() {
        _messages.add(_Msg.system('This device: ${_localName ?? "Unknown"} (${_localAddress ?? ''})'));
        _messages.add(_Msg.system('Make this device discoverable and ask peer to Join.'));
      });
    } catch (e) {
      setState(() {
        _messages.add(_Msg.system('Failed to get local BT info: $e'));
      });
    }
  }
Future<void> _startServer() async {
  try {
    setState(() => _isConnecting = true);
    _messages.add(_Msg.system('Waiting for incoming Bluetooth connection...'));

    // Make this device discoverable for 2 minutes
    await FlutterBluetoothSerial.instance.requestDiscoverable(120);

    // ⚠️ flutter_bluetooth_serial_plus does NOT support accepting incoming connections.
    // Instead, we just show info for the user and let the CLIENT connect manually.
    await _fetchLocalInfo();
    _messages.add(_Msg.system(
      'Your device is now discoverable.\nAsk the other phone to connect to "${_localName ?? "This Device"}" from its device list.',
    ));

    setState(() => _isConnecting = false);
  } catch (e) {
    setState(() {
      _isConnecting = false;
      _messages.add(_Msg.system('Server setup error: $e'));
    });
  }
}



Future<void> _connect() async {
  try {
    setState(() => _isConnecting = true);

    if (widget.isServer) {
      // Server mode — only waits for incoming connection
      _messages.add(_Msg.system('Waiting for the other device to connect...'));
      setState(() => _isConnecting = false);
      return; // Don’t try to connect in host mode
    }

    // Client mode — connects to the selected remote device
    if (widget.remote == null) {
      _messages.add(_Msg.system('No remote device selected.'));
      return;
    }

    _messages.add(_Msg.system('Connecting to ${widget.remote!.name ?? widget.remote!.address}...'));
    _connection = await BluetoothConnection.toAddress(widget.remote!.address);
    _messages.add(_Msg.system('Connected to ${widget.remote!.name ?? widget.remote!.address}'));

    // Listen for incoming messages
    _inputSub = _connection!.input?.listen((Uint8List data) {
      final text = utf8.decode(data);
      setState(() => _messages.add(_Msg.fromRemote(text.trim())));
    }, onDone: () {
      setState(() => _messages.add(_Msg.system('Connection closed')));
    });

    setState(() => _isConnecting = false);
  } catch (e) {
    setState(() {
      _isConnecting = false;
      _messages.add(_Msg.system('Connection error: $e'));
    });
  }
}



  void _sendMessage() {
    final txt = _controller.text.trim();
    if (txt.isEmpty || _connection == null) return;
    try {
      final encoded = utf8.encode(txt + "\n");
      _connection!.output.add(Uint8List.fromList(encoded));
      setState(() {
        _messages.add(_Msg.fromMe(txt));
        _controller.clear();
      });
    } catch (e) {
      setState(() => _messages.add(_Msg.system('Send failed: $e')));
    }
  }

Future<void> _disconnect() async {
  await _inputSub?.cancel();
  try { await _connection?.close(); } catch (_) {}
  try { _connection?.dispose(); } catch (_) {}
  setState(() {
    _connection = null;
    _messages.add(_Msg.system('Disconnected'));
  });
}

@override
void dispose() {
  _controller.dispose();
  _inputSub?.cancel();
  try { _connection?.dispose(); } catch (_) {}
  super.dispose();
}


  Widget _buildMessageTile(_Msg m) {
    if (m.type == _MsgType.system) {
      log(m.text);
      return ListTile(
        title: Center(child: Text(m.text, style: const TextStyle(color: Colors.grey))),
      );
    }
    final align = m.type == _MsgType.me ? CrossAxisAlignment.end : CrossAxisAlignment.start;
    final color = m.type == _MsgType.me ? Colors.pink[100] : Colors.grey[200];
    final radius = const BorderRadius.all(Radius.circular(12));
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        crossAxisAlignment: align,
        children: [
          Container(
            decoration: BoxDecoration(color: color, borderRadius: radius),
            padding: const EdgeInsets.all(10),
            child: Text(m.text),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deviceName = widget.remote?.name ?? (widget.isServer ? "Host" : "Unknown Device");
final connStatus = _isConnecting ? 'Connecting...' : (isConnected ? 'Connected' : 'Disconnected');
    return Scaffold(
      appBar: AppBar(
        title: Text('$deviceName — $connStatus'),

        actions: [
          IconButton(
            icon: const Icon(Icons.power_settings_new),
            onPressed: () => _disconnect(),
            tooltip: 'Disconnect',
          )
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (c, i) => _buildMessageTile(_messages[i]),
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      decoration: const InputDecoration(hintText: 'Type message'),
                      onSubmitted: (_) => _sendMessage(),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.pink),
                    onPressed: _sendMessage,
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

enum _MsgType { me, remote, system }

class _Msg {
  final String text;
  final _MsgType type;
  _Msg(this.text, this.type);
  factory _Msg.fromMe(String t) => _Msg(t, _MsgType.me);
  factory _Msg.fromRemote(String t) => _Msg(t, _MsgType.remote);
  factory _Msg.system(String t) => _Msg(t, _MsgType.system);
}