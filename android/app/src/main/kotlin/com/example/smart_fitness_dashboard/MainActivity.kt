package com.example.smart_fitness_dashboard

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.activity.result.contract.ActivityResultContracts
import java.io.ByteArrayOutputStream

class MainActivity : FlutterFragmentActivity() {
    private var pending: MethodChannel.Result? = null
    private var exportBytes: ByteArray? = null
    private val maxBytes = 10 * 1024 * 1024
    private val createDocument = registerForActivityResult(
        ActivityResultContracts.CreateDocument("application/json")
    ) { uri ->
        val bytes = exportBytes
        exportBytes = null
        if (uri == null || bytes == null) finishDocument(false)
        else documentWork {
            require(uri.scheme == "content")
            contentResolver.openOutputStream(uri, "wt")!!.use { it.write(bytes) }
            true
        }
    }
    private val openDocument = registerForActivityResult(
        ActivityResultContracts.OpenDocument()
    ) { uri ->
        if (uri == null) finishDocument(null)
        else documentWork {
            require(uri.scheme == "content")
            contentResolver.openInputStream(uri)!!.use { input ->
                val output = ByteArrayOutputStream()
                val buffer = ByteArray(8192)
                while (true) {
                    val count = input.read(buffer)
                    if (count < 0) break
                    require(output.size() + count <= maxBytes)
                    output.write(buffer, 0, count)
                }
                output.toByteArray()
            }
        }
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger,
            "smart_fitness/local_documents").setMethodCallHandler { call, result ->
            if (pending != null) result.error("BUSY", "Операция уже выполняется", null)
            else when (call.method) {
                "export" -> {
                    val bytes = call.arguments as? ByteArray
                    if (bytes == null || bytes.size > maxBytes) {
                        result.error("SIZE", "Копия больше 10 МБ", null)
                    } else {
                        pending = result
                        exportBytes = bytes
                        try { createDocument.launch("quant-backup.json") }
                        catch (_: Exception) { failDocument() }
                    }
                }
                "import" -> {
                    pending = result
                    try { openDocument.launch(arrayOf("application/json", "text/plain", "application/octet-stream")) }
                    catch (_: Exception) { failDocument() }
                }
                else -> result.notImplemented()
            }
        }
    }

    private fun documentWork(work: () -> Any) {
        Thread {
            try {
                val value = work()
                runOnUiThread { finishDocument(value) }
            } catch (_: Exception) { runOnUiThread { failDocument() } }
        }.start()
    }
    private fun finishDocument(value: Any?) {
        pending?.success(value)
        pending = null
        exportBytes = null
    }
    private fun failDocument() {
        pending?.error("DOCUMENT", "Не удалось прочитать или записать файл (предел 10 МБ)", null)
        pending = null
        exportBytes = null
    }
}
