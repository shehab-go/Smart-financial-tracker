package com.shehabgo.smartfinancialtracker.ui.screens.dashboard

import androidx.compose.animation.core.*
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.financial.tracker.module.data.FinancialTransaction
import com.shehabgo.smartfinancialtracker.ui.utils.CategoryMapper
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UnifiedDashboardScreen(
    viewModel: DashboardViewModel = viewModel(),
    onNavigateToLedger: () -> Unit = {},
    onNavigateToAdmin: () -> Unit = {}
) {
    val transactions by viewModel.transactions.collectAsStateWithLifecycle()

    val totalIncome = transactions.filter { it.transactionType == "TransferIn" }.sumOf { it.amount }
    val totalExpense = transactions.filter { it.transactionType == "Payment" || it.transactionType == "TransferOut" }.sumOf { it.amount }
    val balance = totalIncome - totalExpense

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Text(
                        text = "CapitalCore",
                        style = MaterialTheme.typography.headlineMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.primary
                    )
                },
                navigationIcon = {
                    Row(
                        modifier = Modifier.padding(start = 20.dp, end = 8.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .border(2.dp, MaterialTheme.colorScheme.primaryContainer, CircleShape)
                                .clip(CircleShape)
                                .background(MaterialTheme.colorScheme.surfaceVariant),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Rounded.Person,
                                contentDescription = "Profile",
                                tint = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                        }
                        Text(
                            text = "مرحباً، سامي",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.secondary
                        )
                    }
                },
                actions = {
                    IconButton(
                        onClick = { /*TODO*/ },
                        modifier = Modifier.padding(end = 12.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.Notifications,
                            contentDescription = "Notifications",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = Color.White.copy(alpha = 0.9f)
                ),
                modifier = Modifier.shadow(1.dp)
            )
        },
        bottomBar = {
            BottomNavigationBar(
                onNavigateToLedger = onNavigateToLedger,
                onNavigateToAdmin = onNavigateToAdmin
            )
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
        ) {
            Spacer(modifier = Modifier.height(24.dp))

            // Dashboard Header
            Column(modifier = Modifier.padding(horizontal = 20.dp)) {
                Text(
                    text = "لوحة التحكم الذكية",
                    style = MaterialTheme.typography.headlineLarge,
                    color = MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.Bold
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(
                        imageVector = Icons.Rounded.Sync,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.secondary
                    )
                    Text(
                        text = "تحديث مباشر بدون سحب",
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.secondary
                    )
                }
            }

            Spacer(modifier = Modifier.height(32.dp))

            // Horizontal Wallet Carousel
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .horizontalScroll(rememberScrollState())
                    .padding(start = 20.dp, end = 20.dp, bottom = 16.dp),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Card 1: Vibrant Red
                WalletCardItem(
                    title = "رصيد جيب التلقائي",
                    amount = balance, // Mocking with balance
                    icon = Icons.Rounded.AccountBalanceWallet,
                    badgeText = "تلقائي",
                    isPrimary = true
                )
                
                // Card 2: Clean White
                WalletCardItem(
                    title = "رصيد الكاش اليدوي",
                    amount = 12500.0,
                    icon = Icons.Rounded.Payments,
                    badgeText = "يدوي",
                    isPrimary = false
                )
                
                // Card 3: Light Surface
                WalletCardItem(
                    title = "الرؤية الموحدة - الإجمالي",
                    amount = balance + 12500.0,
                    icon = Icons.Rounded.AccountBalance,
                    badgeText = "شامل",
                    isPrimary = false,
                    isSurface = true
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Reactive Analytics Section
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 20.dp)
                    .shadow(4.dp, RoundedCornerShape(24.dp), spotColor = Color.Black.copy(alpha = 0.05f))
                    .background(Color.White, RoundedCornerShape(24.dp))
                    .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(24.dp))
                    .padding(24.dp)
            ) {
                Column {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "تحليل المصروفات",
                            style = MaterialTheme.typography.headlineMedium.copy(fontSize = 20.dp.value.sp),
                            color = MaterialTheme.colorScheme.onSurface,
                            fontWeight = FontWeight.Bold
                        )
                        Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Box(modifier = Modifier
                                .size(12.dp)
                                .shadow(4.dp, CircleShape, spotColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.3f))
                                .background(MaterialTheme.colorScheme.primary, CircleShape))
                            Box(modifier = Modifier
                                .size(12.dp)
                                .background(MaterialTheme.colorScheme.secondary, CircleShape))
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    // Mock Chart
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(192.dp),
                        verticalAlignment = Alignment.Bottom,
                        horizontalArrangement = Arrangement.spacedBy(8.dp)
                    ) {
                        ChartBar(heightFraction = 0.4f, color = MaterialTheme.colorScheme.surfaceVariant, label = "15%")
                        ChartBar(heightFraction = 0.65f, color = MaterialTheme.colorScheme.secondary.copy(alpha = 0.3f), label = "28%")
                        ChartBar(heightFraction = 0.85f, color = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f), label = "42%", hasDot = true)
                        ChartBar(heightFraction = 0.3f, color = MaterialTheme.colorScheme.tertiary.copy(alpha = 0.2f), label = "12%")
                        ChartBar(heightFraction = 0.5f, color = MaterialTheme.colorScheme.primaryContainer, label = "22%")
                    }

                    Spacer(modifier = Modifier.height(24.dp))

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            val infiniteTransition = rememberInfiniteTransition()
                            val alpha by infiniteTransition.animateFloat(
                                initialValue = 0.3f,
                                targetValue = 1f,
                                animationSpec = infiniteRepeatable(
                                    animation = tween(1000),
                                    repeatMode = RepeatMode.Reverse
                                )
                            )
                            Box(modifier = Modifier
                                .size(8.dp)
                                .background(MaterialTheme.colorScheme.error.copy(alpha = alpha), CircleShape))
                            Text(
                                text = "تنبيه: إنفاق عالي (تعليم)",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                fontWeight = FontWeight.Medium
                            )
                        }
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            Box(modifier = Modifier
                                .size(8.dp)
                                .background(MaterialTheme.colorScheme.secondary, CircleShape))
                            Text(
                                text = "نمو الدخل: +12%",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.onSurfaceVariant,
                                fontWeight = FontWeight.Medium
                            )
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(40.dp))

            // Transaction Feed
            Column(modifier = Modifier.padding(horizontal = 20.dp)) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        text = "آخر المعاملات",
                        style = MaterialTheme.typography.headlineMedium.copy(fontSize = 20.dp.value.sp),
                        color = MaterialTheme.colorScheme.onSurface,
                        fontWeight = FontWeight.Bold
                    )
                    TextButton(onClick = { /*TODO*/ }) {
                        Text(
                            text = "عرض الكل",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                if (transactions.isEmpty()) {
                    Text(
                        text = "لا توجد عمليات مسجلة حتى الآن. التطبيق في وضع الاستماع الصامت...",
                        style = MaterialTheme.typography.bodyMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.padding(24.dp)
                    )
                } else {
                    transactions.take(5).forEach { transaction ->
                        TransactionItemRow(transaction)
                        Spacer(modifier = Modifier.height(16.dp))
                    }
                }
            }
            
            Spacer(modifier = Modifier.height(80.dp))
        }
    }
}

@Composable
fun WalletCardItem(
    title: String,
    amount: Double,
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    badgeText: String,
    isPrimary: Boolean,
    isSurface: Boolean = false
) {
    val infiniteTransition = rememberInfiniteTransition()
    val scale by infiniteTransition.animateFloat(
        initialValue = 1f,
        targetValue = 1.02f,
        animationSpec = infiniteRepeatable(
            animation = tween(2000),
            repeatMode = RepeatMode.Reverse
        )
    )

    val modifier = if (isPrimary) {
        Modifier
            .width(320.dp)
            .shadow(25.dp, RoundedCornerShape(16.dp), spotColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f))
            .background(
                Brush.linearGradient(
                    colors = listOf(
                        MaterialTheme.colorScheme.primary,
                        Color(0xFFE61D2B) // Hardcoded red from CSS
                    )
                ),
                RoundedCornerShape(16.dp)
            )
            .border(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.1f), RoundedCornerShape(16.dp))
    } else if (isSurface) {
        Modifier
            .width(320.dp)
            .shadow(4.dp, RoundedCornerShape(16.dp), spotColor = Color.Black.copy(alpha = 0.03f))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f), RoundedCornerShape(16.dp))
            .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(16.dp))
    } else {
        Modifier
            .width(320.dp)
            .shadow(4.dp, RoundedCornerShape(16.dp), spotColor = Color.Black.copy(alpha = 0.03f))
            .background(Color.White, RoundedCornerShape(16.dp))
            .border(1.dp, MaterialTheme.colorScheme.primaryContainer, RoundedCornerShape(16.dp))
    }

    Box(
        modifier = modifier.padding(24.dp)
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Top
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = if (isPrimary) Color.White else if (isSurface) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.primary,
                    modifier = Modifier.size(36.dp)
                )
                Box(
                    modifier = Modifier
                        .background(
                            if (isPrimary) Color.White.copy(alpha = 0.2f) else MaterialTheme.colorScheme.surfaceVariant,
                            RoundedCornerShape(16.dp)
                        )
                        .padding(horizontal = 12.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = badgeText,
                        style = MaterialTheme.typography.labelLarge,
                        color = if (isPrimary) Color.White else MaterialTheme.colorScheme.secondary
                    )
                }
            }

            Spacer(modifier = Modifier.height(40.dp))

            Text(
                text = title,
                style = MaterialTheme.typography.labelLarge,
                color = if (isPrimary) Color.White.copy(alpha = 0.8f) else MaterialTheme.colorScheme.secondary
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                Text(
                    text = String.format("%,.0f", amount),
                    style = MaterialTheme.typography.headlineLarge,
                    color = if (isPrimary) Color.White else MaterialTheme.colorScheme.onSurface,
                    fontWeight = FontWeight.Bold
                )
                Text(
                    text = "ر.ي",
                    style = MaterialTheme.typography.labelLarge,
                    color = if (isPrimary) Color.White.copy(alpha = 0.6f) else MaterialTheme.colorScheme.outline
                )
            }
        }
    }
}

@Composable
fun RowScope.ChartBar(heightFraction: Float, color: Color, label: String, hasDot: Boolean = false) {
    Box(
        modifier = Modifier
            .weight(1f)
            .fillMaxHeight(heightFraction)
            .background(color, RoundedCornerShape(topStart = 8.dp, topEnd = 8.dp)),
        contentAlignment = Alignment.TopCenter
    ) {
        if (hasDot) {
            Box(
                modifier = Modifier
                    .offset(y = (-4).dp)
                    .size(8.dp)
                    .shadow(8.dp, CircleShape, spotColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f))
                    .background(MaterialTheme.colorScheme.primary, CircleShape)
            )
        }
    }
}

@Composable
fun TransactionItemRow(transaction: FinancialTransaction) {
    val isIncome = transaction.transactionType == "TransferIn"
    val amountPrefix = if (isIncome) "+" else "-"
    val amountColor = if (isIncome) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.error
    val borderColor = if (isIncome) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.error
    
    val style = CategoryMapper.getStyleForCounterpart(transaction.counterpart)
    val iconBgColor = if (isIncome) MaterialTheme.colorScheme.secondaryContainer else MaterialTheme.colorScheme.errorContainer
    val iconColor = if (isIncome) MaterialTheme.colorScheme.secondary else MaterialTheme.colorScheme.error

    val formatter = SimpleDateFormat("MMM dd, HH:mm", Locale.getDefault())
    val dateString = formatter.format(Date(transaction.timestamp))

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(2.dp, RoundedCornerShape(16.dp), spotColor = Color.Black.copy(alpha = 0.05f))
            .background(Color.White, RoundedCornerShape(16.dp))
            .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(16.dp))
            .clickable { /*TODO*/ }
    ) {
        // Colored right border
        Box(
            modifier = Modifier
                .align(Alignment.CenterEnd)
                .width(4.dp)
                .fillMaxHeight()
                .background(borderColor, RoundedCornerShape(topEnd = 16.dp, bottomEnd = 16.dp))
        )
        
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Box(
                    modifier = Modifier
                        .size(48.dp)
                        .background(iconBgColor, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = style.icon,
                        contentDescription = null,
                        tint = iconColor,
                        modifier = Modifier.size(24.dp)
                    )
                }
                Column {
                    Text(
                        text = transaction.counterpart,
                        style = MaterialTheme.typography.bodyMedium,
                        fontWeight = FontWeight.Bold,
                        color = MaterialTheme.colorScheme.onSurface
                    )
                    Text(
                        text = transaction.packageName,
                        style = MaterialTheme.typography.labelSmall,
                        color = MaterialTheme.colorScheme.outline
                    )
                }
            }
            Column(horizontalAlignment = Alignment.Start) {
                Text(
                    text = "$amountPrefix ${String.format("%,.0f", transaction.amount)}",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Bold,
                    color = amountColor
                )
                Text(
                    text = dateString,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.outline
                )
            }
        }
    }
}

@Composable
fun BottomNavigationBar(
    onNavigateToLedger: () -> Unit,
    onNavigateToAdmin: () -> Unit
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(20.dp, RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp), spotColor = Color.Black.copy(alpha = 0.05f))
            .background(Color.White.copy(alpha = 0.95f), RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
            .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(topStart = 16.dp, topEnd = 16.dp))
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 8.dp)
                .height(64.dp),
            horizontalArrangement = Arrangement.SpaceAround,
            verticalAlignment = Alignment.CenterVertically
        ) {
            BottomNavItem(
                icon = Icons.Rounded.Dashboard,
                label = "Dashboard",
                isSelected = true,
                onClick = { }
            )
            BottomNavItem(
                icon = Icons.Rounded.AccountBalanceWallet,
                label = "Wallets",
                isSelected = false,
                onClick = { }
            )
            BottomNavItem(
                icon = Icons.Rounded.AccountBalance,
                label = "Ledger",
                isSelected = false,
                onClick = onNavigateToLedger
            )
            BottomNavItem(
                icon = Icons.Rounded.AdminPanelSettings,
                label = "Admin",
                isSelected = false,
                onClick = onNavigateToAdmin
            )
        }
    }
}

@Composable
fun BottomNavItem(
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    label: String,
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val contentColor = if (isSelected) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.secondary
    val bgColor = if (isSelected) MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f) else Color.Transparent

    Column(
        modifier = Modifier
            .clip(RoundedCornerShape(24.dp))
            .background(bgColor)
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 4.dp),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            imageVector = icon,
            contentDescription = label,
            tint = contentColor,
            modifier = Modifier.size(24.dp)
        )
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = contentColor,
            fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Normal
        )
    }
}
