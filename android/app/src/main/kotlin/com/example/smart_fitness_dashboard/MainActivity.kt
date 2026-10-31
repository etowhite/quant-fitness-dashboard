package com.example.smart_fitness_dashboard

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import androidx.activity.result.contract.ActivityResultContracts
import java.io.ByteArrayOutputStream

class MainActivity : FlutterFragmentActivity() {
    private var widgetChannel: MethodChannel? = null
    private fun widgetRoute(intent: android.content.Intent?): String? {
        val uri = intent?.data ?: return null
        if(uri.scheme != "quant" || uri.host != "widget") return null
        return uri.lastPathSegment?.takeIf { it in listOf("dashboard", "nutrition", "water", "activity") }
    }
    override fun onNewIntent(intent: android.content.Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        widgetRoute(intent)?.let { widgetChannel?.invokeMethod("route", it) }
    }
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
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "quant/report_image")
            .setMethodCallHandler { call, result -> ReportImages.handle(this, call, result) }
        widgetChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "quant/home_widgets").also { channel ->
            channel.setMethodCallHandler { call, result ->
                when(call.method) {
                    "testWidgetAddWater" -> {
                        if ((applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) == 0) {
                            result.notImplemented()
                        } else {
                            QuantWidgets.enqueue(this, "add", 250)
                            result.success(null)
                        }
                    }
                    "testWidgetViews" -> {
                        if ((applicationInfo.flags and android.content.pm.ApplicationInfo.FLAG_DEBUGGABLE) == 0) {
                            result.notImplemented()
                        } else {
                            try {
                                val summary = mutableListOf<String>()
                                for (scale in listOf(1f, 1.6f)) for (size in listOf(150 to 130, 300 to 180, 150 to 96, 300 to 110, 360 to 180)) {
                                    val config = android.content.res.Configuration(resources.configuration).apply { fontScale = scale }
                                    val ctx = createConfigurationContext(config)
                                    for (water in listOf(false, true)) {
                                        val host = android.widget.FrameLayout(ctx)
                                        val child = QuantWidgets.view(ctx, 42, water, size.first.toFloat(), size.second.toFloat()).apply(ctx, host)
                                        host.addView(child)
                                        val density = resources.displayMetrics.density
                                        host.measure(android.view.View.MeasureSpec.makeMeasureSpec((size.first*density).toInt(), android.view.View.MeasureSpec.EXACTLY),
                                            android.view.View.MeasureSpec.makeMeasureSpec((size.second*density).toInt(), android.view.View.MeasureSpec.EXACTLY))
                                        host.layout(0,0,host.measuredWidth,host.measuredHeight)
                                        val content = child.findViewById<android.view.ViewGroup>(R.id.widget_content)
                                        for (index in 0 until content.childCount) {
                                            require(content.getChildAt(index).bottom <= content.height + 1) { "Widget content overflows vertically" }
                                        }
                                        val buttons = child.findViewById<android.view.View>(R.id.widget_buttons)
                                        require(buttons.bottom <= child.height - child.paddingBottom + 1) { "Widget buttons overflow vertically" }
                                        summary.add("${size.first}x${size.second}@$scale:$water")
                                    }
                                }
                                result.success(summary)
                            } catch (e: Exception) { result.error("WIDGET_LAYOUT", e.javaClass.simpleName, null) }
                        }
                    }
                    "initialRoute" -> result.success(widgetRoute(intent))
                    "refresh" -> { QuantWidgets.refresh(this, call.argument<Boolean>("hide")); result.success(null) }
                    else -> result.notImplemented()
                }
            }
        }
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
