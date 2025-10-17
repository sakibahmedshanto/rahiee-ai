package com.tanainent.rahieeai

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.os.Build
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val CHANNEL = "rahiee_ai/notifications"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL).setMethodCallHandler { call, result ->
            when (call.method) {
                "createNotificationChannel" -> {
                    createNotificationChannel(call.arguments as Map<String, Any>)
                    result.success(null)
                }
                else -> {
                    result.notImplemented()
                }
            }
        }
    }

    private fun createNotificationChannel(arguments: Map<String, Any>) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val channelId = arguments["channelId"] as String
            val channelName = arguments["channelName"] as String
            val channelDescription = arguments["channelDescription"] as String
            val importance = when (arguments["importance"] as String) {
                "high" -> NotificationManager.IMPORTANCE_HIGH
                "default" -> NotificationManager.IMPORTANCE_DEFAULT
                "low" -> NotificationManager.IMPORTANCE_LOW
                else -> NotificationManager.IMPORTANCE_HIGH
            }
            val enableVibration = arguments["enableVibration"] as Boolean
            val enableSound = arguments["enableSound"] as Boolean
            val enableLights = arguments["enableLights"] as Boolean
            val lightColor = arguments["lightColor"] as String

            val channel = NotificationChannel(channelId, channelName, importance).apply {
                description = channelDescription
                enableVibration(enableVibration)
                setShowBadge(true)
                if (enableLights) {
                    setLightColor(android.graphics.Color.parseColor(lightColor))
                    enableLights(true)
                }
                if (!enableSound) {
                    setSound(null, null)
                }
            }

            val notificationManager = getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager
            notificationManager.createNotificationChannel(channel)
        }
    }
}
