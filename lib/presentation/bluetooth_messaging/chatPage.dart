import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial_plus/flutter_bluetooth_serial_plus.dart';
import 'native_bt_server.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice? remoteDevice;
  final bool isServer;

  const ChatPage({
    super.key,
    required this.remoteDevice,
    required this.isServer,
  });

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  BluetoothConnection? _connection; // client connection only
  StreamSubscription? _serverEventSub; // native server events
  bool _isConnected = false;
  bool _isConnecting = true;
  final TextEditingController _controller = TextEditingController();
  final List<_Message> _messages = [];
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    widget.isServer ? _setupServerMode() : _connectAsClient();
  }

  // ---------------- SERVER MODE ----------------
  Future<void> _setupServerMode() async {
    setState(() {
      _isConnecting = true;
      _messages.add(_Message.system('Starting native server...'));
    });
    try {
      // Make discoverable first (optional but recommended)
      await FlutterBluetoothSerial.instance.requestDiscoverable(120);

      // Start native server (Kotlin MainActivity handles starting BluetoothRfcommServer)
      await NativeBtServer.startServer();

      // Subscribe to native events (logs & incoming messages)
      _serverEventSub = NativeBtServer.events().listen((dynamic event) {
        if (event is Map) {
          final type = event['type'];
          final text = event['text'] ?? '';
          if (type == 'message') {
            setState(() {
              _messages.add(_Message.remote(text.toString().trim()));
              _isConnected = true; // client connected (native signalled activity)
              _isConnecting = false;
            });
            _scrollToBottom();
          } else if (type == 'log') {
            setState(() {
              _messages.add(_Message.system(text.toString()));
            });
          } else if (type == 'client_closed') {
            setState(() {
              _messages.add(_Message.system('Client disconnected'));
              _isConnected = false;
            });
          }
        }
      }, onError: (err) {
        setState(() => _messages.add(_Message.system('Server event error: $err')));
      });

      setState(() {
        _messages.add(_Message.system('Native server started – waiting for client...'));
        _isConnecting = false;
      });
    } catch (e) {
      setState(() {
        _messages.add(_Message.system('Failed to start native server: $e'));
        _isConnecting = false;
      });
      _showErrorDialog('Server start failed: $e');
    }
  }

  // ---------------- CLIENT MODE ----------------
  Future<void> _connectAsClient() async {
    final remote = widget.remoteDevice;
    if (remote == null) {
      _showErrorDialog('No remote device selected.');
      setState(() => _isConnecting = false);
      return;
    }

    setState(() {
      _isConnecting = true;
      _messages.add(_Message.system('Connecting to ${remote.name ?? remote.address}...'));
    });

    try {
      // Cancel discovery (important)
      try { await FlutterBluetoothSerial.instance.cancelDiscovery(); } catch (_) {}

      // Try bond if needed (optional)
      final bonded = (await FlutterBluetoothSerial.instance.getBondedDevices())
          .any((d) => d.address == remote.address);
      if (!bonded) {
        // Attempt bond programmatically; user may have to accept pairing
        await FlutterBluetoothSerial.instance.bondDeviceAtAddress(remote.address);
      }

      final conn = await BluetoothConnection.toAddress(remote.address).timeout(const Duration(seconds: 25));
      _connection = conn;
      setState(() {
        _isConnected = true;
        _isConnecting = false;
        _messages.add(_Message.system('Connected to ${remote.name ?? remote.address}'));
      });

      // Listen incoming data
      _connection?.input?.listen((Uint8List data) {
        final text = utf8.decode(data).trim();
        if (text.isNotEmpty) {
          setState(() => _messages.add(_Message.remote(text)));
          _scrollToBottom();
        }
      }, onDone: () {
        setState(() {
          _messages.add(_Message.system('Connection closed by remote'));
          _isConnected = false;
        });
      }, onError: (err) {
        setState(() => _messages.add(_Message.system('Connection error: $err')));
      });
    } catch (e) {
      setState(() {
        _messages.add(_Message.system('Connection failed: $e'));
        _isConnecting = false;
      });
      _showErrorDialog('Connection failed: $e');
    }
  }

  // ---------------- SEND ----------------
  Future<void> _send() async {
    final txt = _controller.text.trim();
    if (txt.isEmpty) return;

    if (widget.isServer) {
      // use native sendToClient
      final ok = await NativeBtServer.sendToClient(txt + '\n');
      if (ok) {
        setState(() => _messages.add(_Message.me(txt)));
      } else {
        setState(() => _messages.add(_Message.system('Failed to send to client (native)')));
      }
    } else {
      // client mode: send through RFCOMM socket
      if (_connection != null && _connection!.isConnected) {
        _connection!.output.add(Uint8List.fromList(utf8.encode(txt + '\n')));
        setState(() => _messages.add(_Message.me(txt)));
      } else {
        setState(() => _messages.add(_Message.system('Not connected')));
      }
    }
    _controller.clear();
    _scrollToBottom();
  }

  // ---------------- UI / Helpers ----------------
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.jumpTo(_scrollController.position.maxScrollExtent);
      }
    });
  }

  void _showErrorDialog(String msg) {
    if (!mounted) return;
    showDialog(
      context: context,
      builder: (_) { 
        return AlertDialog(
        title: const Text('Bluetooth Error'),
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      );},
    );
  }

  @override
  void dispose() {
    _serverEventSub?.cancel();
    _connection?.dispose();
    // ensure native server stopped when leaving UI (optional)
    if (widget.isServer) {
      // ignore: body_might_complete_normally_catch_error
      NativeBtServer.stopServer().catchError((_) {});
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = _isConnecting
        ? 'Connecting...'
        : (_isConnected ? 'Connected' : 'Disconnected');

    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: Colors.pink),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              itemCount: _messages.length,
              itemBuilder: (_, i) {
                final m = _messages[i];
                return Align(
                  alignment: m.type == _MsgType.me ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: m.type == _MsgType.me ? Colors.pink : Colors.pink.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(m.text, style: TextStyle(color: m.type == _MsgType.me ? Colors.white : Colors.black)),
                  ),
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(controller: _controller, decoration: const InputDecoration(hintText: 'Type a message')),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send, color: Colors.pink),
                    onPressed: _send,
                  )
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

class _Message {
  final String text;
  final _MsgType type;
  _Message(this.text, this.type);
  factory _Message.me(String t) => _Message(t, _MsgType.me);
  factory _Message.remote(String t) => _Message(t, _MsgType.remote);
  factory _Message.system(String t) => _Message(t, _MsgType.system);
}
