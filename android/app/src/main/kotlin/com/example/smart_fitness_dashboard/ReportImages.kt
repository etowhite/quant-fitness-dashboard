package com.example.smart_fitness_dashboard

import android.content.ContentValues
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore
import androidx.core.content.FileProvider
import io.flutter.plugin.common.MethodChannel
import java.io.File

object ReportImages {
    fun handle(activity: MainActivity, call: io.flutter.plugin.common.MethodCall, result: MethodChannel.Result) {
        if (call.method == "sdk") { result.success(Build.VERSION.SDK_INT); return }
        if (call.method !in listOf("save", "share")) { result.notImplemented(); return }
        val bytes = call.arguments as? ByteArray
        if (bytes == null || bytes.size > 25 * 1024 * 1024 || bytes.size < 8 ||
            !bytes.take(8).toByteArray().contentEquals(byteArrayOf(-119,80,78,71,13,10,26,10))) {
            result.error("IMAGE", "Invalid PNG", null); return
        }
        Thread {
            val main = Handler(Looper.getMainLooper())
            try {
                val filename = "quant-report-${System.currentTimeMillis()}.png"
                if (call.method == "save") {
                    val resolver = activity.contentResolver
                    val values = ContentValues().apply {
                        put(MediaStore.Images.Media.DISPLAY_NAME, filename)
                        put(MediaStore.Images.Media.MIME_TYPE, "image/png")
                        if (Build.VERSION.SDK_INT >= 29) {
                            put(MediaStore.Images.Media.RELATIVE_PATH, "Pictures/quant")
                            put(MediaStore.Images.Media.IS_PENDING, 1)
                        }
                    }
                    val uri = resolver.insert(MediaStore.Images.Media.EXTERNAL_CONTENT_URI, values)
                        ?: throw IllegalStateException("MediaStore unavailable")
                    try {
                        (resolver.openOutputStream(uri) ?: throw IllegalStateException("No output")).use { it.write(bytes) }
                        if (Build.VERSION.SDK_INT >= 29) resolver.update(uri, ContentValues().apply {put(MediaStore.Images.Media.IS_PENDING, 0)}, null, null)
                    } catch (e: Exception) { resolver.delete(uri, null, null); throw e }
                    main.post { result.success(true) }
                } else {
                    val dir = File(activity.cacheDir, "reports").apply { mkdirs() }
                    dir.listFiles()?.filter { System.currentTimeMillis() - it.lastModified() > 86400000 }?.forEach { it.delete() }
                    val file = File(dir, filename).apply { writeBytes(bytes) }
                    val uri = FileProvider.getUriForFile(activity, "${activity.packageName}.reports", file)
                    main.post {
                        try {
                            val intent = Intent(Intent.ACTION_SEND).apply {
                                type = "image/png"
                                putExtra(Intent.EXTRA_STREAM, uri)
                                clipData = android.content.ClipData.newRawUri("quant report", uri)
                                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                            }
                            activity.startActivity(Intent.createChooser(intent, null))
                            result.success(true)
                        } catch (_: Exception) { file.delete(); result.error("SHARE", "Cannot open share sheet", null) }
                    }
                }
            } catch (_: Exception) { main.post { result.error("IMAGE", "Cannot save image", null) } }
        }.start()
    }
}
