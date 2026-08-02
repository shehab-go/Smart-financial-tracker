package com.shehabgo.sample.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.financial.tracker.module.data.FinancialTransaction
import com.shehabgo.sample.simulator.MockTransactionSimulator
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DashboardScreen(
    transactions: List<FinancialTransaction>,
    onOpenSettings: () -> Unit,
) {
    val context = LocalContext.current
    var showSimulatorMenu by remember { mutableStateOf(false) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Smart Financial Tracker") },
                actions = {
                    IconButton(onClick = onOpenSettings) {
                        Icon(Icons.Default.Settings, contentDescription = "Settings")
                    }
                },
            )
        },
        floatingActionButton = {
            Box {
                FloatingActionButton(onClick = { showSimulatorMenu = true }) {
                    Icon(Icons.Default.Star, contentDescription = "Simulate")
                }
                DropdownMenu(
                    expanded = showSimulatorMenu,
                    onDismissRequest = { showSimulatorMenu = false },
                ) {
                    DropdownMenuItem(
                        text = { Text("Simulate STC Pay") },
                        onClick = {
                            MockTransactionSimulator.simulateSTCPay(context)
                            showSimulatorMenu = false
                        },
                    )
                    DropdownMenuItem(
                        text = { Text("Simulate mFloos") },
                        onClick = {
                            MockTransactionSimulator.simulateAlkuraimi(context)
                            showSimulatorMenu = false
                        },
                    )
                    DropdownMenuItem(
                        text = { Text("Simulate UrPay") },
                        onClick = {
                            MockTransactionSimulator.simulateUrPay(context)
                            showSimulatorMenu = false
                        },
                    )
                }
            }
        },
    ) { padding ->
        if (transactions.isEmpty()) {
            Box(
                modifier =
                    Modifier
                        .fillMaxSize()
                        .padding(padding),
                contentAlignment = Alignment.Center,
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(
                        Icons.Default.Notifications,
                        contentDescription = null,
                        modifier = Modifier.size(64.dp),
                        tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f),
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        "No transactions yet",
                        style = MaterialTheme.typography.bodyLarge,
                        color = Color.Gray,
                    )
                    Text(
                        "Try sending a transaction SMS to this device",
                        style = MaterialTheme.typography.bodySmall,
                        color = Color.Gray,
                    )
                }
            }
        } else {
            LazyColumn(
                modifier =
                    Modifier
                        .fillMaxSize()
                        .padding(padding),
                contentPadding = PaddingValues(16.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp),
            ) {
                items(transactions) { tx ->
                    TransactionItem(tx)
                }
            }
        }
    }
}

@Composable
fun TransactionItem(tx: FinancialTransaction) {
    val date =
        remember(tx.timestamp) {
            SimpleDateFormat("dd MMM yyyy, HH:mm", Locale.getDefault()).format(Date(tx.timestamp))
        }

    Card(
        modifier = Modifier.fillMaxWidth(),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp),
    ) {
        Row(
            modifier =
                Modifier
                    .padding(16.dp)
                    .fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically,
        ) {
            Column(modifier = Modifier.weight(1f)) {
                Text(
                    text = tx.counterpart,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold,
                )
                Text(
                    text = tx.transactionType,
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.secondary,
                )
                Text(
                    text = date,
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.Gray,
                )
            }
            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = "${tx.amount} ${tx.currency}",
                    style = MaterialTheme.typography.titleLarge,
                    color =
                        if (tx.transactionType.contains("Transfer", true) || tx.transactionType.contains("Purchase", true)) {
                            MaterialTheme.colorScheme.error
                        } else {
                            Color(0xFF4CAF50)
                        },
                    fontWeight = FontWeight.ExtraBold,
                )
                Text(
                    text = "Ref: ${tx.referenceId}",
                    style = MaterialTheme.typography.labelSmall,
                    fontSize = 10.sp,
                    color = Color.Gray,
                )
            }
        }
    }
}
