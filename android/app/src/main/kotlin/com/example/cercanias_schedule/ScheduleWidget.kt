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
    companion object {
        private const val TAG = "ScheduleWidget"
        const val PREFS_NAME = "WidgetData"
        const val SCHEDULES_KEY = "schedules"
        const val ORIGIN_KEY = "origin"
        const val DESTINATION_KEY = "destination"
        const val SWAP_ACTION = "com.example.cercanias_schedule.ACTION_SWAP_STATIONS"
        const val UPDATE_ACTION = "com.example.cercanias_schedule.ACTION_UPDATE_WIDGET"
        const val ACTION_ITEM_CLICK = "com.example.cercanias_schedule.ACTION_ITEM_CLICK"
        private const val UPDATE_INTERVAL = 15 * 60 * 1000L // 15 minutes

        private fun setupPeriodicUpdates(context: Context) {
            Log.d(TAG, "Setting up periodic updates")
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
                Log.d(TAG, "Setting up periodic updates for Android M+")
                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    System.currentTimeMillis(),
                    UPDATE_INTERVAL,
                    pendingIntent
                )
            } else {
                Log.d(TAG, "Setting up periodic updates for older Android versions")
                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    System.currentTimeMillis(),
                    UPDATE_INTERVAL,
                    pendingIntent
                )
            }
        }

        private fun cancelPeriodicUpdates(context: Context) {
            Log.d(TAG, "Cancelling periodic updates")
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
            Log.d(TAG, "Updating widget $appWidgetId")
            val views = RemoteViews(context.packageName, R.layout.widget_layout)
            
            // Set up the intent for the RemoteViewsService
            val intent = Intent(context, ScheduleWidgetService::class.java).apply {
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            
            // Set up the RemoteViews adapter
            Log.d(TAG, "Setting up RemoteViews adapter for widget $appWidgetId")
            views.setRemoteAdapter(R.id.widget_schedule_grid, intent)
            
            // Set up click handling for the GridView
            val clickIntent = Intent(context, ScheduleWidget::class.java).apply {
                action = ACTION_ITEM_CLICK
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                data = Uri.parse(toUri(Intent.URI_INTENT_SCHEME))
            }
            val clickPendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                clickIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setPendingIntentTemplate(R.id.widget_schedule_grid, clickPendingIntent)
            
            // Set up the empty view
            views.setEmptyView(R.id.widget_schedule_grid, R.id.widget_empty_view)
            
            // Get the current route from shared preferences
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val origin = prefs.getString(ORIGIN_KEY, "") ?: ""
            val destination = prefs.getString(DESTINATION_KEY, "") ?: ""
            
            // Set the route text
            val routeText = "$origin → $destination"
            Log.d(TAG, "Setting route text: $routeText")
            views.setTextViewText(R.id.widget_route, routeText)
            
            // Set up the swap button
            val swapIntent = Intent(context, ScheduleWidget::class.java).apply {
                action = SWAP_ACTION
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            }
            val swapPendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId,
                swapIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE
            )
            views.setOnClickPendingIntent(R.id.widget_swap_button, swapPendingIntent)
            
            // Set the last update time
            val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            val lastUpdate = timeFormat.format(Date())
            Log.d(TAG, "Setting last update time: $lastUpdate")
            
            // Update the widget
            Log.d(TAG, "Updating widget $appWidgetId with new views")
            appWidgetManager.updateAppWidget(appWidgetId, views)
            
            // Notify the widget that the data has changed
            Log.d(TAG, "Notifying widget $appWidgetId that data has changed")
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetId, R.id.widget_schedule_grid)
        }

        fun updateAllWidgets(context: Context) {
            Log.d(TAG, "Updating all widgets")
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, ScheduleWidget::class.java)
            )
            Log.d(TAG, "Found ${appWidgetIds.size} widgets to update")
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_schedule_grid)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        fun updateData(context: Context, origin: String, destination: String, schedulesJson: String) {
            Log.d(TAG, "Updating data - Origin: $origin, Destination: $destination")
            Log.d(TAG, "Schedules JSON length: ${schedulesJson.length}")
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            prefs.putString(ORIGIN_KEY, origin)
            prefs.putString(DESTINATION_KEY, destination)
            prefs.putString(SCHEDULES_KEY, schedulesJson)
            prefs.apply()
            Log.d(TAG, "Data updated in shared preferences")
        }
    }

    override fun onUpdate(
        context: Context,
        appWidgetManager: AppWidgetManager,
        appWidgetIds: IntArray
    ) {
        Log.d(TAG, "onUpdate called for ${appWidgetIds.size} widgets")
        for (appWidgetId in appWidgetIds) {
            updateAppWidget(context, appWidgetManager, appWidgetId)
        }
    }

    override fun onEnabled(context: Context) {
        super.onEnabled(context)
        Log.d(TAG, "onEnabled called")
        // Set up periodic updates when the first widget is created
        setupPeriodicUpdates(context)
    }

    override fun onDisabled(context: Context) {
        super.onDisabled(context)
        Log.d(TAG, "onDisabled called")
        // Cancel periodic updates when the last widget is disabled
        cancelPeriodicUpdates(context)
    }

    override fun onReceive(context: Context, intent: Intent) {
        super.onReceive(context, intent)
        Log.d(TAG, "onReceive called with action: ${intent.action}")
        when (intent.action) {
            SWAP_ACTION, "android.appwidget.action.APPWIDGET_CLICK" -> {
                Log.d(TAG, "Handling swap action")
                // Handle swap action
                val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
                val origin = prefs.getString(ORIGIN_KEY, "") ?: ""
                val destination = prefs.getString(DESTINATION_KEY, "") ?: ""
                Log.d(TAG, "Current route: $origin → $destination")

                if (origin.isNotEmpty() && destination.isNotEmpty()) {
                    // Swap and save back to shared preferences
                    Log.d(TAG, "Swapping stations")
                    updateData(context, destination, origin, prefs.getString(SCHEDULES_KEY, "[]") ?: "[]")

                    // Start the update service to fetch new schedule
                    val serviceIntent = Intent(context, ScheduleUpdateService::class.java)
                    Log.d(TAG, "Starting update service")
                    if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.O) {
                        context.startForegroundService(serviceIntent)
                    } else {
                        context.startService(serviceIntent)
                    }

                    // Update all widgets to reflect the change
                    Log.d(TAG, "Updating all widgets")
                    updateAllWidgets(context)
                } else {
                    Log.w(TAG, "Cannot swap: origin or destination is empty")
                }
            }
            UPDATE_ACTION -> {
                Log.d(TAG, "Handling periodic update")
                // Handle periodic update
                updateAllWidgets(context)
            }
        }
    }
} 