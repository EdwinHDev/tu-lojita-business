package com.tulojita.empresa

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    private fun hasNotificationExtras(intent: Intent?): Boolean {
        if (intent == null) return false
        if (intent.action == "FLUTTER_NOTIFICATION_CLICK") return true
        val extras = intent.extras ?: return false
        val notificationKeys = listOf(
            "google.message_id",
            "gcm.message_id",
            "message_id",
            "from",
            "notificationId",
            "payload",
            "type",
            "orderId",
            "targetId",
            "storeId"
        )
        return notificationKeys.any { key -> extras.containsKey(key) }
    }

    override fun onCreate(savedInstanceState: Bundle?) {
        if (!isTaskRoot &&
            intent.hasCategory(Intent.CATEGORY_LAUNCHER) &&
            Intent.ACTION_MAIN == intent.action &&
            !hasNotificationExtras(intent)
        ) {
            finish()
            return
        }
        super.onCreate(savedInstanceState)

        // Configurar User-Agent personalizado para WebView
        System.setProperty("http.agent", "TuLojitaBusiness/1.0")
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
    }
}
