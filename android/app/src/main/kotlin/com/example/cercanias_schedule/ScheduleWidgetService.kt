package com.example.cercanias_schedule

import android.content.Context
import android.content.Intent
import android.widget.RemoteViews
import android.widget.RemoteViewsService
import org.json.JSONArray
import org.json.JSONObject
import android.util.Log

class ScheduleWidgetService : RemoteViewsService() {
    override fun onGetViewFactory(intent: Intent): RemoteViewsFactory {
        return ScheduleRemoteViewsFactory(this.applicationContext, intent)
    }
}

class ScheduleRemoteViewsFactory(private val context: Context, intent: Intent) : RemoteViewsService.RemoteViewsFactory {
    private var schedules: JSONArray = JSONArray()

    override fun onCreate() {
        // Connect to data source here if needed
    }

    override fun onDataSetChanged() {
        // This is called when the app calls AppWidgetManager.notifyAppWidgetViewDataChanged()
        // Fetching data from shared preferences or intent extras here
        val prefs = context.getSharedPreferences("WidgetData", Context.MODE_PRIVATE)
        val schedulesJsonString = prefs.getString("schedules", "[]") ?: "[]"
        Log.d("ScheduleWidget", "onDataSetChanged: schedulesJsonString = $schedulesJsonString")
        try {
            schedules = JSONArray(schedulesJsonString)
            Log.d("ScheduleWidget", "onDataSetChanged: schedules count = ${schedules.length()}")
        } catch (e: Exception) {
            Log.e("ScheduleWidget", "Error parsing schedules JSON", e)
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
            Log.d("ScheduleWidget", "getViewAt: position $position, schedule = $schedule")
            views.setTextViewText(R.id.schedule_departure_time, schedule.getString("departureTime"))
            views.setTextViewText(R.id.schedule_arrival_time, schedule.getString("arrivalTime"))
            views.setTextViewText(R.id.schedule_train_code, "Train: ${schedule.getString("trainCode")}")
        } catch (e: Exception) {
            // Handle error
            Log.e("ScheduleWidget", "Error getting view at position $position", e)
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