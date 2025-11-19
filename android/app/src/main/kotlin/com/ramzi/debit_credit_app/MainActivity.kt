package com.ramzi.debit_credit_app

import android.os.Bundle
import androidx.activity.enableEdgeToEdge
import io.flutter.embedding.android.FlutterFragmentActivity

class MainActivity : FlutterFragmentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        // Configure system bars using AndroidX edge-to-edge helper for Android 15+ compatibility.
        enableEdgeToEdge()
        super.onCreate(savedInstanceState)
    }
}
