package com.shehabgo.sample

import android.app.Application
import io.sentry.android.core.SentryAndroid

class SampleApplication : Application() {
    override fun onCreate() {
        super.onCreate()

        // Initialize Sentry to capture unparsed notifications for improvement
        SentryAndroid.init(this) { options ->
            options.dsn = "https://825bd75a2711db4379e998e626e71291@o4511440783933440.ingest.de.sentry.io/4511922524979280"
            // Set tracesSampleRate to 1.0 to capture 100% of transactions for performance monitoring.
            // We recommend adjusting this value in production.
            options.tracesSampleRate = 1.0
            options.isEnableUserInteractionTracing = true
        }
    }
}
