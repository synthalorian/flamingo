package com.synthclaw.flamingo

import android.app.NotificationChannel
import android.app.NotificationManager
import android.content.Context
import android.media.AudioAttributes
import android.media.Ringtone
import android.media.RingtoneManager
import android.media.MediaPlayer
import android.net.Uri
import android.os.BatteryManager
import android.os.Build
import android.provider.Settings
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    private val BATTERY_CHANNEL = "battery_thermometer/temp"
    private val TIMER_SOUND_CHANNEL = "timer_sound_player"

    private var _ringtone: Ringtone? = null
    private var _mediaPlayer: MediaPlayer? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        // ── Battery temperature ──────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BATTERY_CHANNEL)
            .setMethodCallHandler { call, result ->
                if (call.method == "getTemp") {
                    val temp = getBatteryTemperatureC()
                    if (temp != null) {
                        result.success((temp * 100).toInt())
                    } else {
                        result.error(
                            "unavailable",
                            "Battery temperature not supported on this device",
                            null
                        )
                    }
                } else {
                    result.notImplemented()
                }
            }

        // ── Timer sound player ──────────────────────────────────────
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, TIMER_SOUND_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "playAlarm"    -> {
                        stopCurrent()
                        _mediaPlayer = createPlayer(RingtoneManager.TYPE_ALARM)
                        _mediaPlayer?.start()
                        result.success(null)
                    }
                    "playNotif"    -> {
                        stopCurrent()
                        _mediaPlayer = createPlayer(RingtoneManager.TYPE_NOTIFICATION)
                        _mediaPlayer?.start()
                        result.success(null)
                    }
                    "stop"         -> {
                        stopCurrent()
                        result.success(null)
                    }
                    else           -> result.notImplemented()
                }
            }
    }

    private fun createPlayer(type: Int): MediaPlayer {
        val uri = RingtoneManager.getDefaultUri(type)
            ?: Settings.System.DEFAULT_NOTIFICATION_URI
        return MediaPlayer.create(this, uri)
    }

    private fun stopCurrent() {
        _ringtone?.stop()
        _ringtone = null
        _mediaPlayer?.release()
        _mediaPlayer = null
    }

    // ── Battery ─────────────────────────────────────────────────────
    private fun getBatteryTemperatureC(): Double? {
        return if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
            val bm = getSystemService(Context.BATTERY_SERVICE) as BatteryManager
            val tenths = bm.getIntProperty(BatteryManager.BATTERY_PROPERTY_TEMPERATURE)
            tenths.takeIf { it != Int.MIN_VALUE }?.toDouble()?.let { it / 10.0 }
        } else {
            null
        }
    }

    override fun onDestroy() {
        super.onDestroy()
        _ringtone?.stop()
        _mediaPlayer?.release()
        _mediaPlayer = null
    }
}
