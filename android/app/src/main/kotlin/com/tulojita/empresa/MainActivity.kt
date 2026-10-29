package com.tulojita.empresa

import android.content.Intent
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        if (!isTaskRoot && intent.hasCategory(Intent.CATEGORY_LAUNCHER) && Intent.ACTION_MAIN.equals(intent.action)) {
            finish()
            return
        }
        super.onCreate(savedInstanceState)
        
        // Configurar User-Agent personalizado para WebView
        System.setProperty("http.agent", "TuLojitaBusiness/1.0")
    }
}
