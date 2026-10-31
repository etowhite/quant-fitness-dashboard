package com.example.smart_fitness_dashboard

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.*
import android.graphics.Color
import android.net.Uri
import android.os.*
import android.util.SizeF
import android.util.TypedValue
import android.view.View
import android.widget.RemoteViews
import androidx.work.*
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.FlutterInjector
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import java.util.Calendar
import java.util.UUID
import java.util.concurrent.CountDownLatch
import java.util.concurrent.TimeUnit

object QuantWidgets {
    private const val CACHE = "quant_widget_snapshot"
    internal val workerLock = Any()
    fun ids(context: Context): IntArray {
        val manager = AppWidgetManager.getInstance(context)
        return manager.getAppWidgetIds(ComponentName(context, QuantDashboardWidget::class.java)) +
            manager.getAppWidgetIds(ComponentName(context, QuantWaterWidget::class.java))
    }
    fun refresh(context: Context, hide: Boolean? = null) {
        if (hide != null) context.getSharedPreferences(CACHE, 0).edit().putBoolean("hidden", hide).putBoolean("privacy_override", true).commit()
        renderAll(context)
        if (ids(context).isNotEmpty()) enqueue(context, "refresh")
    }
    fun enqueue(context: Context, action: String, volume: Int = 0) {
        val data = workDataOf("action" to action, "volume" to volume, "id" to UUID.randomUUID().toString(), "at" to System.currentTimeMillis())
        val request = OneTimeWorkRequestBuilder<QuantWidgetWorker>().setInputData(data)
            .setBackoffCriteria(BackoffPolicy.LINEAR, 10, TimeUnit.SECONDS).build()
        // Every tap gets a durable request; no REPLACE/debounce on mutations.
        WorkManager.getInstance(context).enqueueUniqueWork("quant-widget-actions", ExistingWorkPolicy.APPEND_OR_REPLACE, request)
    }
    fun scheduleMidnight(context: Context) {
        if (ids(context).isEmpty()) return
        val next = Calendar.getInstance().apply { add(Calendar.DATE, 1); set(Calendar.HOUR_OF_DAY, 0); set(Calendar.MINUTE, 0); set(Calendar.SECOND, 5) }
        val work = OneTimeWorkRequestBuilder<QuantWidgetWorker>().setInputData(workDataOf("action" to "refresh"))
            .setInitialDelay((next.timeInMillis-System.currentTimeMillis()).coerceAtLeast(1000), TimeUnit.MILLISECONDS).build()
        WorkManager.getInstance(context).enqueueUniqueWork("quant-widget-midnight", ExistingWorkPolicy.REPLACE, work)
    }
    fun save(context: Context, map: Map<*, *>) {
        val prefs = context.getSharedPreferences(CACHE, 0)
        val edit = prefs.edit().putString("snapshot", JSONObject(map).toString()).remove("error")
        if (!prefs.getBoolean("privacy_override", false)) edit.putBoolean("hidden", map["hidden"] as? Boolean ?: true)
        edit.commit()
        renderAll(context); scheduleMidnight(context)
    }
    fun error(context: Context) {
        context.getSharedPreferences(CACHE, 0).edit().putBoolean("error", true).commit()
        renderAll(context)
    }
    fun renderAll(context: Context) {
        val manager = AppWidgetManager.getInstance(context)
        for (cls in arrayOf(QuantDashboardWidget::class.java, QuantWaterWidget::class.java)) {
            for (id in manager.getAppWidgetIds(ComponentName(context, cls))) render(context, manager, id, cls == QuantWaterWidget::class.java)
        }
    }
    private fun open(context: Context, route: String): PendingIntent = PendingIntent.getActivity(context, route.hashCode(),
        Intent(context, MainActivity::class.java).setAction(Intent.ACTION_VIEW)
            .setData(Uri.parse("quant://widget/$route")).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)
    private fun action(context: Context, id: Int, volume: Int): PendingIntent = PendingIntent.getBroadcast(context, id * 1000 + volume,
        Intent(context, QuantWidgetActionReceiver::class.java).setAction("quant.WATER")
            .setData(Uri.parse("quant://widget-action/$id/$volume")).putExtra("volume", volume),
        PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE)

    fun render(context: Context, manager: AppWidgetManager, id: Int, water: Boolean) {
        val options = manager.getAppWidgetOptions(id)
        if (Build.VERSION.SDK_INT >= 31) {
            val sizes = options.getParcelableArrayList<SizeF>(AppWidgetManager.OPTION_APPWIDGET_SIZES)
            if (!sizes.isNullOrEmpty()) {
                val views = sizes.distinct().take(16).associateWith { view(context, id, water, it.width, it.height) }
                manager.updateAppWidget(id, RemoteViews(views)); return
            }
        }
        manager.updateAppWidget(id, view(context, id, water,
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MIN_WIDTH, if(water) 150 else 160).toFloat(),
            options.getInt(AppWidgetManager.OPTION_APPWIDGET_MAX_HEIGHT, if(water) 100 else 180).toFloat()))
    }
    // Public for the on-device widget host tests; no data writes here.
    fun view(context: Context, id: Int, waterOnly: Boolean, width: Float, height: Float): RemoteViews {
        val prefs = context.getSharedPreferences(CACHE, 0)
        val snapshot = try { JSONObject(prefs.getString("snapshot", "{}")!!) } catch (_: Exception) { JSONObject() }
        val language = snapshot.optString("language", context.resources.configuration.locales[0].language)
        val en = language == "en"
        fun text(ru: String, english: String) = if (en) english else ru
        val today = Calendar.getInstance()
        val day = "${today.get(Calendar.YEAR)}-${today.get(Calendar.MONTH)+1}-${today.get(Calendar.DATE)}"
        val fresh = snapshot.optString("day") == day && snapshot.optInt("zone", Int.MIN_VALUE) == java.util.TimeZone.getDefault().getOffset(System.currentTimeMillis()) / 60000
        val hidden = prefs.getBoolean("hidden", true)
        val systemDark = (context.resources.configuration.uiMode and 48) == 32
        val dark = when(snapshot.optString("mode", "dark")) { "light" -> false; "system" -> systemDark; else -> true }
        val fg = if(dark) Color.rgb(245,245,245) else Color.rgb(23,33,45)
        // Calm dark-on-light accent, independent of neon brightness.
        val accent = if(dark) snapshot.optLong("accent", 0xFF00FF87).toInt() else Color.rgb(0,110,100)
        val view = RemoteViews(context.packageName, R.layout.quant_widget)
        val background = when {
            !dark -> R.drawable.quant_widget_bg_light
            snapshot.optBoolean("amoled") -> R.drawable.quant_widget_bg_black
            else -> R.drawable.quant_widget_bg
        }
        view.setInt(R.id.widget_root, "setBackgroundResource", background)
        view.setTextViewText(R.id.widget_title, if(waterOnly) text("quant · вода", "quant · water") else "quant")
        view.setTextColor(R.id.widget_title, fg)
        view.setOnClickPendingIntent(R.id.widget_title, open(context, "dashboard"))
        view.setViewVisibility(R.id.widget_title, if(height < 110 || (height < 180 && context.resources.configuration.fontScale > 1.3f)) View.GONE else View.VISIBLE)
        val status = when {
            prefs.getBoolean("error", false) -> text("Не удалось сохранить · откройте quant", "Could not save · open quant")
            hidden -> text("Данные скрыты", "Data hidden")
            !fresh -> text("Обновление…", "Updating…")
            else -> ""
        }
        view.setTextViewText(R.id.widget_status, status); view.setTextColor(R.id.widget_status, fg)
        view.setViewVisibility(R.id.widget_status, if(status.isEmpty()) View.GONE else View.VISIBLE)
        view.setOnClickPendingIntent(R.id.widget_status, open(context, if(waterOnly) "water" else "dashboard"))
        view.removeAllViews(R.id.widget_content); view.removeAllViews(R.id.widget_buttons)
        fun metric(label: String, actual: String, current: Double?, goal: Double?, route: String) {
            val metric = RemoteViews(context.packageName, R.layout.quant_widget_metric)
            metric.setTextViewText(R.id.metric_value, (if(hidden) "$label · •••" else if(!fresh) "$label · —" else "$label $actual").trim())
            metric.setTextColor(R.id.metric_value, fg)
            val scale = context.resources.configuration.fontScale
            metric.setTextViewTextSize(R.id.metric_value, TypedValue.COMPLEX_UNIT_SP,
                if(width < 190 || scale > 1.3f) 11f else 14f)
            val showProgress = !hidden && fresh && current != null && goal != null && height >= (if(waterOnly) { if(scale > 1.3f) 105 else 95 } else 180)
            metric.setViewVisibility(R.id.metric_progress, if(showProgress) View.VISIBLE else View.GONE)
            if(showProgress) metric.setProgressBar(R.id.metric_progress, 1000, ((current!! / goal!!.coerceAtLeast(1.0))*1000).toInt().coerceIn(0,1000), false)
            metric.setOnClickPendingIntent(R.id.metric_root, open(context, route))
            metric.setContentDescription(R.id.metric_root, if(hidden) text("Данные скрыты", "Data hidden") else if(!fresh) "$label —" else "$label $actual")
            view.addView(R.id.widget_content, metric)
        }
        fun num(key: String) = snapshot.optDouble(key, 0.0)
        val water = num("water"); val waterGoal = num("waterGoal")
        if(!waterOnly) metric(text("Ккал", "kcal"), "${num("calories").toInt()} / ${num("calorieGoal").toInt()}", num("calories"), num("calorieGoal"), "nutrition")
        metric(if(waterOnly && width < 190) "" else text("Вода", "Water"), "${water.toInt()}/${waterGoal.toInt()} ${text("мл", "ml")}", water, waterGoal, "water")
        if(!waterOnly) {
            val steps = if(snapshot.isNull("steps")) null else num("steps")
            metric(text("Шаги", "Steps"), if(steps == null) text("нет доступа · quant", "sync in quant") else "${steps.toInt()} / ${num("stepGoal").toInt()}", steps, num("stepGoal"), "activity")
            if(height >= 180 || (width >= 270 && height >= 130)) metric(text("Б/Ж/У", "P/F/C"), "${num("proteins").toInt()} / ${num("fats").toInt()} / ${num("carbs").toInt()} ${text("г", "g")}", null, null, "nutrition")
        } else {
            val volumes = if(width >= 270) listOf(100,250,500) else listOf(250)
            for(volume in volumes + if(width >= 360 || height >= 145) listOf(0) else emptyList()) {
                val button = RemoteViews(context.packageName, R.layout.quant_widget_button)
                val label = if(volume == 0) text("Отмена", "Undo") else "+$volume ${text("мл", "ml")}"
                button.setTextViewText(R.id.widget_button, label); button.setTextColor(R.id.widget_button, accent)
                if(context.resources.configuration.fontScale > 1.3f) button.setTextViewTextSize(R.id.widget_button, TypedValue.COMPLEX_UNIT_SP, 10f)
                button.setInt(R.id.widget_button, "setBackgroundResource", if(dark) R.drawable.quant_widget_bg else R.drawable.quant_widget_bg_light)
                button.setContentDescription(R.id.widget_button, if(volume==0) text("Отменить последнюю порцию", "Undo last portion") else "+$volume ${text("мл", "ml")}")
                button.setOnClickPendingIntent(R.id.widget_button, action(context, id, volume))
                view.addView(R.id.widget_buttons, button)
            }
        }
        return view
    }
}

class QuantDashboardWidget : AppWidgetProvider() {
    override fun onUpdate(c: Context, m: AppWidgetManager, ids: IntArray) { QuantWidgets.refresh(c); QuantWidgets.scheduleMidnight(c) }
    override fun onAppWidgetOptionsChanged(c: Context, m: AppWidgetManager, id: Int, options: Bundle) { QuantWidgets.render(c,m,id,false) }
}
class QuantWaterWidget : AppWidgetProvider() {
    override fun onUpdate(c: Context, m: AppWidgetManager, ids: IntArray) { QuantWidgets.refresh(c); QuantWidgets.scheduleMidnight(c) }
    override fun onAppWidgetOptionsChanged(c: Context, m: AppWidgetManager, id: Int, options: Bundle) { QuantWidgets.render(c,m,id,true) }
}
class QuantWidgetActionReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        if(intent.action != "quant.WATER") return
        val volume = intent.getIntExtra("volume", -1)
        if(volume !in listOf(0,100,250,500)) return
        QuantWidgets.enqueue(context, if(volume==0) "undo" else "add", volume)
    }
}
class QuantWidgetTimeReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) { QuantWidgets.refresh(context); QuantWidgets.scheduleMidnight(context) }
}
class QuantWidgetWorker(context: Context, parameters: WorkerParameters) : Worker(context, parameters) {
    override fun doWork(): Result = synchronized(QuantWidgets.workerLock) { runJob() }

    private fun runJob(): Result {
        val done = CountDownLatch(1); var success = false
        var engine: FlutterEngine? = null
        val main = Handler(Looper.getMainLooper())
        main.post {
            try {
                val loader = FlutterInjector.instance().flutterLoader()
                loader.startInitialization(applicationContext); loader.ensureInitializationComplete(applicationContext, null)
                val created = FlutterEngine(applicationContext); engine = created
                MethodChannel(created.dartExecutor.binaryMessenger, "quant/widget_worker").setMethodCallHandler { call, result ->
                    when(call.method) {
                        "ready" -> result.success(mapOf("action" to (inputData.getString("action") ?: "refresh"), "volume" to inputData.getInt("volume",0), "id" to inputData.getString("id"), "at" to inputData.getLong("at", System.currentTimeMillis())))
                        "complete" -> {
                            val map = call.arguments as? Map<*, *>
                            if(map != null) { QuantWidgets.save(applicationContext, map); success = true }
                            result.success(null); done.countDown()
                        }
                        "failed" -> { result.success(null); done.countDown() }
                        else -> result.notImplemented()
                    }
                }
                created.dartExecutor.executeDartEntrypoint(DartExecutor.DartEntrypoint(loader.findAppBundlePath(), "package:smart_fitness_dashboard/main.dart", "widgetMain"))
            } catch (_: Exception) { done.countDown() }
        }
        done.await(90, TimeUnit.SECONDS)
        main.post { engine?.destroy() }
        if(!success) QuantWidgets.error(applicationContext)
        return if(success) Result.success() else if(runAttemptCount < 2) Result.retry() else Result.failure()
    }
}
