package com.housestudio.oflite

import android.content.pm.ActivityInfo
import android.os.Bundle
import io.flutter.embedding.android.FlutterActivity

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Tablet (menor lateral >= 600dp) abre sempre deitado, já na primeira
        // tela, sem piscar em retrato. Celular não muda.
        if (resources.configuration.smallestScreenWidthDp >= 600) {
            requestedOrientation = ActivityInfo.SCREEN_ORIENTATION_SENSOR_LANDSCAPE
        }
        super.onCreate(savedInstanceState)
    }
}
