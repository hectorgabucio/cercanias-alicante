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

    // Map of station names to codes
    private val stationCodes = mapOf(
        "Alacant Terminal" to "60911",
        "Sant Vicent Centre" to "60913",
        "Murcia del Carmen" to "61200",
        "Elx Parc" to "62103",
        "Torrellano" to "62104",
        "Beniel" to "62001",
        "Lorca-Sutullena" to "06006",
        "Orihuela Miguel Hernández" to "62002"
    )

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
        val originName = prefs.getString(ScheduleWidget.ORIGIN_KEY, "") ?: return
        val destinationName = prefs.getString(ScheduleWidget.DESTINATION_KEY, "") ?: return

        if (originName.isEmpty() || destinationName.isEmpty()) {
            Log.e("ScheduleUpdateService", "Origin or destination is empty")
            return
        }

        // Convert station names to codes
        val origin = stationCodes[originName] ?: run {
            Log.e("ScheduleUpdateService", "Unknown origin station: $originName")
            return
        }
        val destination = stationCodes[destinationName] ?: run {
            Log.e("ScheduleUpdateService", "Unknown destination station: $destinationName")
            return
        }

        val dateFormat = SimpleDateFormat("yyyyMMdd", Locale.getDefault())
        val today = dateFormat.format(Date())

        val url = URL("https://horarios.renfe.com/cer/HorariosServlet")
        val connection = url.openConnection() as HttpURLConnection
        connection.requestMethod = "POST"
        connection.setRequestProperty("Content-Type", "application/json")
        connection.setRequestProperty("Accept", "application/json")
        connection.doOutput = true
        connection.connectTimeout = 10000 // 10 seconds
        connection.readTimeout = 10000 // 10 seconds

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

        try {
            val requestBodyString = requestBody.toString()
            Log.d("ScheduleUpdateService", "Request body: $requestBodyString")
            
            connection.outputStream.use { os ->
                os.write(requestBodyString.toByteArray())
                os.flush()
            }

            val responseCode = connection.responseCode
            Log.d("ScheduleUpdateService", "Response code: $responseCode")

            if (responseCode == HttpURLConnection.HTTP_OK) {
                val response = connection.inputStream.bufferedReader().use { it.readText() }
                Log.d("ScheduleUpdateService", "Raw response: $response")

                if (response.isNotEmpty()) {
                    try {
                        val jsonResponse = JSONObject(response)
                        val horarios = jsonResponse.optJSONArray("horario")
                        if (horarios != null && horarios.length() > 0) {
                            // Save the updated schedules
                            prefs.edit().putString(ScheduleWidget.SCHEDULES_KEY, horarios.toString()).apply()
                            // Update the widget
                            ScheduleWidget.updateAllWidgets(this@ScheduleUpdateService)
                        } else {
                            Log.e("ScheduleUpdateService", "No schedules found in response")
                        }
                    } catch (e: Exception) {
                        Log.e("ScheduleUpdateService", "Error parsing JSON response: ${e.message}")
                    }
                } else {
                    Log.e("ScheduleUpdateService", "Empty response from server")
                }
            } else {
                val errorResponse = connection.errorStream?.bufferedReader()?.use { it.readText() }
                Log.e("ScheduleUpdateService", "HTTP error: $responseCode, Response: $errorResponse")
            }
        } catch (e: Exception) {
            Log.e("ScheduleUpdateService", "Network error: ${e.message}")
        } finally {
            connection.disconnect()
        }
    }
} 