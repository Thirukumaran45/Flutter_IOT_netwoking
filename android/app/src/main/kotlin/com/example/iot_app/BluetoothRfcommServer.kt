package com.example.iot_app

import android.bluetooth.BluetoothAdapter
import android.bluetooth.BluetoothServerSocket
import android.bluetooth.BluetoothSocket
import android.util.Log
import java.io.IOException
import java.io.InputStream
import java.io.OutputStream
import java.util.UUID
import kotlin.concurrent.thread

class BluetoothRfcommServer(private val onLog: (String) -> Unit,
                            private val onMessage: (String) -> Unit,
                            private val onClientClosed: () -> Unit) {

    private val TAG = "BtRfcommServer"
    private val adapter: BluetoothAdapter? = BluetoothAdapter.getDefaultAdapter()
    private var serverSocket: BluetoothServerSocket? = null
    private var acceptThread: Thread? = null
    private var clientSocket: BluetoothSocket? = null
    private var clientOut: OutputStream? = null

    // Standard SPP UUID (client and server must be compatible)
    private val SERVICE_UUID: UUID = UUID.fromString("00001101-0000-1000-8000-00805F9B34FB")

    fun startServer() {
        if (adapter == null) {
            onLog("No Bluetooth adapter available")
            return
        }

        try {
            serverSocket = adapter.listenUsingRfcommWithServiceRecord("FlutterBTChat", SERVICE_UUID)
            onLog("Server socket opened, waiting for client...")
        } catch (e: IOException) {
            onLog("Failed to open server socket: ${e.message}")
            return
        }

        acceptThread = thread(start = true) {
            try {
                val socket = serverSocket?.accept() // blocking
                if (socket == null) {
                    onLog("Accept returned null socket")
                    close()
                    return@thread
                }
                clientSocket = socket
                onLog("Client accepted: ${socket.remoteDevice.address}")
                clientOut = socket.outputStream
                handleClient(socket)
            } catch (e: IOException) {
                onLog("Accept loop ended: ${e.message}")
            } finally {
                close()
            }
        }
    }

    private fun handleClient(socket: BluetoothSocket) {
        try {
            val input: InputStream = socket.inputStream
            val buffer = ByteArray(1024)
            while (true) {
                val bytesRead = input.read(buffer)
                if (bytesRead <= 0) break
                val received = String(buffer, 0, bytesRead, Charsets.UTF_8)
                onMessage(received)
            }
        } catch (e: IOException) {
            onLog("Client read error: ${e.message}")
        } finally {
            try { clientSocket?.close() } catch (_: Exception) {}
            clientSocket = null
            clientOut = null
            onClientClosed()
        }
    }

    fun writeToClient(message: String): Boolean {
        return try {
            val out = clientOut ?: run {
                onLog("No client output stream")
                return false
            }
            out.write(message.toByteArray(Charsets.UTF_8))
            out.flush()
            true
        } catch (e: Exception) {
            onLog("Write failed: ${e.message}")
            false
        }
    }

    fun close() {
        try { clientSocket?.close() } catch (_: Exception) {}
        try { serverSocket?.close() } catch (_: Exception) {}
        acceptThread?.interrupt()
        clientSocket = null
        serverSocket = null
        clientOut = null
        onLog("Server stopped (cleanly)")
    }
}
