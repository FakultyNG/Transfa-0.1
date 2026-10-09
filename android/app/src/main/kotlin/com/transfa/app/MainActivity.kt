package com.transfa.app

import android.content.Intent
import android.provider.Settings
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity: FlutterFragmentActivity() {
    private val CHANNEL_WIFI = "app.settings/wifi"
    private val CHANNEL_CELLULAR = "app.settings/cellular"

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_WIFI)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openWifiSettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_WIFI_SETTINGS))
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", "Cannot open Wi-Fi settings", e.message)
                        }
                    }
                    else -> result.notImplemented()
                }
            }

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, CHANNEL_CELLULAR)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openCellularSettings" -> {
                        try {
                            startActivity(Intent(Settings.ACTION_DATA_ROAMING_SETTINGS))
                            result.success(null)
                        } catch (e: Exception) {
                            result.error("UNAVAILABLE", "Cannot open Cellular settings", e.message)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }
}
