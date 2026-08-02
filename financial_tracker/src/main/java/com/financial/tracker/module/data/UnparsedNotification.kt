package com.financial.tracker.module.data

/**
 * Represents a notification that was received from a targeted wallet/bank application,
 * but could not be successfully parsed by the regex rules.
 */
data class UnparsedNotification(
    val id: Int = 0,
    val packageName: String,
    val title: String,
    val text: String,
    val timestamp: Long,
)
