package com.example.cercanias_schedule

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject
import java.text.SimpleDateFormat
import java.util.*

class ScheduleWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ScheduleRemoteViewsFactory(this.applicationContext, intent)
    }
}

class ScheduleRemoteViewsFactory(private val context: Context, intent: Intent) : RemoteViewsService.RemoteViewsFactory {
    private var schedules: JSONArray = JSONArray()
    private val timeFormat = SimpleDateFormat("HH:mm", Locale.getDefault())

    override fun onCreate() {
        // Connect to data source here if needed
    }

    override fun onDataSetChanged() {
        // This is called when the app calls AppWidgetManager.notifyAppWidgetViewDataChanged()
        // Fetching data from shared preferences or intent extras here
        val prefs = context.getSharedPreferences(ScheduleWidget.PREFS_NAME, Context.MODE_PRIVATE)
        val schedulesJsonString = prefs.getString(ScheduleWidget.SCHEDULES_KEY, "[]") ?: "[]"
        try {
            val allSchedules = JSONArray(schedulesJsonString)
            val filteredSchedules = JSONArray()
            
            // Get current time and subtract 5 minutes to get the cutoff time
            val calendar = Calendar.getInstance()
            calendar.add(Calendar.MINUTE, -5)
            val cutoffTime = timeFormat.format(calendar.time)
            
            // Filter schedules - keep all schedules that are 5 minutes in the past or newer
            for (i in 0 until allSchedules.length()) {
                val schedule = allSchedules.getJSONObject(i)
                val departureTime = schedule.getString("horaSalida")
                if (departureTime.compareTo(cutoffTime) >= 0) {
                    filteredSchedules.put(schedule)
                }
            }
            
            schedules = filteredSchedules
        } catch (e: Exception) {
            schedules = JSONArray() // Clear schedules on error
        }
    }

    override fun onDestroy() {
        // Clean up data source here if needed
    }

    override fun getCount(): Int {
        return schedules.length()
    }

    override fun getViewAt(position: Int): RemoteViews {
        val views = RemoteViews(context.packageName, R.layout.widget_schedule_item)
        try {
            val schedule = schedules.getJSONObject(position)
            views.setTextViewText(R.id.schedule_departure_time, schedule.getString("horaSalida"))
            views.setTextViewText(R.id.schedule_arrival_time, schedule.getString("horaLlegada"))
            views.setTextViewText(R.id.schedule_train_code, "Train: ${schedule.getString("cdgoTren")}")
        } catch (e: Exception) {
            // Handle error
            views.setTextViewText(R.id.schedule_departure_time, "Error")
            views.setTextViewText(R.id.schedule_arrival_time, "")
            views.setTextViewText(R.id.schedule_train_code, "")
        }
        return views
    }

    override fun getLoadingView(): RemoteViews? {
        return null // Use default loading view
    }

    override fun getViewTypeCount(): Int {
        return 1
    }

    override fun getItemId(position: Int): Long {
        return position.toLong()
    }

    override fun hasStableIds(): Boolean {
        return true
    }
} 