package com.example.m_call

import android.app.Notification
import android.app.RemoteInput
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log

class MCallNotificationListenerService : NotificationListenerService() {

    private val TAG = "MCall_NotificationListener"

    override fun onNotificationPosted(sbn: StatusBarNotification?) {
        super.onNotificationPosted(sbn)
        if (sbn == null) return

        val packageName = sbn.packageName ?: return

        // Check if from WhatsApp or Messenger
        val isWhatsApp = packageName == "com.whatsapp"
        val isMessenger = packageName == "com.facebook.orca"

        if (!isWhatsApp && !isMessenger) return

        val prefs = getSharedPreferences("mcall_native_prefs", Context.MODE_PRIVATE)
        val isActive = prefs.getBoolean("is_active", false)
        val endTime = prefs.getLong("end_time_millis", 0L)
        val replyToWhatsApp = prefs.getBoolean("reply_to_whatsapp", true)
        val replyToMessenger = prefs.getBoolean("reply_to_messenger", true)
        val now = System.currentTimeMillis()

        if (!isActive || now >= endTime) return
        if (isWhatsApp && !replyToWhatsApp) return
        if (isMessenger && !replyToMessenger) return

        val notification = sbn.notification ?: return
        val extras = notification.extras ?: return

        val title = extras.getString(Notification.EXTRA_TITLE) ?: ""
        val text = extras.getCharSequence(Notification.EXTRA_TEXT)?.toString() ?: ""
        val category = notification.category

        // Detect if this is an incoming call or message during busy mode
        val isCall = category == Notification.CATEGORY_CALL ||
                title.contains("call", ignoreCase = true) ||
                text.contains("incoming call", ignoreCase = true) ||
                text.contains("calling", ignoreCase = true)

        if (isCall) {
            val platform = if (isWhatsApp) "whatsapp" else "messenger"
            Log.i(TAG, "Detected $platform call from $title")

            val modeName = prefs.getString("mode_name", "Busy") ?: "Busy"
            val template = prefs.getString(
                "message_template",
                "Assalamualaikum, {time} minute wait koren. Ami {mode_name} e achi."
            ) ?: "I am busy in {mode_name} right now."

            val remainingMin = maxOf(1, ((endTime - now) / 60000).toInt())
            val autoReplyMessage = template
                .replace("{time}", remainingMin.toString())
                .replace("{mode_name}", modeName)

            // Notify Flutter
            MainActivity.instance?.notifyCallEvent(title, title, platform)

            // Look for quick reply action to auto-respond
            val replied = replyToNotification(notification, autoReplyMessage)
            if (replied) {
                Log.i(TAG, "Sent notification auto-reply on $platform: $autoReplyMessage")
            }
        }
    }

    private fun replyToNotification(notification: Notification, message: String): Boolean {
        val actions = notification.actions ?: return false

        for (action in actions) {
            val remoteInputs = action.remoteInputs ?: continue
            for (remoteInput in remoteInputs) {
                val intent = Intent()
                val bundle = Bundle()
                bundle.putCharSequence(remoteInput.resultKey, message)
                RemoteInput.addResultsToIntent(remoteInputs, intent, bundle)

                try {
                    action.actionIntent.send(this, 0, intent)
                    return true
                } catch (e: Exception) {
                    Log.e(TAG, "Error sending reply to notification: ${e.message}")
                }
            }
        }
        return false
    }
}
