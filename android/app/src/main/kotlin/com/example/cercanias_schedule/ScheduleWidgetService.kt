package com.example.cercanias_schedule

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*
import android.util.Log
import android.appwidget.AppWidgetManager
import android.content.ComponentName

class ScheduleWidgetService : RemoteViewsService() {
    private val TAG = "ScheduleWidgetService"

    override fun onCreate() {
        super.onCreate()
        Log.d(TAG, "Service onCreate called")
    }

    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        Log.d(TAG, "onGetViewFactory called with intent: ${intent.data}")
        val widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        Log.d(TAG, "Widget ID from intent: $widgetId")
        val factory = ScheduleRemoteViewsFactory(this.applicationContext, intent)
        Log.d(TAG, "Created new RemoteViewsFactory for GridView")
        return factory
    }

    override fun onDestroy() {
        super.onDestroy()
        Log.d(TAG, "Service onDestroy called")
    }
}

class ScheduleRemoteViewsFactory(private val context: Context, intent: Intent) : RemoteViewsService.RemoteViewsFactory {
    private var schedules: JSONArray = JSONArray()
    private val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())
    private val TAG = "ScheduleRemoteViewsFactory"
    private val widgetId: Int

    init {
        Log.d(TAG, "Factory init block called")
        widgetId = intent.getIntExtra(AppWidgetManager.EXTRA_APPWIDGET_ID, -1)
        Log.d(TAG, "Factory created for widget ID: $widgetId")
    }

    override fun onCreate() {
        Log.d(TAG, "onCreate called for widget $widgetId")
        onDataSetChanged()
    }

    override fun onDataSetChanged() {
        Log.d(TAG, "onDataSetChanged called for widget $widgetId")
        // This is called when the app calls AppWidgetManager.notifyAppWidgetViewDataChanged()
        // Fetching data from shared preferences or intent extras here
        val prefs = context.getSharedPreferences(ScheduleWidget.PREFS_NAME, Context.MODE_PRIVATE)
        val schedulesJsonString = prefs.getString(ScheduleWidget.SCHEDULES_KEY, "[]") ?: "[]"
        Log.d(TAG, "Raw schedules JSON for widget $widgetId: $schedulesJsonString")
        
        try {
            val allSchedules = JSONArray(schedulesJsonString)
            val filteredSchedules = JSONArray()
            
            // Get current time and subtract 5 minutes to get the cutoff time
            val calendar = Calendar.getInstance()
            calendar.add(Calendar.MINUTE, -5)
            val cutoffTime = timeFormat.format(calendar.time)
            Log.d(TAG, "Cutoff time for widget $widgetId: $cutoffTime")
            
            // Filter schedules - keep all schedules that are 5 minutes in the past or newer
            for (i in 0 until allSchedules.length()) {
                val schedule = allSchedules.getJSONObject(i)
                val departureTime = schedule.getString("horaSalida")
                Log.d(TAG, "Checking schedule for widget $widgetId: $departureTime")
                if (departureTime.compareTo(cutoffTime) >= 0) {
                    filteredSchedules.put(schedule)
                    Log.d(TAG, "Added schedule for widget $widgetId: $departureTime")
                } else {
                    Log.d(TAG, "Filtered out schedule for widget $widgetId: $departureTime")
                }
            }
            
            Log.d(TAG, "Setting schedules for widget $widgetId. Previous count: ${schedules.length()}, New count: ${filteredSchedules.length()}")
            schedules = filteredSchedules
            Log.d(TAG, "Final filtered schedules count for widget $widgetId: ${schedules.length()}")
            for (i in 0 until schedules.length()) {
                val schedule = schedules.getJSONObject(i)
                Log.d(TAG, "Schedule $i for widget $widgetId: ${schedule.getString("horaSalida")}")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error processing schedules for widget $widgetId", e)
            schedules = JSONArray() // Clear schedules on error
        }
    }

    override fun onDestroy() {
        Log.d(TAG, "onDestroy called for widget $widgetId")
    }

    override fun getCount(): Int {
        Log.d(TAG, "getCount called for widget $widgetId, returning 6 (2x3 grid)")
        return 6 // We always show 6 items (2 rows of 3)
    }

    override fun getViewAt(position: Int): RemoteViews {
        Log.d(TAG, "getViewAt called for widget $widgetId at position: $position (row: ${position / 3}, col: ${position % 3})")
        val views = RemoteViews(context.packageName, R.layout.widget_time_item)
        
        try {
            if (position < schedules.length()) {
                val schedule = schedules.getJSONObject(position)
                val time = schedule.getString("horaSalida")
                Log.d(TAG, "Setting time for widget $widgetId at position $position (row: ${position / 3}, col: ${position % 3}): $time")
                views.setTextViewText(R.id.time_text, time)
            } else {
                Log.d(TAG, "Position $position (row: ${position / 3}, col: ${position % 3}) is empty for widget $widgetId, setting placeholder")
                views.setTextViewText(R.id.time_text, "-")
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error setting view for widget $widgetId at position $position (row: ${position / 3}, col: ${position % 3})", e)
            views.setTextViewText(R.id.time_text, "-")
        }
        
        return views
    }

    override fun getLoadingView(): RemoteViews? {
        Log.d(TAG, "getLoadingView called for widget $widgetId")
        return null // Use default loading view
    }

    override fun getViewTypeCount(): Int {
        Log.d(TAG, "getViewTypeCount called for widget $widgetId, returning 1")
        return 1
    }

    override fun getItemId(position: Int): Long {
        Log.d(TAG, "getItemId called for widget $widgetId at position: $position")
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        Log.d(TAG, "hasStableIds called for widget $widgetId, returning true")
        return true
    }
} 