package com.shehabgo.smartfinancialtracker.ui.utils

import android.content.Context
import com.financial.tracker.module.data.FinancialTransaction
import java.io.OutputStreamWriter
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

object ExportUtils {

    fun generateCSVContent(transactions: List<FinancialTransaction>): String {
        val builder = java.lang.StringBuilder()
        builder.append("ID,Type,Amount,Currency,Counterpart,Category,Date,IsClassified\n")
        
        val dateFormat = SimpleDateFormat("yyyy-MM-dd HH:mm:ss", Locale.US)
        
        for (tx in transactions) {
            val dateStr = dateFormat.format(Date(tx.timestamp))
            val safeCounterpart = tx.counterpart.replace("\"", "\"\"")
            val safeCategory = tx.category?.replace("\"", "\"\"") ?: "Uncategorized"
            builder.append("${tx.id},${tx.transactionType},${tx.amount},${tx.currency},\"$safeCounterpart\",\"$safeCategory\",\"$dateStr\",${tx.isClassified}\n")
        }
        
        return builder.toString()
    }

    fun saveCSVToUri(context: Context, uri: android.net.Uri, csvContent: String) {
        try {
            context.contentResolver.openOutputStream(uri)?.use { outputStream ->
                OutputStreamWriter(outputStream).use { writer ->
                    writer.write(csvContent)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
