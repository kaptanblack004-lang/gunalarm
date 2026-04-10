package com.example.gun_alarm

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.*

class AlarmWidgetReceiver : AppWidgetProvider() {

    override fun onUpdate(context: Context, appWidgetManager: AppWidgetManager, appWidgetIds: IntArray) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        Toast.makeText(context, "GünAlarm Widget Etkinleþtirildi", Toast.LENGTH_SHORT).show()
    }

    override fun onDisabled(context: Context) {
        Toast.makeText(context, "GünAlarm Widget Devre Dýþý", Toast.LENGTH_SHORT).show()
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        
        when (intent.action) {
            "ADD_ALARM" -> {
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                    putExtra("action", "add_alarm")
                }
                context.startActivity(openAppIntent)
            }
            "OPEN_APP" -> {
                val openAppIntent = Intent(context, MainActivity::class.java).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                }
                context.startActivity(openAppIntent)
            }
            "TOGGLE_ALARM" -> {
                val alarmId = intent.getStringExtra("alarm_id")
                // Toggle alarm logic burada çaðrýlacak
                Toast.makeText(context, "Alarm $alarmId deðiþtirildi", Toast.LENGTH_SHORT).show()
            }
        }
    }

    companion object {
        fun updateAppWidget(context: Context, appWidgetManager: AppWidgetManager, appWidgetId: Int) {
            val views = RemoteViews(context.packageName, R.layout.alarm_widget)

            // Mevcut saati güncelle
            val currentTime = SimpleDateFormat("HH:mm", Locale.getDefault()).format(Date())
            views.setTextViewText(R.id.widget_time, currentTime)

            // Hava durumu bilgilerini güncelle (örnek veriler)
            views.setTextViewText(R.id.widget_weather_temp, "22°C")
            views.setTextViewText(R.id.widget_weather_desc, "Açýk")
            views.setTextViewText(R.id.widget_location, "Ýstanbul")

            // Alarm listesini güncelle (örnek veriler)
            val alarmTexts = listOf("07:00 - Uyanma", "08:30 - Ýþ", "14:00 - Toplantý")
            views.removeAllViews(R.id.widget_alarms_list)
            
            if (alarmTexts.isEmpty()) {
                views.setViewVisibility(R.id.widget_no_alarms, android.view.View.VISIBLE)
                views.setViewVisibility(R.id.widget_alarms_list, android.view.View.GONE)
            } else {
                views.setViewVisibility(R.id.widget_no_alarms, android.view.View.GONE)
                views.setViewVisibility(R.id.widget_alarms_list, android.view.View.VISIBLE)
                
                alarmTexts.forEach { alarmText ->
                    val alarmView = RemoteViews(context.packageName, R.layout.alarm_item)
                    alarmView.setTextViewText(R.id.alarm_item_text, alarmText)
                    views.addView(R.id.widget_alarms_list, alarmView)
                }
            }

            // Butonlar için intent'ler
            val addAlarmIntent = Intent(context, AlarmWidgetReceiver::class.java).apply {
                action = "ADD_ALARM"
            }
            val addAlarmPendingIntent = PendingIntent.getBroadcast(
                context, 0, addAlarmIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_add_alarm, addAlarmPendingIntent)

            val openAppIntent = Intent(context, AlarmWidgetReceiver::class.java).apply {
                action = "OPEN_APP"
            }
            val openAppPendingIntent = PendingIntent.getBroadcast(
                context, 1, openAppIntent, 
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_open_app, openAppPendingIntent)

            // Widget'ý güncelle
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }
    }
}
