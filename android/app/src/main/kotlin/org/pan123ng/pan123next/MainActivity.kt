package org.pan123ng.pan123next

import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "pan123next/downloader"
    private var serverPort: Int = 0

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "startServer" -> {
                    if (serverPort > 0) {
                        result.success(serverPort)
                        return@setMethodCallHandler
                    }
                    val dir = call.argument<String>("dir") ?: ""
                    Thread {
                        val port = startGoServer(dir)
                        serverPort = port
                        Handler(Looper.getMainLooper()).post {
                            result.success(port)
                        }
                    }.start()
                }
                "stopServer" -> {
                    stopGoServer()
                    serverPort = 0
                    result.success(true)
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun startGoServer(dir: String): Int {
        return try {
            val clazz = Class.forName("downloader.MobileServer")
            val method = clazz.getMethod("startServer", String::class.java)
            method.invoke(null, dir) as Int
        } catch (e: Exception) {
            android.util.Log.e("GoDownloader", "startServer failed", e)
            0
        }
    }

    private fun stopGoServer() {
        try {
            val clazz = Class.forName("downloader.MobileServer")
            val method = clazz.getMethod("stopServer")
            method.invoke(null)
        } catch (e: Exception) {
            android.util.Log.e("GoDownloader", "stopServer failed", e)
        }
    }

    override fun onDestroy() {
        stopGoServer()
        super.onDestroy()
    }
}
