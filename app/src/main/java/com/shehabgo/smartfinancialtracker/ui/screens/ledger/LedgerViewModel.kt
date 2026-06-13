package com.shehabgo.smartfinancialtracker.ui.screens.ledger

import android.content.Context
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.financial.tracker.module.FinancialTrackerClient
import com.financial.tracker.module.data.FinancialTransaction
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch

class LedgerViewModel : ViewModel() {
    private val _transactions = MutableStateFlow<List<FinancialTransaction>>(emptyList())
    val transactions: StateFlow<List<FinancialTransaction>> = _transactions

    init {
        viewModelScope.launch {
            FinancialTrackerClient.transactionFlow.collect { newTx ->
                val updatedList = _transactions.value.toMutableList()
                val existingIndex = updatedList.indexOfFirst { it.referenceId == newTx.referenceId }
                if (existingIndex >= 0) {
                    updatedList[existingIndex] = newTx
                } else {
                    updatedList.add(0, newTx)
                }
                _transactions.value = updatedList
                recalculateTotals(updatedList)
            }
        }
    }

    private val _totalOwedToMe = MutableStateFlow(0.0)
    val totalOwedToMe: StateFlow<Double> = _totalOwedToMe

    private val _totalOwedByMe = MutableStateFlow(0.0)
    val totalOwedByMe: StateFlow<Double> = _totalOwedByMe

    private val _unclassifiedQueue = MutableStateFlow<List<FinancialTransaction>>(emptyList())
    val unclassifiedQueue: StateFlow<List<FinancialTransaction>> = _unclassifiedQueue

    fun loadTransactions(context: Context) {
        viewModelScope.launch {
            val all = FinancialTrackerClient.getAllTransactions(context)
            _transactions.value = all
            recalculateTotals(all)
        }
    }

    private fun recalculateTotals(all: List<FinancialTransaction>) {
        _totalOwedToMe.value = all.filter { it.isDebt && !it.isSettled && it.transactionType == "Transfer Out" }.sumOf { it.amount }
        _totalOwedByMe.value = all.filter { it.isDebt && !it.isSettled && it.transactionType == "Transfer In" }.sumOf { it.amount }

        val unclassifiedList = all.filter { 
            !it.isClassified && (it.transactionType == "Transfer In" || it.transactionType == "Transfer Out")
        }.sortedBy { it.timestamp }

        _unclassifiedQueue.value = unclassifiedList
    }

    fun classifyTransaction(context: Context, tx: FinancialTransaction, isDebt: Boolean, category: String? = null) {
        viewModelScope.launch {
            val updated = tx.copy(isClassified = true, isDebt = isDebt, category = category)
            FinancialTrackerClient.updateTransaction(context, updated)
            loadTransactions(context)
        }
    }

    fun settleTransaction(context: Context, tx: FinancialTransaction) {
        viewModelScope.launch {
            FinancialTrackerClient.markAsSettled(context, tx.referenceId)
            loadTransactions(context)
        }
    }
}
