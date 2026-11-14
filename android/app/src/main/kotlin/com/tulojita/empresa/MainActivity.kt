package com.tulojita.empresa

import android.content.ActivityNotFoundException
import android.content.Intent
import android.os.Bundle
import androidx.core.content.FileProvider
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel
import java.io.File

class MainActivity : FlutterActivity() {
    companion object {
        private const val PDF_OPENER_CHANNEL = "com.tulojita/pdf_opener"
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            PDF_OPENER_CHANNEL
        ).setMethodCallHandler { call, result ->
            if (call.method == "openPdf") {
                val path = call.argument<String>("path")
                result.success(openPdfFile(path))
            } else {
                result.notImplemented()
            }
        }
    }

    private fun openPdfFile(path: String?): Boolean {
        if (path.isNullOrBlank()) return false
        return try {
            val file = File(path)
            if (!file.exists() || !file.isFile) return false
            val authority = "${applicationContext.packageName}.pdfFileProvider"
            val uri = FileProvider.getUriForFile(this, authority, file)
            val viewIntent = Intent(Intent.ACTION_VIEW).apply {
                setDataAndType(uri, "application/pdf")
                addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
            }
            if (viewIntent.resolveActivity(packageManager) == null) {
                return false
            }
            startActivity(viewIntent)
            true
        } catch (_: ActivityNotFoundException) {
            false
        } catch (_: Exception) {
            false
        }
    }

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
