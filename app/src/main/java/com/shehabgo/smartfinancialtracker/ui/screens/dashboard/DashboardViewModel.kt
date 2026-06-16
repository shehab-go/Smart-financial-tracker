package com.shehabgo.smartfinancialtracker.ui.screens.dashboard

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.financial.tracker.module.FinancialTrackerClient
import com.financial.tracker.module.data.FinancialTransaction
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch

class DashboardViewModel(application: Application) : AndroidViewModel(application) {
    
    private val _transactions = MutableStateFlow<List<FinancialTransaction>>(emptyList())
    val transactions: StateFlow<List<FinancialTransaction>> = _transactions.asStateFlow()

    init {
        viewModelScope.launch {
            // Load initial transactions from the database
            _transactions.value = FinancialTrackerClient.getAllTransactions(application)
            
            // Listen for incoming real-time transactions and prepend them to the list
            FinancialTrackerClient.transactionFlow.collect { newTx ->
                val currentList = _transactions.value.toMutableList()
                val existingIndex = currentList.indexOfFirst { it.referenceId == newTx.referenceId }
                if (existingIndex >= 0) {
                    currentList[existingIndex] = newTx
                } else {
                    currentList.add(0, newTx)
                }
                _transactions.value = currentList
            }
        }
    }

    fun classifyTransaction(context: android.content.Context, tx: FinancialTransaction, isDebt: Boolean, category: String? = null) {
        viewModelScope.launch {
            val updated = tx.copy(isClassified = true, isDebt = isDebt, category = category)
            FinancialTrackerClient.updateTransaction(context, updated)
            _transactions.value = FinancialTrackerClient.getAllTransactions(context)
        }
    }
}
