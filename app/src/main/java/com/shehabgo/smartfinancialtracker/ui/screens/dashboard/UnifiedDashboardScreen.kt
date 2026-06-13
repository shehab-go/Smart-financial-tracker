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
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.financial.tracker.module.data.FinancialTransaction
import com.shehabgo.smartfinancialtracker.ui.theme.AppColors
import com.shehabgo.smartfinancialtracker.ui.theme.AppShapes
import com.shehabgo.smartfinancialtracker.ui.theme.AppSpacing
import com.shehabgo.smartfinancialtracker.ui.theme.AppElevation
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

    // Calculate totals based on actual transaction data
    val totalIncome = transactions.filter { it.transactionType == "TransferIn" }.sumOf { it.amount }
    val totalExpense = transactions.filter { it.transactionType == "Payment" || it.transactionType == "TransferOut" || it.transactionType == "Purchase" }.sumOf { it.amount }
    val balance = totalIncome - totalExpense

    // Force RTL local layout direction for Arabic visual matching
    CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
        Scaffold(
            containerColor = Color(0xFFF9FBFC) // Light premium background
        ) { innerPadding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .verticalScroll(rememberScrollState())
            ) {
                Spacer(modifier = Modifier.height(28.dp))

                // ── العنوان الرئيسي (Dashboard Header) ────────────────────────
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = AppSpacing.ScreenH)
                ) {
                    Text(
                        text = "لوحة التحكم الذكية",
                        style = MaterialTheme.typography.headlineLarge.copy(
                            fontSize = 28.sp,
                            fontWeight = FontWeight.Bold
                        ),
                        color = AppColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(6.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.Sync,
                            contentDescription = null,
                            modifier = Modifier.size(16.dp),
                            tint = AppColors.TextSecondary
                        )
                        Text(
                            text = "تحديث مباشر بدون سحب",
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 12.sp),
                            color = AppColors.TextSecondary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // ── كنز المحافظ التمريري (Horizontal Wallet Carousel) ────────
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .horizontalScroll(rememberScrollState())
                        .padding(horizontal = AppSpacing.ScreenH, vertical = AppSpacing.xs),
                    horizontalArrangement = Arrangement.spacedBy(AppSpacing.base)
                ) {
                    // البطاقة 1: رصيد جيب التلقائي (الأحمر المميز)
                    WalletCardItem(
                        title = "رصيد جيب التلقائي",
                        amount = balance,
                        icon = Icons.Rounded.AccountBalanceWallet,
                        badgeText = "تلقائي",
                        isPrimary = true
                    )
                    
                    // البطاقة 2: رصيد الكاش اليدوي (أبيض نظيف)
                    WalletCardItem(
                        title = "رصيد الكاش اليدوي",
                        amount = 0.0,
                        icon = Icons.Rounded.Payments,
                        badgeText = "يدوي",
                        isPrimary = false
                    )
                    
                    // البطاقة 3: الرؤية الموحدة (رمادي زجاجي)
                    WalletCardItem(
                        title = "الرؤية الموحدة - الإجمالي",
                        amount = balance,
                        icon = Icons.Rounded.AccountBalance,
                        badgeText = "شامل",
                        isPrimary = false,
                        isSurface = true
                    )
                }

                Spacer(modifier = Modifier.height(24.dp))

                // ── بطاقة تحليل المصروفات (Reactive Analytics Section) ────────
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = AppSpacing.ScreenH)
                        .shadow(AppElevation.xs, AppShapes.CardLg, spotColor = Color.Black.copy(alpha = 0.04f))
                        .background(AppColors.Surface, AppShapes.CardLg)
                        .border(1.dp, AppColors.Border, AppShapes.CardLg)
                        .padding(20.dp)
                ) {
                    Column {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "تحليل المصروفات",
                                style = MaterialTheme.typography.titleLarge.copy(
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 20.sp
                                ),
                                color = AppColors.TextPrimary
                            )
                            Row(horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                Box(modifier = Modifier.size(8.dp).background(AppColors.TextSecondary, CircleShape))
                                Box(modifier = Modifier.size(8.dp).background(AppColors.Primary, CircleShape))
                            }
                        }

                        Spacer(modifier = Modifier.height(28.dp))

                        // مخطط الأعمدة التفاعلي (Interactive Bar Chart)
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(160.dp),
                            verticalAlignment = Alignment.Bottom,
                            horizontalArrangement = Arrangement.spacedBy(12.dp)
                        ) {
                            val maxAmount = transactions.maxOfOrNull { it.amount }?.coerceAtLeast(1.0) ?: 1.0
                            val recentTx = transactions.take(5)
                            if (recentTx.isEmpty()) {
                                repeat(5) { ChartBar(heightFraction = 0.05f, color = Color(0xFFE2E5E8)) }
                            } else {
                                recentTx.forEach { tx ->
                                    val fraction = (tx.amount / maxAmount).toFloat().coerceIn(0.1f, 1f)
                                    val color = if (tx.transactionType == "TransferIn") Color(0xFFD3E0EA) else Color(0xFFFFB3A7)
                                    ChartBar(heightFraction = fraction, color = color)
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(24.dp))

                        // تسميات التوضيح (Legend)
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                Box(modifier = Modifier.size(8.dp).background(AppColors.Primary, CircleShape))
                                Text(
                                    text = "تنبيه: إنفاق عالي (تعليم)",
                                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                                    color = AppColors.TextSecondary
                                )
                            }
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                Box(modifier = Modifier.size(8.dp).background(Color(0xFFC4C8CC), CircleShape))
                                Text(
                                    text = "نمو الدخل: +12%",
                                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                                    color = AppColors.TextSecondary
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(28.dp))

                // ── قائمة المعاملات الأخيرة (Recent Transactions Feed) ────────
                Column(modifier = Modifier.padding(horizontal = AppSpacing.ScreenH)) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween,
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            text = "آخر المعاملات",
                            style = MaterialTheme.typography.titleLarge.copy(
                                fontWeight = FontWeight.Bold,
                                fontSize = 20.sp
                            ),
                            color = AppColors.TextPrimary
                        )
                        Text(
                            text = "عرض الكل",
                            style = MaterialTheme.typography.labelLarge.copy(
                                color = AppColors.Primary,
                                fontWeight = FontWeight.Bold
                            ),
                            modifier = Modifier.clickable { /*TODO*/ }
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    // القائمة الديناميكية للعمليات
                    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                        if (transactions.isEmpty()) {
                            // Empty State Message
                            Text(
                                text = "محفظتك في فترة راحة اليوم... استمتع بيومك!",
                                style = MaterialTheme.typography.bodyMedium,
                                color = AppColors.TextSecondary,
                                modifier = Modifier.padding(vertical = 24.dp).fillMaxWidth(),
                                textAlign = TextAlign.Center
                            )
                        } else {
                            transactions.take(10).forEach { tx ->
                                val style = com.shehabgo.smartfinancialtracker.ui.utils.CategoryMapper.getStyleForCounterpart(tx.counterpart)
                                val isIncome = tx.transactionType == "TransferIn"
                                val amountPrefix = if(isIncome) "+ " else "- "
                                
                                TransactionItemRow(
                                    title = tx.counterpart.ifEmpty { "عملية مالية" },
                                    subtitle = if(isIncome) "إيراد - تلقائي" else "مصروف - تلقائي",
                                    amount = "$amountPrefix${String.format("%,.0f", tx.amount)}",
                                    timeLabel = SimpleDateFormat("dd/MM/yyyy HH:mm", Locale.US).format(Date(tx.timestamp)),
                                    isIncome = isIncome,
                                    icon = style.icon,
                                    iconBgColor = style.containerColor,
                                    iconTint = style.contentColor,
                                    accentColor = null // الشريط الجانبي اختياري
                                )
                            }
                        }
                    }
                }
                
                Spacer(modifier = Modifier.height(120.dp))
            }
        }
    }
}

@Composable
fun WalletCardItem(
    title: String,
    amount: Double,
    icon: ImageVector,
    badgeText: String,
    isPrimary: Boolean,
    isSurface: Boolean = false
) {
    val modifier = if (isPrimary) {
        Modifier
            .width(260.dp)
            .shadow(AppElevation.md, AppShapes.Card, spotColor = AppColors.Primary.copy(alpha = 0.25f))
            .background(
                Brush.linearGradient(
                    colors = listOf(
                        AppColors.Primary,
                        Color(0xFFE61D2B)
                    )
                ),
                AppShapes.Card
            )
    } else if (isSurface) {
        Modifier
            .width(260.dp)
            .shadow(AppElevation.xs, AppShapes.Card, spotColor = Color.Black.copy(alpha = 0.02f))
            .background(Color(0xFFF0F4F8).copy(alpha = 0.8f), AppShapes.Card)
            .border(1.dp, AppColors.Border, AppShapes.Card)
    } else {
        Modifier
            .width(260.dp)
            .shadow(AppElevation.xs, AppShapes.Card, spotColor = Color.Black.copy(alpha = 0.02f))
            .background(AppColors.Surface, AppShapes.Card)
            .border(1.dp, AppColors.Border, AppShapes.Card)
    }

    val textColor = if (isPrimary) AppColors.Surface else AppColors.TextPrimary
    val subtitleColor = if (isPrimary) AppColors.Surface.copy(alpha = 0.8f) else AppColors.TextSecondary

    Box(
        modifier = modifier.padding(18.dp)
    ) {
        Column {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // شارة النوع
                Box(
                    modifier = Modifier
                        .background(
                            if (isPrimary) Color.White.copy(alpha = 0.2f) else Color(0xFFECEFF2),
                            RoundedCornerShape(12.dp)
                        )
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = badgeText,
                        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                        color = if (isPrimary) AppColors.Surface else AppColors.TextSecondary
                    )
                }

                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = if (isPrimary) AppColors.Surface else AppColors.Primary,
                    modifier = Modifier.size(24.dp)
                )
            }

            Spacer(modifier = Modifier.height(28.dp))

            Text(
                text = title,
                style = MaterialTheme.typography.labelMedium,
                color = subtitleColor
            )
            Spacer(modifier = Modifier.height(4.dp))
            Row(
                verticalAlignment = Alignment.Bottom,
                horizontalArrangement = Arrangement.spacedBy(6.dp)
            ) {
                Text(
                    text = String.format("%,.0f", amount),
                    style = MaterialTheme.typography.headlineMedium.copy(
                        fontWeight = FontWeight.Bold,
                        fontSize = 24.sp
                    ),
                    color = textColor
                )
                Text(
                    text = "ر.ي",
                    style = MaterialTheme.typography.labelSmall,
                    color = subtitleColor,
                    modifier = Modifier.padding(bottom = 3.dp)
                )
            }
        }
    }
}

@Composable
fun RowScope.ChartBar(heightFraction: Float, color: Color, hasDot: Boolean = false) {
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
                    .background(AppColors.Primary, CircleShape)
            )
        }
    }
}

@Composable
fun TransactionItemRow(
    title: String,
    subtitle: String,
    amount: String,
    timeLabel: String? = null,
    isIncome: Boolean,
    icon: ImageVector,
    iconBgColor: Color,
    iconTint: Color,
    accentColor: Color? = null
) {
    val amountColor = if (isIncome) Color(0xFF141D23) else AppColors.Primary

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(AppElevation.xs, AppShapes.Card, spotColor = Color.Black.copy(alpha = 0.03f))
            .background(AppColors.Surface, AppShapes.Card)
            .border(1.dp, AppColors.Border, AppShapes.Card)
    ) {
        // الشريط الملون الجانبي من جهة البداية (اليمين في RTL)
        if (accentColor != null) {
            Box(
                modifier = Modifier
                    .align(Alignment.CenterStart)
                    .width(4.dp)
                    .fillMaxHeight()
                    .clip(RoundedCornerShape(topStart = 12.dp, bottomStart = 12.dp))
                    .background(accentColor)
            )
        }

        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                // دائرة الأيقونة
                Box(
                    modifier = Modifier
                        .size(44.dp)
                        .background(iconBgColor, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = icon,
                        contentDescription = null,
                        tint = iconTint,
                        modifier = Modifier.size(22.dp)
                    )
                }
                Column {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                        color = AppColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                        color = AppColors.TextSecondary
                    )
                }
            }

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = amount,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp
                    ),
                    color = amountColor
                )
                if (timeLabel != null) {
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = timeLabel,
                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                        color = AppColors.TextSecondary
                    )
                }
            }
        }
    }
}


