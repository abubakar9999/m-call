package com.example.m_call

import android.Manifest
import android.content.BroadcastReceiver
import android.content.ContentValues
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.database.Cursor
import android.database.sqlite.SQLiteDatabase
import android.net.Uri
import android.os.Build
import android.provider.CallLog
import android.provider.ContactsContract
import android.telecom.TelecomManager
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.app.ActivityCompat
import java.io.File
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class CallReceiver : BroadcastReceiver() {

    companion object {
        private const val TAG = "MCall_CallReceiver"
        private var lastCallNumber: String? = null
        private var lastCallTimestamp: Long = 0L
    }

    override fun onReceive(context: Context, intent: Intent?) {
        if (intent == null || intent.action != TelephonyManager.ACTION_PHONE_STATE_CHANGED) {
            return
        }

        val state = intent.getStringExtra(TelephonyManager.EXTRA_STATE)
        Log.d(TAG, "Phone state changed: $state")

        if (state == TelephonyManager.EXTRA_STATE_RINGING) {
            handleIncomingCall(context, intent)
        }
    }

    private fun handleIncomingCall(context: Context, intent: Intent) {
        val prefs = context.getSharedPreferences("mcall_native_prefs", Context.MODE_PRIVATE)
        val isActive = prefs.getBoolean("is_active", false)
        val endTime = prefs.getLong("end_time_millis", 0L)
        val replyToPhone = prefs.getBoolean("reply_to_phone", true)
        val modeName = prefs.getString("mode_name", "Busy") ?: "Busy"
        val messageTemplate = prefs.getString(
            "message_template",
            "Assalamualaikum, {time} minute wait koren. Ami {mode_name} e achi."
        ) ?: "Assalamualaikum, {time} minute wait koren. Ami {mode_name} e achi."

        val now = System.currentTimeMillis()

        if (!isActive || now >= endTime || !replyToPhone) {
            Log.d(TAG, "Mode inactive or expired (active: $isActive, now: $now, end: $endTime)")
            return
        }

        // Retrieve caller phone number
        var incomingNumber = intent.getStringExtra(TelephonyManager.EXTRA_INCOMING_NUMBER)
        if (incomingNumber.isNullOrBlank()) {
            incomingNumber = getLatestCallLogNumber(context)
        }

        if (incomingNumber.isNullOrBlank() || incomingNumber.equals("Unknown", ignoreCase = true)) {
            Log.w(TAG, "Cannot determine incoming phone number")
            return
        }

        // Debounce: ignore repeated rings for the same call within 10 seconds
        if (incomingNumber == lastCallNumber && (now - lastCallTimestamp) < 10000L) {
            Log.d(TAG, "Ignoring duplicate ringing event for $incomingNumber")
            return
        }
        lastCallNumber = incomingNumber
        lastCallTimestamp = now

        Log.i(TAG, "Detected incoming call from: $incomingNumber during mode: $modeName")

        // 1. End / Reject the call automatically
        rejectCall(context)

        // 2. Prepare auto-reply message
        val remainingMinutes = maxOf(1, ((endTime - now) / 60000).toInt())
        val replyMessage = messageTemplate
            .replace("{time}", remainingMinutes.toString())
            .replace("{mode_name}", modeName)

        // 3. Send SMS
        val smsSuccess = SmsHelper.sendSms(context, incomingNumber, replyMessage)

        // 4. Resolve contact name
        val callerName = getContactName(context, incomingNumber)

        // 5. Notify Flutter if foreground engine is running
        MainActivity.instance?.notifyCallEvent(incomingNumber, callerName, "phone")

        // 6. Write directly to SQLite database
        saveCallLogToDb(context, incomingNumber, callerName, modeName, replyMessage, smsSuccess)
    }

    private fun rejectCall(context: Context) {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.P) {
            if (ActivityCompat.checkSelfPermission(context, Manifest.permission.ANSWER_PHONE_CALLS) == PackageManager.PERMISSION_GRANTED) {
                try {
                    val telecom = context.getSystemService(Context.TELECOM_SERVICE) as? TelecomManager
                    telecom?.endCall()
                    Log.i(TAG, "Call rejected successfully via TelecomManager")
                } catch (e: Exception) {
                    Log.e(TAG, "Failed to end call: ${e.message}")
                }
            }
        }
    }

    private fun getLatestCallLogNumber(context: Context): String? {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.READ_CALL_LOG) != PackageManager.PERMISSION_GRANTED) {
            return null
        }
        return try {
            val cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                arrayOf(CallLog.Calls.NUMBER),
                null,
                null,
                "${CallLog.Calls.DATE} DESC LIMIT 1"
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val idx = it.getColumnIndex(CallLog.Calls.NUMBER)
                    if (idx != -1) it.getString(idx) else null
                } else null
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun getContactName(context: Context, phoneNumber: String): String? {
        if (ActivityCompat.checkSelfPermission(context, Manifest.permission.READ_CONTACTS) != PackageManager.PERMISSION_GRANTED) {
            return null
        }
        val uri = Uri.withAppendedPath(
            ContactsContract.PhoneLookup.CONTENT_FILTER_URI,
            Uri.encode(phoneNumber)
        )
        return try {
            val cursor = context.contentResolver.query(
                uri,
                arrayOf(ContactsContract.PhoneLookup.DISPLAY_NAME),
                null,
                null,
                null
            )
            cursor?.use {
                if (it.moveToFirst()) {
                    val idx = it.getColumnIndex(ContactsContract.PhoneLookup.DISPLAY_NAME)
                    if (idx != -1) it.getString(idx) else null
                } else null
            }
        } catch (e: Exception) {
            null
        }
    }

    private fun saveCallLogToDb(
        context: Context,
        phoneNumber: String,
        callerName: String?,
        modeName: String,
        message: String,
        sent: Boolean
    ) {
        try {
            val dbFile = context.getDatabasePath("mcall.db")
            if (!dbFile.exists()) return

            val db = SQLiteDatabase.openDatabase(dbFile.absolutePath, null, SQLiteDatabase.OPEN_READWRITE)
            val values = ContentValues().apply {
                put("id", System.currentTimeMillis().toString())
                put("caller_number", phoneNumber)
                put("caller_name", callerName)
                put("platform", "phone")
                put("message_sent", if (sent) message else "")
                put("mode_name", modeName)
                put("timestamp", SimpleDateFormat("yyyy-MM-dd'T'HH:mm:ss'Z'", Locale.US).format(Date()))
            }
            db.insert("call_logs", null, values)
            db.close()
            Log.d(TAG, "Call log saved to SQLite directly")
        } catch (e: Exception) {
            Log.w(TAG, "Could not save log directly to db: ${e.message}")
        }
    }
}

