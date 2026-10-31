package com.example.smart_fitness_dashboard

import android.app.Activity
import android.os.Bundle
import android.widget.ScrollView
import android.widget.TextView

class HealthPermissionsActivity : Activity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        title = "quant"
        val language = try {
            val saved = getSharedPreferences("FlutterSharedPreferences", MODE_PRIVATE)
                .getString("flutter.quant.preferences.v1", null)
            if (saved == null) "system" else org.json.JSONObject(saved).optString("language", "system")
        } catch (_: Exception) { "system" }
        val english = language == "en" || (language == "system" && java.util.Locale.getDefault().language == "en")
        val text = TextView(this).apply {
            text = if (english) "quant · Health data access\n\n" +
                "quant reads steps, active/total calories, weight and body fat from Health Connect. " +
                "Data is read while the app is open, remains on your device and is never modified.\n\n" +
                "You can revoke access in Health Connect settings. Enable sharing in your tracker or smart scale companion app first."
            else "quant · Доступ к данным здоровья\n\n" +
                "quant читает шаги, активные/общие калории, вес и процент жира " +
                "из Health Connect для отображения ваших показателей. " +
                "Модуль читает данные только при открытом приложении, не изменяет их " +
                "и не отправляет их на сервер.\n\n" +
                "Разрешения можно отозвать в настройках Health Connect. " +
                "Часы, фитнес-трекеры и умные весы должны самостоятельно передавать данные в Health Connect."
            textSize = 18f
            setPadding(32, 48, 32, 48)
        }
        setContentView(ScrollView(this).apply { addView(text) })
    }
}
