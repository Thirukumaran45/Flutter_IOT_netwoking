import 'dart:async';
import 'package:flutter/services.dart';

class NativeBtServer {
  static const MethodChannel _method =
      MethodChannel('com.example.iot_app/bluetooth_server');
  static const EventChannel _events =
      EventChannel('com.example.iot_app/bluetooth_events');

  /// Start native server. Returns 'started' or throws.
  static Future<String?> startServer() async {
    try {
      final res = await _method.invokeMethod<String>('startServer');
      return res;
    } on PlatformException {
      rethrow;
    }
  }

  /// Stop native server.
  static Future<String?> stopServer() async {
    try {
      final res = await _method.invokeMethod<String>('stopServer');
      return res;
    } on PlatformException {
      rethrow;
    }
  }

  /// Send message to the connected client (native side writes to socket).
  static Future<bool> sendToClient(String message) async {
    try {
      final ok = await _method.invokeMethod<bool>('sendToClient', {'message': message});
      return ok == true;
    } on PlatformException {
      return false;
    }
  }

  /// Stream of events coming from native server (maps with keys 'type' and 'text').
  static Stream<dynamic> events() => _events.receiveBroadcastStream();
}
