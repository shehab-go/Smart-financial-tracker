package com.shehabgo.smartfinancialtracker.ui.screens.transactions

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.ArrowForward
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.shehabgo.smartfinancialtracker.ui.screens.dashboard.DashboardViewModel
import com.shehabgo.smartfinancialtracker.ui.screens.dashboard.TransactionItemRow
import com.shehabgo.smartfinancialtracker.ui.theme.AppColors
import com.shehabgo.smartfinancialtracker.ui.theme.AppSpacing
import java.text.SimpleDateFormat
import java.util.*

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TransactionsHistoryScreen(
    onNavigateBack: () -> Unit,
    viewModel: DashboardViewModel = viewModel()
) {
    val transactions by viewModel.transactions.collectAsState()

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        "سجل المعاملات",
                        style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                        color = AppColors.TextPrimary
                    )
                },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.Rounded.ArrowForward, contentDescription = "Back", tint = AppColors.TextPrimary)
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color(0xFFF9FBFC)
                )
            )
        },
        containerColor = Color(0xFFF9FBFC)
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = AppSpacing.ScreenH)
        ) {
            val classifiedTransactions = transactions.filter { it.isClassified || (it.transactionType != "Transfer In" && it.transactionType != "Transfer Out") }
                .sortedByDescending { it.timestamp }
                
            if (classifiedTransactions.isEmpty()) {
                Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
                    Text(
                        text = "لا توجد معاملات مالية حتى الآن.",
                        style = MaterialTheme.typography.bodyMedium,
                        color = AppColors.TextSecondary
                    )
                }
            } else {
                val groupedTransactions = classifiedTransactions.groupBy { tx ->
                    val cal = Calendar.getInstance()
                    val today = cal.get(Calendar.DAY_OF_YEAR)
                    cal.timeInMillis = tx.timestamp
                    val txDay = cal.get(Calendar.DAY_OF_YEAR)
                    when (today - txDay) {
                        0 -> "اليوم"
                        1 -> "أمس"
                        else -> SimpleDateFormat("dd MMMM yyyy", Locale("ar")).format(Date(tx.timestamp))
                    }
                }

                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(top = 16.dp, bottom = 100.dp),
                    verticalArrangement = Arrangement.spacedBy(0.dp)
                ) {
                    groupedTransactions.forEach { (dateGroup, txList) ->
                        item {
                            Text(
                                text = dateGroup,
                                style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                                color = AppColors.TextSecondary,
                                modifier = Modifier.padding(top = 16.dp, bottom = 12.dp, start = 8.dp)
                            )
                        }
                        
                        items(txList.size) { index ->
                            val tx = txList[index]
                            val isIncome = tx.transactionType == "TransferIn" || tx.transactionType == "Transfer In"
                            val style = com.shehabgo.smartfinancialtracker.ui.utils.CategoryMapper.getEmojiAndColorForText(tx.category ?: tx.counterpart, isIncome)
                            val amountPrefix = if(isIncome) "+ " else "- "
                            
                            Row(modifier = Modifier.fillMaxWidth().height(IntrinsicSize.Min)) {
                                // Timeline Line & Dot
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    modifier = Modifier.width(48.dp).padding(end = 12.dp)
                                ) {
                                    // Top Line
                                    Box(modifier = Modifier.width(2.dp).weight(1f).background(if (index == 0) Color.Transparent else AppColors.Border))
                                    // Dot
                                    Box(
                                        modifier = Modifier.size(32.dp).background(style.containerColor, CircleShape).border(2.dp, Color.White, CircleShape),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Text(text = style.emoji, fontSize = 14.sp)
                                    }
                                    // Bottom Line
                                    Box(modifier = Modifier.width(2.dp).weight(1f).background(if (index == txList.size - 1) Color.Transparent else AppColors.Border))
                                }
                                
                                // Transaction Card
                                Box(modifier = Modifier.weight(1f).padding(bottom = 12.dp)) {
                                    TransactionItemRow(
                                        title = tx.counterpart.ifEmpty { "عملية مالية" },
                                        subtitle = if(isIncome) "إيراد - ${tx.category ?: "تلقائي"}" else "مصروف - ${tx.category ?: "تلقائي"}",
                                        amount = "$amountPrefix${String.format("%,.0f", tx.amount)}",
                                        timeLabel = SimpleDateFormat("HH:mm", Locale.US).format(Date(tx.timestamp)),
                                        isIncome = isIncome,
                                        emoji = "",
                                        iconBgColor = Color.Transparent,
                                        iconTint = Color.Transparent,
                                        accentColor = null,
                                        showIcon = false
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
