package com.shehabgo.smartfinancialtracker.ui.screens.admin

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.financial.tracker.module.FinancialTrackerClient
import com.financial.tracker.module.data.UnparsedNotification
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class UnparsedLogsViewModel : ViewModel() {
    private val _logs = MutableStateFlow<List<UnparsedNotification>>(emptyList())
    val logs: StateFlow<List<UnparsedNotification>> = _logs

    private val _isReprocessing = MutableStateFlow(false)
    val isReprocessing: StateFlow<Boolean> = _isReprocessing

    fun loadLogs(context: Context) {
        viewModelScope.launch {
            _logs.value = FinancialTrackerClient.getUnparsedLogs(context)
        }
    }

    fun reprocessLogs(context: Context, onComplete: () -> Unit) {
        if (_isReprocessing.value) return
        viewModelScope.launch {
            _isReprocessing.value = true
            // إعادة معالجة السجلات عبر محرك التتبع
            FinancialTrackerClient.reprocessUnparsedLogs(context)
            // تحديث السجلات بعد المعالجة
            loadLogs(context)
            _isReprocessing.value = false
            onComplete()
        }
    }
}
