package com.example.flyk

import android.app.PendingIntent
import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import dev.flutter.plugins.home_widget.HomeWidgetPlugin

class FlykWidgetProvider : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    private fun updateAppWidget(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetId: Int
    ) {
        val views = RemoteViews(context.packageName, R.layout.widget_layout)
        
        // Get data from HomeWidget
        val lastIdea = HomeWidgetPlugin.getData<String>("last_idea", "No ideas yet")
        val isRecording = HomeWidgetPlugin.getData<Boolean>("is_recording", false) ?: false
        
        // Update UI
        views.setTextViewText(R.id.widget_status, if (isRecording) "Recording..." else "Long press to record")
        
        // Set up click intent
        val intent = Intent(context, MainActivity::class.java).apply {
            action = "com.example.flyk.START_RECORDING"
            flags = Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_CLEAR_TOP
        }
        val pendingIntent = PendingIntent.getActivity(
            context,
            0,
            intent,
            PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
        )
        
        views.setOnClickPendingIntent(R.id.widget_record_button, pendingIntent)
        
        appWidgetManager.updateAppWidget(appWidgetId, views)
    }
}

