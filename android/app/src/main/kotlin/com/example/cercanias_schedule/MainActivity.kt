package com.example.cercanias_schedule

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import org.json.JSONArray
import org.json.JSONObject

class MainActivity : FlutterActivity() {
    private val CHANNEL = "com.example.cercanias_schedule/widget"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "updateWidget" -> {
                    try {
                        val origin = call.argument<String>("origin") ?: ""
                        val destination = call.argument<String>("destination") ?: ""
                        val schedulesJson = call.argument<String>("schedulesJson") ?: "[]"
                        
                        // Update widget data
                        ScheduleWidget.updateData(this, origin, destination, schedulesJson)
                        
                        // Update all widgets
                        ScheduleWidget.updateAllWidgets(this)
                        
                        result.success(null)
                    } catch (e: Exception) {
                        result.error("WIDGET_UPDATE_ERROR", e.message, null)
                    }
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }
}
