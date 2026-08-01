package com.shehabgo.smartfinancialtracker

import android.app.Application
import com.financial.tracker.module.config.WalletConfigManager

class SmartFinancialApp : Application() {
    override fun onCreate() {
        super.onCreate()
        // تهيئة محرك الإشعارات وقواعد المحافظ فور تشغيل التطبيق
        WalletConfigManager.init(this)
    }
}
