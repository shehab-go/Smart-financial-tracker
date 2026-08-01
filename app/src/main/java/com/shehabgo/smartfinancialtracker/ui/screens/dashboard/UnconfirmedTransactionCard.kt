package com.shehabgo.smartfinancialtracker.ui.screens.dashboard

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.CallMade
import androidx.compose.material.icons.automirrored.rounded.CallReceived
import androidx.compose.material.icons.rounded.Close
import androidx.compose.material.icons.rounded.Handshake
import androidx.compose.material.icons.rounded.MoneyOff
import androidx.compose.material.icons.rounded.TipsAndUpdates
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.tween
import androidx.compose.animation.expandVertically
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.animation.shrinkVertically
import androidx.compose.animation.slideInVertically
import androidx.compose.animation.slideOutVertically
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import com.financial.tracker.module.data.FinancialTransaction
import com.shehabgo.smartfinancialtracker.ui.theme.AppColors
import com.shehabgo.smartfinancialtracker.ui.theme.AppShapes

@Composable
fun UnconfirmedTransactionCard(
    transaction: FinancialTransaction,
    onClassifyAsExpense: () -> Unit,
    onClassifyAsDebt: () -> Unit,
    onIgnore: () -> Unit
) {
    val isIncome = transaction.transactionType == "Transfer In" || transaction.transactionType == "TransferIn"
    
    val haptic = LocalHapticFeedback.current
    var visible by remember { mutableStateOf(false) }

    LaunchedEffect(transaction.id) {
        visible = true
        haptic.performHapticFeedback(HapticFeedbackType.LongPress)
    }

    AnimatedVisibility(
        visible = visible,
        enter = slideInVertically(
            initialOffsetY = { -40 },
            animationSpec = tween(500)
        ) + expandVertically() + fadeIn(),
        exit = slideOutVertically() + shrinkVertically() + fadeOut()
    ) {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(4.dp, AppShapes.Card, spotColor = AppColors.Warning.copy(alpha = 0.2f))
                .background(AppColors.Surface, AppShapes.Card)
                .border(1.dp, AppColors.Warning.copy(alpha = 0.3f), AppShapes.Card)
                .padding(16.dp)
        ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .background(AppColors.Warning.copy(alpha = 0.15f), CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.TipsAndUpdates,
                            contentDescription = null,
                            tint = AppColors.Warning,
                            modifier = Modifier.size(18.dp)
                        )
                    }
                    Column {
                        Text(
                            text = "عملية غير مؤكدة",
                            style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                            color = AppColors.Warning
                        )
                        Text(
                            text = if (isIncome) "حوالة واردة من ${transaction.counterpart}" else "حوالة صادرة إلى ${transaction.counterpart}",
                            style = MaterialTheme.typography.labelSmall,
                            color = AppColors.TextSecondary
                        )
                    }
                }
                Text(
                    text = "${transaction.amount} ر.ي",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = if (isIncome) AppColors.Success else AppColors.Primary
                )
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                Button(
                    onClick = onClassifyAsExpense,
                    modifier = Modifier.weight(1f).height(36.dp),
                    contentPadding = PaddingValues(0.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = if (isIncome) AppColors.Success.copy(alpha = 0.1f) else AppColors.Error.copy(alpha = 0.1f),
                        contentColor = if (isIncome) AppColors.Success else AppColors.Error
                    )
                ) {
                    Icon(
                        imageVector = if(isIncome) Icons.AutoMirrored.Rounded.CallReceived else Icons.Rounded.MoneyOff,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = if (isIncome) "إيراد" else "مصروف",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                
                Button(
                    onClick = onClassifyAsDebt,
                    modifier = Modifier.weight(1f).height(36.dp),
                    contentPadding = PaddingValues(0.dp),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = AppColors.PrimaryAlpha10,
                        contentColor = AppColors.Primary
                    )
                ) {
                    Icon(
                        imageVector = Icons.Rounded.Handshake,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp)
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "دين / سلف",
                        fontSize = 12.sp,
                        fontWeight = FontWeight.Bold
                    )
                }
                
                IconButton(
                    onClick = onIgnore,
                    modifier = Modifier
                        .size(36.dp)
                        .background(AppColors.SurfaceVariant, CircleShape)
                ) {
                    Icon(
                        imageVector = Icons.Rounded.Close,
                        contentDescription = "تجاهل",
                        tint = AppColors.TextHint,
                        modifier = Modifier.size(18.dp)
                    )
                }
            }
        }
    }
}
}

