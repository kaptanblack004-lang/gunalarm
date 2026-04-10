package com.example.gun_alarm

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProviderInfo
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.widget.RemoteViews
import android.widget.RemoteViewsService

class AlarmWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return AlarmRemoteViewsFactory(applicationContext, intent)
    }
}

class AlarmRemoteViewsFactory(
    private val context: Context,
    private val intent: Intent
) : RemoteViewsService.RemoteViewsFactory {

    private val alarmList = mutableListOf<Map<String, Any>>()

    override fun onCreate() {
        // Örnek alarm verileri
        alarmList.addAll(listOf(
            mapOf(
                "time" to "07:00",
                "label" to "Uyanma",
                "enabled" to true
            ),
            mapOf(
                "time" to "08:30",
                "label" to "Ýþ",
                "enabled" to true
            ),
            mapOf(
                "time" to "14:00",
                "label" to "Toplantý",
                "enabled" to false
            )
        ))
    }

    override fun onDestroy() {
        alarmList.clear()
    }

    override fun getCount(): Int = alarmList.size

    override fun getViewAt(position: Int): RemoteViews {
        val alarm = alarmList[position]
        val views = RemoteViews(context.packageName, R.layout.alarm_item)
        
        views.setTextViewText(R.id.alarm_item_text, "${alarm["time"]} - ${alarm["label"]}")
        
        val statusText = if (alarm["enabled"] as Boolean) "Aç" else "Kapat"
        views.setTextViewText(R.id.alarm_item_toggle, statusText)
        
        // Toggle butonu için intent
        val toggleIntent = Intent().apply {
            action = "TOGGLE_ALARM"
            putExtra("alarm_id", position.toString())
        }
        views.setOnClickFillInIntent(R.id.alarm_item_toggle, toggleIntent)
        
        return views
    }

    override fun getLoadingView(): RemoteViews? = null

    override fun getViewTypeCount(): Int = 1

    override fun getItemId(position: Int): Long = position.toLong()

    override fun hasStableIds(): Boolean = true

    override fun onDataSetChanged() {
        // Verileri yenile
        alarmList.clear()
        onCreate()
    }
}
