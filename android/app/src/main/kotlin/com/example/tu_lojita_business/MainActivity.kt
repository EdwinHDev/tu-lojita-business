package com.example.tu_lojita_business

import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        // Configurar User-Agent personalizado para WebView
        System.setProperty("http.agent", "TuLojitaBusiness/1.0")
    }
}
