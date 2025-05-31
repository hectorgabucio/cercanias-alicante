package com.example.cercanias_schedule

import android.appwidget.AppWidgetManager
import android.appwidget.AppWidgetProvider
import android.content.Context
import android.content.Intent
import android.content.SharedPreferences
import android.widget.RemoteViews
import android.app.PendingIntent
import android.content.ComponentName
import android.widget.Toast
import java.text.SimpleDateFormat
import java.util.*
import org.json.JSONArray
import org.json.JSONObject
import android.net.Uri
import android.util.Log
import android.app.AlarmManager
import android.os.Build

class ScheduleWidget : AppWidgetProvider() {
    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        // Set up periodic updates when the first widget is created
        setupPeriodicUpdates(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        // Cancel periodic updates when the last widget is disabled
        cancelPeriodicUpdates(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        when (intent.action) {
            SWAP_ACTION -> {
                // Handle swap action
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val origin = prefs.getString(ORIGIN_KEY, "") ?: ""
                val destination = prefs.getString(DESTINATION_KEY, "") ?: ""

                // Swap and save back to shared preferences
                updateData(context, destination, origin, prefs.getString(SCHEDULES_KEY, "[]") ?: "[]")

                // Start the update service to fetch new schedule
                val serviceIntent = Intent(context, ScheduleUpdateService::class.java)
                context.startService(serviceIntent)

                // Update all widgets to reflect the change
                updateAllWidgets(context)
            }
            UPDATE_ACTION -> {
                // Handle periodic update
                updateAllWidgets(context)
            }
        }
    }

    companion object {
        const val PREFS_NAME = "WidgetData"
        const val SCHEDULES_KEY = "schedules"
        const val ORIGIN_KEY = "origin"
        const val DESTINATION_KEY = "destination"
        const val SWAP_ACTION = "com.example.cercanias_schedule.ACTION_SWAP_STATIONS"
        const val UPDATE_ACTION = "com.example.cercanias_schedule.ACTION_UPDATE_WIDGET"
        private const val UPDATE_INTERVAL = 15 * 60 * 1000L // 15 minutes

        private fun setupPeriodicUpdates(context: Context) {
            // Start the update service
            val serviceIntent = Intent(context, ScheduleUpdateService::class.java)
            context.startService(serviceIntent)

            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, ScheduleWidget::class.java).apply {
                action = UPDATE_ACTION
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )

            // Cancel any existing alarms
            alarmManager.cancel(pendingIntent)

            // Set up the periodic update
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) {
                alarmManager.setExactAndAllowWhileIdle(
                    AlarmManager.RTC_WAKEUP,
                    System.currentTimeMillis() + UPDATE_INTERVAL,
                    pendingIntent
                )
            } else {
                alarmManager.setExact(
                    AlarmManager.RTC_WAKEUP,
                    System.currentTimeMillis() + UPDATE_INTERVAL,
                    pendingIntent
                )
            }
        }

        private fun cancelPeriodicUpdates(context: Context) {
            val alarmManager = context.getSystemService(Context.ALARM_SERVICE) as AlarmManager
            val intent = Intent(context, ScheduleWidget::class.java).apply {
                action = UPDATE_ACTION
            }
            val pendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                intent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            alarmManager.cancel(pendingIntent)
        }

        fun updateAppWidget(
            context: Context,
            appWidgetManager: AppWidgetManager,
            appWidgetId: Int
        ) {
            // Construct the RemoteViews object
            val views = RemoteViews(context.packageName, R.layout.widget_layout)

            // Set up the intent to launch the app when the widget is clicked
            val appIntent = Intent(context, MainActivity::class.java)
            val appPendingIntent = PendingIntent.getActivity(
                context,
                0,
                appIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_layout, appPendingIntent)

            // Set up the intent for the RemoteViewsService
            val serviceIntent = Intent(context, ScheduleWidgetService::class.java)
            serviceIntent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            serviceIntent.data = Uri.parse(serviceIntent.toUri(Intent.URI_INTENT_SCHEME))
            views.setRemoteAdapter(R.id.widget_schedule_list, serviceIntent)

            // Set up the intent for the swap button
            val swapIntent = Intent(context, ScheduleWidget::class.java)
            swapIntent.action = SWAP_ACTION
            val swapPendingIntent = PendingIntent.getBroadcast(
                context,
                0,
                swapIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_swap_button, swapPendingIntent)

            // Update route information from shared preferences
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val origin = prefs.getString(ORIGIN_KEY, "") ?: ""
            val destination = prefs.getString(DESTINATION_KEY, "") ?: ""
            views.setTextViewText(R.id.widget_route, "$origin → $destination")

            // Update the last update time
            val dateFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            views.setTextViewText(
                R.id.widget_last_update,
                "Última actualización: ${dateFormat.format(Date())}"
            )

            // Instruct the widget manager to update the widget
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, ScheduleWidget::class.java)
            )
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_schedule_list)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        fun updateData(context: Context, origin: String, destination: String, schedulesJson: String) {
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            prefs.putString(ORIGIN_KEY, origin)
            prefs.putString(DESTINATION_KEY, destination)
            prefs.putString(SCHEDULES_KEY, schedulesJson)
            prefs.apply()
        }
    }
} 