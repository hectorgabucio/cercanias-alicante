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
    private val TAG = "ScheduleWidget"

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

    companion object {
        const val PREFS_NAME = "WidgetData"
        const val SCHEDULES_KEY = "schedules"
        const val ORIGIN_KEY = "origin"
        const val DESTINATION_KEY = "destination"
        const val SWAP_ACTION = "com.example.cercanias_schedule.ACTION_SWAP_STATIONS"
        const val UPDATE_ACTION = "com.example.cercanias_schedule.ACTION_UPDATE_WIDGET"
        private const val UPDATE_INTERVAL = 15 * 60 * 1000L // 15 minutes

        private fun setupPeriodicUpdates(context: Context) {
            Log.d("ScheduleWidget", "Setting up periodic updates")
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
                Log.d("ScheduleWidget", "Setting up periodic updates for Android M+")
                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    System.currentTimeMillis(),
                    UPDATE_INTERVAL,
                    pendingIntent
                )
            } else {
                Log.d("ScheduleWidget", "Setting up periodic updates for older Android versions")
                alarmManager.setRepeating(
                    AlarmManager.RTC_WAKEUP,
                    System.currentTimeMillis(),
                    UPDATE_INTERVAL,
                    pendingIntent
                )
            }
        }

        private fun cancelPeriodicUpdates(context: Context) {
            Log.d("ScheduleWidget", "Cancelling periodic updates")
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
            Log.d("ScheduleWidget", "Updating widget $appWidgetId")
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
            val intent = Intent(context, ScheduleWidgetService::class.java)
            intent.putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
            intent.data = Uri.parse(intent.toUri(Intent.URI_INTENT_SCHEME))
            Log.d("ScheduleWidget", "Setting up RemoteViews adapter for widget $appWidgetId")
            views.setRemoteAdapter(R.id.widget_schedule_grid, intent)

            // Set up empty view
            views.setEmptyView(R.id.widget_schedule_grid, R.id.widget_empty_view)

            // Set up the intent for the swap button with a unique request code
            val swapIntent = Intent(context, ScheduleWidget::class.java).apply {
                action = SWAP_ACTION
                // Add unique data to prevent intent reuse
                data = Uri.parse("swap://${System.currentTimeMillis()}")
                // Add widget ID as extra to ensure uniqueness
                putExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, appWidgetId)
                // Add flags to make the intent more persistent
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            val swapPendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId, // Use widget ID as request code to make it unique
                swapIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_ONE_SHOT
            )
            views.setOnClickPendingIntent(R.id.widget_swap_button, swapPendingIntent)

            // Also set up a click listener on the entire widget for swap
            val widgetSwapIntent = Intent(context, ScheduleWidget::class.java).apply {
                action = "android.appwidget.action.APPWIDGET_CLICK"
                data = Uri.parse("widget://${appWidgetId}")
                // Add flags to make the intent more persistent
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                addFlags(Intent.FLAG_ACTIVITY_CLEAR_TOP)
            }
            val widgetSwapPendingIntent = PendingIntent.getBroadcast(
                context,
                appWidgetId + 1000, // Different request code
                widgetSwapIntent,
                PendingIntent.FLAG_UPDATE_CURRENT or PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_ONE_SHOT
            )
            views.setOnClickPendingIntent(R.id.widget_swap_button, widgetSwapPendingIntent)

            // Update route information from shared preferences
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
            val origin = prefs.getString(ORIGIN_KEY, "") ?: ""
            val destination = prefs.getString(DESTINATION_KEY, "") ?: ""
            Log.d("ScheduleWidget", "Setting route text: $origin → $destination")
            views.setTextViewText(R.id.widget_route, "$origin → $destination")

            // Update the last update time
            val dateFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
            val updateTime = dateFormat.format(Date())
            Log.d("ScheduleWidget", "Setting last update time: $updateTime")
            views.setTextViewText(
                R.id.widget_last_update,
                "Última actualización: $updateTime"
            )

            // Instruct the widget manager to update the widget
            Log.d("ScheduleWidget", "Updating widget $appWidgetId with new views")
            appWidgetManager.updateAppWidget(appWidgetId, views)
        }

        fun updateAllWidgets(context: Context) {
            Log.d("ScheduleWidget", "Updating all widgets")
            val appWidgetManager = AppWidgetManager.getInstance(context)
            val appWidgetIds = appWidgetManager.getAppWidgetIds(
                ComponentName(context, ScheduleWidget::class.java)
            )
            Log.d("ScheduleWidget", "Found ${appWidgetIds.size} widgets to update")
            appWidgetManager.notifyAppWidgetViewDataChanged(appWidgetIds, R.id.widget_schedule_grid)
            for (appWidgetId in appWidgetIds) {
                updateAppWidget(context, appWidgetManager, appWidgetId)
            }
        }

        fun updateData(context: Context, origin: String, destination: String, schedulesJson: String) {
            Log.d("ScheduleWidget", "Updating data - Origin: $origin, Destination: $destination")
            Log.d("ScheduleWidget", "Schedules JSON length: ${schedulesJson.length}")
            val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE).edit()
            prefs.putString(ORIGIN_KEY, origin)
            prefs.putString(DESTINATION_KEY, destination)
            prefs.putString(SCHEDULES_KEY, schedulesJson)
            prefs.apply()
            Log.d("ScheduleWidget", "Data updated in shared preferences")
        }
    }
} 