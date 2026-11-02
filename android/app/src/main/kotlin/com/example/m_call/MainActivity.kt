package com.example.m_call

import android.Manifest
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
import android.os.Build
import android.provider.ContactsContract
import android.telecom.TelecomManager
import android.telephony.PhoneStateListener
import android.telephony.TelephonyCallback
import android.telephony.TelephonyManager
import android.util.Log
import androidx.annotation.NonNull
import androidx.core.app.ActivityCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class MainActivity : FlutterActivity(), MethodChannel.MethodCallHandler, EventChannel.StreamHandler {

    private val METHOD_CHANNEL = "com.mcall.app/services"
    private val EVENT_CHANNEL = "com.mcall.app/events"
    private val TAG = "MCall_MainActivity"

    private var eventSink: EventChannel.EventSink? = null
    private var telephonyManager: TelephonyManager? = null

    companion object {
        var instance: MainActivity? = null
            private set
    }

    override fun configureFlutterEngine(@NonNull flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        instance = this

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler(this)

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(this)

        telephonyManager = getSystemService(Context.TELEPHONY_SERVICE) as? TelephonyManager
        setupCallListener()
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        val prefs = getSharedPreferences("mcall_native_prefs", Context.MODE_PRIVATE)

        when (call.method) {
            "startService" -> {
                result.success(true)
            }
            "stopService" -> {
                result.success(true)
            }
            "isServiceRunning" -> {
                val isActive = prefs.getBoolean("is_active", false)
                val endTime = prefs.getLong("end_time_millis", 0L)
                result.success(isActive && System.currentTimeMillis() < endTime)
            }
            "activateMode" -> {
                val modeName = call.argument<String>("modeName") ?: "Busy"
                val message = call.argument<String>("message") ?: "I am busy in {mode_name} right now."
                val durationMinutes = call.argument<Int>("durationMinutes") ?: 10
                val replyToPhone = call.argument<Boolean>("replyToPhone") ?: true
                val replyToWhatsApp = call.argument<Boolean>("replyToWhatsApp") ?: true
                val replyToMessenger = call.argument<Boolean>("replyToMessenger") ?: true

                prefs.edit()
                    .putBoolean("is_active", true)
                    .putString("mode_name", modeName)
                    .putString("message_template", message)
                    .putInt("duration_minutes", durationMinutes)
                    .putLong("end_time_millis", System.currentTimeMillis() + durationMinutes * 60 * 1000L)
                    .putBoolean("reply_to_phone", replyToPhone)
                    .putBoolean("reply_to_whatsapp", replyToWhatsApp)
                    .putBoolean("reply_to_messenger", replyToMessenger)
                    .apply()

                Log.i(TAG, "Mode activated on native: $modeName for $durationMinutes mins")
                result.success(true)
            }
            "deactivateMode" -> {
                prefs.edit().putBoolean("is_active", false).apply()
                Log.i(TAG, "Mode deactivated on native")
                result.success(true)
            }
            "sendSms" -> {
                val phoneNumber = call.argument<String>("phoneNumber")
                val message = call.argument<String>("message")

                if (phoneNumber.isNullOrEmpty() || message.isNullOrEmpty()) {
                    result.error("INVALID_ARGS", "Phone number and message are required", null)
                    return
                }

                val sent = SmsHelper.sendSms(this, phoneNumber, message)
                result.success(sent)
            }
            "canSendSms" -> {
                val hasPermission = ActivityCompat.checkSelfPermission(
                    this,
                    Manifest.permission.SEND_SMS
                ) == PackageManager.PERMISSION_GRANTED
                result.success(hasPermission)
            }
            "rejectCall" -> {
                val rejected = endCall()
                result.success(rejected)
            }
            "getContactName" -> {
                val phoneNumber = call.argument<String>("phoneNumber")
                val name = phoneNumber?.let { getContactNameFromNumber(it) }
                result.success(name)
            }
            "openNotificationSettings" -> {
                try {
                    val intent = Intent("android.settings.ACTION_NOTIFICATION_LISTENER_SETTINGS")
                    intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                    startActivity(intent)
                    result.success(true)
                } catch (e: Exception) {
                    result.success(false)
                }
            }
            else -> {
                result.notImplemented()
            }
        }
    }

    // ── Call Interception & Listener ──────────────────────────────────────────

    private fun setupCallListener() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_PHONE_STATE) == PackageManager.PERMISSION_GRANTED) {
                telephonyManager?.registerTelephonyCallback(
                    mainExecutor,
                    object : TelephonyCallback(), TelephonyCallback.CallStateListener {
                        override fun onCallStateChanged(state: Int) {
                            if (state == TelephonyManager.CALL_STATE_RINGING) {
                                val number = getLatestCallLogNumber() ?: "Unknown"
                                handleCallState(state, number)
                            }
                        }
                    }
                )
            }
        } else {
            @Suppress("DEPRECATION")
            telephonyManager?.listen(object : PhoneStateListener() {
                @Deprecated("Deprecated in Java")
                override fun onCallStateChanged(state: Int, incomingNumber: String?) {
                    handleCallState(state, incomingNumber)
                }
            }, PhoneStateListener.LISTEN_CALL_STATE)
        }
    }

    private fun handleCallState(state: Int, incomingNumber: String?) {
        val prefs = getSharedPreferences("mcall_native_prefs", Context.MODE_PRIVATE)
        val isActive = prefs.getBoolean("is_active", false)
        val endTime = prefs.getLong("end_time_millis", 0L)
        if (!isActive || System.currentTimeMillis() >= endTime) return

        if (state == TelephonyManager.CALL_STATE_RINGING) {
            val number = incomingNumber ?: getLatestCallLogNumber() ?: "Unknown"
            val contactName = getContactNameFromNumber(number)
            notifyCallEvent(number, contactName, "phone")
        }
    }

    private fun getLatestCallLogNumber(): String? {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
            return null
        }
        return try {
            val cursor = contentResolver.query(
                android.provider.CallLog.Calls.CONTENT_URI,
                arrayOf(android.provider.CallLog.Calls.NUMBER),
                null,
                null,
                "${android.provider.CallLog.Calls.DATE} DESC LIMIT 1"
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val idx = it.getColumnIndex(android.provider.CallLog.Calls.NUMBER)
                    if (idx != -1) it.getString(idx) else null
                } else null
            }
        } catch (e: Exception) {
            null
        }
    }

    fun notifyCallEvent(phoneNumber: String, callerName: String?, platform: String) {
        val dateFormat = SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US)
        val event = mapOf(
            "phoneNumber" to phoneNumber,
            "callerName" to callerName,
            "platform" to platform,
            "timestamp" to dateFormat.format(Date())
        )
        runOnUiThread {
            eventSink?.success(event)
        }
    }

    // ── Reject Incoming Call ──────────────────────────────────────────────────

    private fun endCall(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            val telecomManager = getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.ANSWER_PHONE_CALLS) == PackageManager.PERMISSION_GRANTED) {
                return try {
                    telecomManager?.endCall() ?: false
                } catch (e: Exception) {
                    false
                }
            }
        }
        return false
    }

    // ── Contacts Resolver ─────────────────────────────────────────────────────

    private fun getContactNameFromNumber(phoneNumber: String): String? {
        if (ActivityCompat.checkSelfPermission(this, Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            return null
        }

        val uri = Uri.withAppendedPath(
            ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
            Uri.encode(phoneNumber)
        )
        val projection = arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME)
        var cursor: Cursor? = null

        return try {
            cursor = contentResolver.query(uri, projection, null, null, null)
            if (cursor != null && cursor.moveToFirst()) {
                val index = cursor.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                if (index != -1) cursor.getString(index) else null
            } else null
        } catch (e: Exception) {
            null
        } finally {
            cursor?.close()
        }
    }

    // ── EventChannel.StreamHandler ────────────────────────────────────────────

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    override fun onDestroy() {
        instance = null
        super.onDestroy()
    }
}
