package com.example.cercanias_schedule

import android.app.Service
import android.content.Intent
import android.os.IBinder
import android.util.Log
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.launch
import org.json.JSONObject
import java.net.HttpURLConnection
import java.net.URL
import java.text.SimpleDateFormat
import java.util.*

class ScheduleUpdateService : Service() {
    private val scope = CoroutineScope(Dispatchers.IO)

    override fun onBind(intent: Intent?): IBinder? = null

    override fun onCreate() {
        super.onCreate()
    }

    override fun onStartCommand(intent: Intent?, flags: Int, startId: Int): Int {
        scope.launch {
            try {
                updateSchedule()
            } catch (e: Exception) {
                Log.e("ScheduleUpdateService", "Error updating schedule", e)
            } finally {
                stopSelf(startId)
            }
        }
        return START_NOT_STICKY
    }

    private suspend fun updateSchedule() {
        val prefs = getSharedPreferences(ScheduleWidget.PREFS_NAME, MODE_PRIVATE)
        val origin = prefs.getString(ScheduleWidget.ORIGIN_KEY, "") ?: return
        val destination = prefs.getString(ScheduleWidget.DESTINATION_KEY, "") ?: return

        val dateFormat = SimpleDateFormat("yyyyMMdd", Locale.getDefault())
        val today = dateFormat.format(Date())

        val url = URL("https://horarios.renfe.com/cer/HorariosServlet")
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.setRequestProperty("Content-Type", "application/json")
        connection.doOutput = true

        val requestBody = JSONObject().apply {
            put("nucleo", "41")
            put("origen", origin)
            put("destino", destination)
            put("fchaViaje", today)
            put("validaReglaNegocio", true)
            put("tiempoReal", false)
            put("servicioHorarios", "VTI")
            put("horaViajeOrigen", "00")
            put("horaViajeLlegada", "26")
            put("accesibilidadTrenes", false)
        }

        connection.outputStream.use { os ->
            os.write(requestBody.toString().toByteArray())
            os.flush()
        }

        val responseCode = connection.responseCode
        if (responseCode == HttpURLConnection.HTTP_OK) {
            val response = connection.inputStream.bufferedReader().use { it.readText() }
            val jsonResponse = JSONObject(response)
            val horarios = jsonResponse.optJSONArray("horario") ?: return

            // Save the updated schedules
            prefs.edit().putString(ScheduleWidget.SCHEDULES_KEY, horarios.toString()).apply()

            // Update the widget
            ScheduleWidget.updateAllWidgets(this@ScheduleUpdateService)
        }
    }
} 