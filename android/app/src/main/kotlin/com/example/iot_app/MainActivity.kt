package com.example.iot_app

import android.os.Bundle
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterActivity() {
    private val TAG = "MainActivity"
    private val METHOD_CHANNEL = "com.example.iot_app/bluetooth_server"
    private val EVENT_CHANNEL = "com.example.iot_app/bluetooth_events"

    private var server: BluetoothRfcommServer? = null
    private var eventSink: EventChannel.EventSink? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startServer" -> {
                    startServer()
                    result.success("started")
                }
                "stopServer" -> {
                    stopServer()
                    result.success("stopped")
                }
                "sendToClient" -> {
                    val msg = call.argument<String>("message") ?: ""
                    val ok = server?.writeToClient(msg) ?: false
                    result.success(ok)
                }
                else -> result.notImplemented()
            }
        }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL).setStreamHandler(object : EventChannel.StreamHandler {
            override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
                eventSink = events
            }

            override fun onCancel(arguments: Any?) {
                eventSink = null
            }
        })
    }

    private fun startServer() {
        if (server != null) return
        server = BluetoothRfcommServer(
            onLog = { msg ->
                Log.d(TAG, msg)
                runOnUiThread {
                    eventSink?.success(mapOf("type" to "log", "text" to msg))
                }
            },
            onMessage = { msg ->
                Log.d(TAG, "msg -> $msg")
                runOnUiThread {
                    eventSink?.success(mapOf("type" to "message", "text" to msg))
                }
            },
            onClientClosed = {
                runOnUiThread {
                    eventSink?.success(mapOf("type" to "client_closed"))
                }
            }
        )

        server?.startServer()
    }

    private fun stopServer() {
        server?.close()
        server = null
    }
}