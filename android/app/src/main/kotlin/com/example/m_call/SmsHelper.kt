package com.example.m_call

import android.content.Context
import android.os.Build
import android.telephony.SmsManager
import android.util.Log

object SmsHelper {
    private const val TAG = "MCall_SmsHelper"

    fun sendSms(context: Context, phoneNumber: String, message: String): Boolean {
        if (phoneNumber.isBlank() || phoneNumber.equals("Unknown", ignoreCase = true) || phoneNumber.equals("null", ignoreCase = true)) {
            Log.w(TAG, "Cannot send SMS: invalid phone number '$phoneNumber'")
            return false
        }

        return try {
            val smsManager: SmsManager = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.S) {
                try {
                    context.getSystemService(SmsManager::class.java) ?: @Suppress("DEPRECATION") SmsManager.getDefault()
                } catch (e: Exception) {
                    @Suppress("DEPRECATION")
                    SmsManager.getDefault()
                }
            } else {
                @Suppress("DEPRECATION")
                SmsManager.getDefault()
            }

            val parts = smsManager.divideMessage(message)
            if (parts.size > 1) {
                smsManager.sendMultipartTextMessage(phoneNumber, null, parts, null, null)
            } else {
                smsManager.sendTextMessage(phoneNumber, null, message, null, null)
            }
            Log.i(TAG, "Successfully dispatched SMS to $phoneNumber (${parts.size} part(s))")
            true
        } catch (e: Exception) {
            Log.e(TAG, "Error sending SMS to $phoneNumber: ${e.message}", e)
            false
        }
    }
}

