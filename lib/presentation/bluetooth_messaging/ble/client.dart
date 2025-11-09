import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:intl/intl.dart';

class ClientScreen extends StatefulWidget {
  const ClientScreen({super.key});

  @override
  State<ClientScreen> createState() => _ClientScreenState();
}

class _ClientScreenState extends State<ClientScreen> {
  final List<String> _receivedMessages = [];
  bool _scanning = false;
  StreamSubscription<List<ScanResult>>? _scanSub;
  String? _selectedDeviceId;
  String? _selectedDeviceName;
  Timer? _refreshTimer;
  String? _pendingMessage;
  String? _lastMessageContent;

  // 🔹 NEW: track if advertiser is currently visible
  bool _advertiserVisible = true;
  Timer? _advertiserCheckTimer;
  DateTime? _lastSeenTime;

  @override
  void initState() {
    super.initState();
    _checkPermissions();
  }

  Future<void> _checkPermissions() async {
    await [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ].request();
  }

  Future<void> _startScan() async {
    if (_scanning) return;

    setState(() {
      _receivedMessages.clear();
      _scanning = true;
      _advertiserVisible = true;
    });

    final List<ScanResult> foundDevices = [];
    FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));

    await for (final results in FlutterBluePlus.scanResults.timeout(const Duration(seconds: 4))) {
      for (var r in results) {
        if (!foundDevices.any((d) => d.device.id == r.device.id)) {
          foundDevices.add(r);
        }
      }
      if (foundDevices.isNotEmpty) break;
    }

    await FlutterBluePlus.stopScan();

    if (!mounted) return;

    final chosen = await showDialog<ScanResult>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Select a Server Device"),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: foundDevices.isEmpty
              ? const Center(child: Text("No devices found."))
              : ListView.builder(
                  itemCount: foundDevices.length,
                  itemBuilder: (_, i) {
                    final r = foundDevices[i];
                    final name = r.device.name.isNotEmpty ? r.device.name : "Unknown";
                    return ListTile(
                      leading: const Icon(Icons.bluetooth, color: Colors.pink),
                      title: Text(name),
                      subtitle: Text(r.device.id.id),
                      onTap: () => Navigator.pop(ctx, r),
                    );
                  },
                ),
        ),
      ),
    );

    if (chosen == null) {
      setState(() => _scanning = false);
      return;
    }

    _selectedDeviceId = chosen.device.id.id;
    _selectedDeviceName = chosen.device.name.isNotEmpty ? chosen.device.name : "Unknown";

    FlutterBluePlus.startScan();

    _scanSub = FlutterBluePlus.scanResults.listen(
      (results) {
        bool seenThisRound = false;

        for (ScanResult r in results) {
          if (r.device.id.id != _selectedDeviceId) continue;

          // 🔹 Mark advertiser as seen recently
          seenThisRound = true;
          _lastSeenTime = DateTime.now();

          final data = r.advertisementData.manufacturerData;
          if (data.isNotEmpty) {
            final bytes = data.values.first;
            final message = String.fromCharCodes(bytes);

            if (message.isNotEmpty &&
                message != _lastMessageContent &&
                message != _pendingMessage &&
                !_receivedMessages.any((m) => m.contains(message))) {
              _pendingMessage = message;
            }
          }
        }

        // 🔹 If advertiser not seen in this round, mark time and check timeout later
        if (!seenThisRound && _lastSeenTime == null) {
          _lastSeenTime = DateTime.now();
        }
      },
      onError: (error) {
        debugPrint("❌ Scan error: $error");
      },
    );

    // 🔹 Timer to refresh UI for new messages
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (_) {
      if (_pendingMessage != null && _pendingMessage != _lastMessageContent) {
        final now = DateFormat('hh:mm:ss a').format(DateTime.now());
        final fullMsg = "🕒 [$now] $_selectedDeviceName: ${_pendingMessage!}";

        if (!mounted) return;
        setState(() {
          _receivedMessages.insert(0, fullMsg);
        });

        _lastMessageContent = _pendingMessage;
        _pendingMessage = null;
      }
    });

    // 🔹 NEW: Timer to check if advertiser disappeared
    _advertiserCheckTimer?.cancel();
    _advertiserCheckTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      if (_lastSeenTime == null) return;
      final diff = DateTime.now().difference(_lastSeenTime!);

      // If no signal for >6s, assume disconnected
      if (diff.inSeconds > 6 && _advertiserVisible) {
        _advertiserVisible = false;
        await _stopScan();

        if (!mounted) return;
        setState(() {
          _receivedMessages.insert(
            0,
            "⚠️ [${DateFormat('hh:mm:ss a').format(DateTime.now())}] Connection lost from $_selectedDeviceName. Scanning stopped.",
          );
        });
      }
    });
  }

  Future<void> _stopScan() async {
    if (!_scanning) return;
    await FlutterBluePlus.stopScan();
    await _scanSub?.cancel();
    _scanSub = null;
    _refreshTimer?.cancel();
    _refreshTimer = null;
    _advertiserCheckTimer?.cancel();
    _advertiserCheckTimer = null;
    if (mounted) setState(() => _scanning = false);
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _advertiserCheckTimer?.cancel();
    _stopScan();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.pink[50],
      appBar: AppBar(
        title: const Text(
          "Client (Scanner)",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          icon: const Icon(Icons.arrow_back),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _scanning
                  ? Icons.stop_circle_rounded
                  : Icons.play_circle_fill_rounded,
              size: 30,
            ),
            onPressed: _scanning ? _stopScan : _startScan,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _scanning ? Colors.green[100] : Colors.pink[100],
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.pink.withOpacity(0.2),
                    spreadRadius: 2,
                    blurRadius: 6,
                    offset: const Offset(2, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    _scanning
                        ? Icons.bluetooth_searching
                        : Icons.bluetooth_disabled,
                    color: _scanning ? Colors.green : Colors.grey,
                    size: 26,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    _scanning
                        ? (_advertiserVisible
                            ? "Scanning for messages..."
                            : "Disconnected — stopped scanning")
                        : "Tap ▶️ to start scanning",
                    style: TextStyle(
                      color: _scanning
                          ? Colors.green[900]
                          : Colors.grey[700],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: _receivedMessages.isEmpty
                  ? Center(
                      child: Text(
                        _scanning
                            ? "Listening for nearby devices..."
                            : "No messages yet.",
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    )
                  : ListView.builder(
                      reverse: true,
                      itemCount: _receivedMessages.length,
                      itemBuilder: (_, index) {
                        final msg = _receivedMessages[index];
                        return Card(
                          margin: const EdgeInsets.symmetric(
                              vertical: 6, horizontal: 4),
                          elevation: 3,
                          shadowColor:
                              Colors.pinkAccent.withOpacity(0.2),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.pinkAccent,
                              child: const Icon(Icons.message,
                                  color: Colors.white),
                            ),
                            title: Text(
                              msg,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
