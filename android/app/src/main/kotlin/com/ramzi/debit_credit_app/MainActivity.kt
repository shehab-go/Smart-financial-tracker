package com.ramzi.debit_credit_app

import android.os.Bundle
import androidx.core.view.WindowCompat
import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        // Enable edge-to-edge by letting content draw behind system bars
        WindowCompat.setDecorFitsSystemWindows(window, false)
    }
}
