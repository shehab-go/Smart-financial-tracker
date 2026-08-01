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
import com.shehabgo.smartfinancialtracker.data.CategoryManager
import com.shehabgo.smartfinancialtracker.ui.screens.categories.CategoryItem
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.items

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UnifiedDashboardScreen(
    onNavigateToLedger: () -> Unit = {},
    onNavigateToTransactions: () -> Unit = {},
    onNavigateToAdmin: () -> Unit = {},
    viewModel: DashboardViewModel = viewModel()
) {
    val transactions by viewModel.transactions.collectAsStateWithLifecycle()
    val displayTransactions = transactions.take(5)

    // Calculate totals based on actual transaction data
    val totalIncome = transactions.filter { it.transactionType == "TransferIn" || it.transactionType == "Transfer In" }.sumOf { it.amount }
    val totalExpense = transactions.filter { it.transactionType == "Payment" || it.transactionType == "TransferOut" || it.transactionType == "Transfer Out" || it.transactionType == "Purchase" }.sumOf { it.amount }
    
    // Read the balance directly from the latest transaction that contains it, fallback to manual calculation
    val latestBalance = transactions.firstOrNull { it.balance != null }?.balance
    val balance = latestBalance ?: (totalIncome - totalExpense)
    val context = androidx.compose.ui.platform.LocalContext.current

    var transactionToCategorize by remember { mutableStateOf<FinancialTransaction?>(null) }
    var categories by remember { mutableStateOf(CategoryManager.getCategories(context)) }
    var isAddingCategory by remember { mutableStateOf(false) }
    var newCategoryName by remember { mutableStateOf("") }
    val presetColors = listOf(Color(0xFFE91E63), Color(0xFF9C27B0), Color(0xFF3F51B5), Color(0xFF00BCD4), Color(0xFF4CAF50), Color(0xFFFF9800))
    var newCategoryColor by remember { mutableStateOf(presetColors[0]) }
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

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

                // ── البطاقة العلوية (Hero Header & Balance) ────────────────────────
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = AppSpacing.ScreenH)
                        .shadow(AppElevation.md, AppShapes.CardLg, spotColor = AppColors.Primary.copy(alpha = 0.3f))
                        .background(
                            Brush.linearGradient(
                                colors = listOf(AppColors.Primary, Color(0xFFE61D2B))
                            ),
                            AppShapes.CardLg
                        )
                ) {
                    Column(
                        modifier = Modifier.padding(24.dp)
                    ) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = "مرحباً بك، شهاب! 👋",
                                    style = MaterialTheme.typography.labelLarge,
                                    color = Color.White.copy(alpha = 0.8f)
                                )
                                Spacer(modifier = Modifier.height(4.dp))
                                Text(
                                    text = "لوحة التحكم",
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                    color = Color.White
                                )
                            }
                            Box(
                                modifier = Modifier
                                    .size(40.dp)
                                    .background(Color.White.copy(alpha = 0.2f), CircleShape)
                                    .clickable { /* Notifications or Settings */ },
                                contentAlignment = Alignment.Center
                            ) {
                                Icon(Icons.Rounded.Notifications, contentDescription = null, tint = Color.White, modifier = Modifier.size(20.dp))
                            }
                        }

                        Spacer(modifier = Modifier.height(24.dp))

                        Text(
                            text = "الرصيد الإجمالي المتاح",
                            style = MaterialTheme.typography.labelMedium,
                            color = Color.White.copy(alpha = 0.7f)
                        )
                        Spacer(modifier = Modifier.height(4.dp))
                        Text(
                            text = String.format("%,.0f ر.ي", balance),
                            style = MaterialTheme.typography.displaySmall.copy(
                                fontWeight = FontWeight.Bold,
                                textDirection = androidx.compose.ui.text.style.TextDirection.Ltr
                            ),
                            color = Color.White
                        )

                        Spacer(modifier = Modifier.height(28.dp))

                        // أزرار الوصول السريع (Quick Actions)
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            QuickActionItem(icon = Icons.Rounded.Add, label = "إضافة", onClick = { /* TODO */ })
                            QuickActionItem(icon = Icons.Rounded.Send, label = "تحويل", onClick = { /* TODO */ })
                            QuickActionItem(icon = Icons.Rounded.Payments, label = "دفع", onClick = { /* TODO */ })
                            QuickActionItem(icon = Icons.Rounded.AccountBalanceWallet, label = "سحب", onClick = { /* TODO */ })
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // ── بطاقات المحافظ الرقمية (Digital Wallets) ────────
                Column(modifier = Modifier.padding(top = 12.dp)) {
                    Text(
                        text = "محافظك النشطة",
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = AppColors.TextPrimary,
                        modifier = Modifier.padding(start = AppSpacing.ScreenH, end = AppSpacing.ScreenH, bottom = 12.dp)
                    )
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .horizontalScroll(rememberScrollState())
                            .padding(horizontal = AppSpacing.ScreenH, vertical = AppSpacing.xs),
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        // البطاقة 1: رصيد جيب التلقائي
                        WalletCardItem(
                            title = "رصيد جيب التلقائي",
                            amount = balance,
                            icon = Icons.Rounded.AccountBalanceWallet,
                            badgeText = "أساسي",
                            isPrimary = false,
                            gradientColors = listOf(Color(0xFF1E293B), Color(0xFF0F172A)) // Dark Premium
                        )
                        
                        // البطاقة 2: رصيد الكاش اليدوي
                        WalletCardItem(
                            title = "رصيد الكاش اليدوي",
                            amount = 0.0,
                            icon = Icons.Rounded.Payments,
                            badgeText = "كاش",
                            isPrimary = false,
                            gradientColors = listOf(Color(0xFF0D9488), Color(0xFF0F766E)) // Teal Premium
                        )
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // ── ملخص الدخل والمصروفات (Mini Analytics) ────────
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = AppSpacing.ScreenH),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // الدخل
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .shadow(AppElevation.xs, AppShapes.Card, spotColor = Color.Black.copy(alpha = 0.05f))
                            .background(AppColors.Surface, AppShapes.Card)
                            .padding(16.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            Box(modifier = Modifier.size(36.dp).background(AppColors.Success.copy(alpha = 0.1f), CircleShape), contentAlignment = Alignment.Center) {
                                Icon(Icons.Rounded.ArrowDownward, contentDescription = null, tint = AppColors.Success, modifier = Modifier.size(20.dp))
                            }
                            Column {
                                Text(text = "الدخل", style = MaterialTheme.typography.labelMedium, color = AppColors.TextSecondary)
                                Text(
                                    text = String.format("%,.0f ر.ي", totalIncome),
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                    color = AppColors.TextPrimary
                                )
                            }
                        }
                    }
                    
                    // المصروفات
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .shadow(AppElevation.xs, AppShapes.Card, spotColor = Color.Black.copy(alpha = 0.05f))
                            .background(AppColors.Surface, AppShapes.Card)
                            .padding(16.dp)
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            Box(modifier = Modifier.size(36.dp).background(AppColors.Error.copy(alpha = 0.1f), CircleShape), contentAlignment = Alignment.Center) {
                                Icon(Icons.Rounded.ArrowUpward, contentDescription = null, tint = AppColors.Error, modifier = Modifier.size(20.dp))
                            }
                            Column {
                                Text(text = "المصروفات", style = MaterialTheme.typography.labelMedium, color = AppColors.TextSecondary)
                                Text(
                                    text = String.format("%,.0f ر.ي", totalExpense),
                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                    color = AppColors.TextPrimary
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // ── قائمة العمليات غير المؤكدة (Unconfirmed Transactions Stream) ────────
                val unclassifiedList = transactions.filter { 
                    !it.isClassified && (it.transactionType == "Transfer In" || it.transactionType == "Transfer Out")
                }.sortedBy { it.timestamp }

                if (unclassifiedList.isNotEmpty()) {
                    Column(modifier = Modifier.padding(horizontal = AppSpacing.ScreenH)) {
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Text(
                                text = "عمليات بانتظار التأكيد",
                                style = MaterialTheme.typography.titleLarge.copy(
                                    fontWeight = FontWeight.Bold,
                                    fontSize = 20.sp
                                ),
                                color = AppColors.TextPrimary
                            )
                            Box(
                                modifier = Modifier
                                    .background(AppColors.Warning.copy(alpha = 0.2f), CircleShape)
                                    .padding(horizontal = 8.dp, vertical = 2.dp)
                            ) {
                                Text(
                                    text = "${unclassifiedList.size}",
                                    style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                                    color = AppColors.Warning
                                )
                            }
                        }
                        Spacer(modifier = Modifier.height(16.dp))
                        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                            unclassifiedList.take(3).forEach { tx ->
                                UnconfirmedTransactionCard(
                                    transaction = tx,
                                    onClassifyAsExpense = {
                                        val isIncome = tx.transactionType == "Transfer In" || tx.transactionType == "TransferIn"
                                        if (isIncome) {
                                            viewModel.classifyTransaction(context = context, tx = tx, isDebt = false, category = "Income")
                                        } else {
                                            transactionToCategorize = tx
                                        }
                                    },
                                    onClassifyAsDebt = {
                                        viewModel.classifyTransaction(context = context, tx = tx, isDebt = true, category = "Debt")
                                    },
                                    onIgnore = {
                                        viewModel.classifyTransaction(context = context, tx = tx, isDebt = false, category = "Ignored")
                                    }
                                )
                            }
                        }
                    }
                    Spacer(modifier = Modifier.height(28.dp))
                }

                // ── بطاقة تحليل المصروفات (Reactive Analytics Section) ────────
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = AppSpacing.ScreenH)
                        .shadow(AppElevation.md, AppShapes.CardLg, spotColor = Color.Black.copy(alpha = 0.05f))
                        .background(
                            Brush.linearGradient(listOf(Color(0xFFFFFFFF), Color(0xFFF8FAFC))),
                            AppShapes.CardLg
                        )
                        .border(1.dp, Color.White, AppShapes.CardLg)
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

                        // ── ملخص الإنفاق ────────────────────────
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = "إجمالي المصروفات",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = AppColors.TextSecondary
                                )
                                Spacer(modifier = Modifier.height(2.dp))
                                val displayExpense = totalExpense
                                Text(
                                    text = String.format("%,.0f ر.ي", displayExpense),
                                    style = MaterialTheme.typography.titleLarge.copy(
                                        fontWeight = FontWeight.Bold,
                                        textDirection = androidx.compose.ui.text.style.TextDirection.Ltr
                                    ),
                                    color = AppColors.Primary
                                )
                            }
                            // Chip: "هذا الأسبوع"
                            Box(
                                modifier = Modifier
                                    .background(AppColors.SurfaceVariant.copy(alpha = 0.5f), RoundedCornerShape(8.dp))
                                    .padding(horizontal = 10.dp, vertical = 6.dp)
                            ) {
                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                    Text("هذا الأسبوع", style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold), color = AppColors.TextPrimary)
                                    Icon(Icons.Rounded.KeyboardArrowDown, contentDescription = null, modifier = Modifier.size(14.dp), tint = AppColors.TextPrimary)
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(28.dp))

                        // ── حسابات المصروفات وخريطة الألوان (Expenses & Color Map) ────────
                        val expensesList = transactions.filter { it.transactionType == "Payment" || it.transactionType == "TransferOut" || it.transactionType == "Transfer Out" || it.transactionType == "Purchase" }
                        val categoryGroups = expensesList.groupBy { it.category ?: "غير مصنف" }
                            .mapValues { entry -> entry.value.sumOf { it.amount } }
                            .toList()
                            .sortedByDescending { it.second }
                            
                        val catColorMap = remember(categories, categoryGroups) {
                            val map = mutableMapOf<String, Color>()
                            val usedColors = mutableSetOf<Color>()
                            
                            // تعيين الألوان الثابتة للفئات الخاصة (مثل غير مصنف والديون إن وجدت كفئات غير مسجلة)
                            map["غير مصنف"] = Color(0xFF9E9E9E) // رمادي محايد لغير المصنف
                            usedColors.add(Color(0xFF9E9E9E))
                            
                            val fallbackPalette = listOf(
                                Color(0xFFBD001B), // Primary (Red)
                                Color(0xFFF59E0B), // Orange
                                Color(0xFF8B5CF6), // Purple
                                Color(0xFF10B981), // Green
                                Color(0xFF3B82F6), // Blue
                                Color(0xFFEC4899), // Pink
                                Color(0xFF14B8A6), // Teal
                                Color(0xFFF43F5E), // Rose
                                Color(0xFF6366F1), // Indigo
                                Color(0xFF84CC16)  // Lime
                            )
                            var fallbackIndex = 0
                            
                            categoryGroups.forEach { pair ->
                                val catName = pair.first
                                if (catName != "غير مصنف") {
                                    val matchedColor = categories.find { it.name == catName }?.color
                                    if (matchedColor != null && !usedColors.contains(matchedColor)) {
                                        map[catName] = matchedColor
                                        usedColors.add(matchedColor)
                                    } else {
                                        while (fallbackIndex < fallbackPalette.size && usedColors.contains(fallbackPalette[fallbackIndex])) {
                                            fallbackIndex++
                                        }
                                        val colorToUse = if (fallbackIndex < fallbackPalette.size) fallbackPalette[fallbackIndex++] else Color(0xFF333333)
                                        map[catName] = colorToUse
                                        usedColors.add(colorToUse)
                                    }
                                }
                            }
                            map
                        }

                        // ── الرقم البطل وشريط الطيف (Hero Expense & Spectrum Bar) ────────
                        val total = categoryGroups.sumOf { it.second }.coerceAtLeast(1.0)

                        Column(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalAlignment = Alignment.CenterHorizontally
                        ) {
                            Text(
                                text = "إجمالي الإنفاق",
                                style = MaterialTheme.typography.labelLarge,
                                color = AppColors.TextSecondary
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = String.format("%,.0f ر.ي", total),
                                style = MaterialTheme.typography.displaySmall.copy(fontWeight = FontWeight.ExtraBold),
                                color = AppColors.TextPrimary
                            )
                            
                            Spacer(modifier = Modifier.height(32.dp))
                            
                            // شريط الطيف اللوني (Spectrum Bar)
                            var animationPlayed by remember { mutableStateOf(false) }
                            LaunchedEffect(key1 = true) {
                                animationPlayed = true
                            }
                            val progressAnimation by androidx.compose.animation.core.animateFloatAsState(
                                targetValue = if (animationPlayed) 1f else 0f,
                                animationSpec = androidx.compose.animation.core.tween(durationMillis = 1000, easing = androidx.compose.animation.core.FastOutSlowInEasing)
                            )

                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height(16.dp)
                                    .clip(RoundedCornerShape(8.dp))
                                    .background(Color(0xFFF1F5F9))
                            ) {
                                if (categoryGroups.isNotEmpty()) {
                                    categoryGroups.forEachIndexed { index, pair ->
                                        val weight = ((pair.second / total) * progressAnimation).toFloat()
                                        if (weight > 0.01f) {
                                            val catColor = catColorMap[pair.first] ?: AppColors.Primary
                                            val shape = when {
                                                categoryGroups.size == 1 -> RoundedCornerShape(8.dp)
                                                index == 0 -> RoundedCornerShape(topStart = 8.dp, bottomStart = 8.dp)
                                                index == categoryGroups.size - 1 -> RoundedCornerShape(topEnd = 8.dp, bottomEnd = 8.dp)
                                                else -> androidx.compose.ui.graphics.RectangleShape
                                            }
                                            Box(
                                                modifier = Modifier
                                                    .weight(weight)
                                                    .fillMaxHeight()
                                                    .background(catColor, shape)
                                            )
                                            if (index < categoryGroups.size - 1) {
                                                Spacer(modifier = Modifier.width(2.dp))
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(32.dp))

                        // ── بطاقات الفئات الأفقية (Horizontal Category Carousel) ────────
                        val cats = categoryGroups.take(6) // Show top 6
                        if (cats.isNotEmpty()) {
                            androidx.compose.foundation.lazy.LazyRow(
                                horizontalArrangement = Arrangement.spacedBy(12.dp),
                                contentPadding = PaddingValues(horizontal = 4.dp)
                            ) {
                                items(cats.size) { index ->
                                    val pair = cats[index]
                                    val catName = pair.first
                                    val catAmount = pair.second
                                    val percent = ((catAmount / total) * 100).toInt()
                                    val catColor = catColorMap[catName] ?: AppColors.Primary
                                    val style = com.shehabgo.smartfinancialtracker.ui.utils.CategoryMapper.getEmojiAndColorForText(catName, false)

                                    Box(
                                        modifier = Modifier
                                            .width(150.dp)
                                            .shadow(AppElevation.sm, RoundedCornerShape(16.dp), spotColor = Color.Black.copy(alpha = 0.04f))
                                            .background(Color.White, RoundedCornerShape(16.dp))
                                            .border(1.dp, Color(0xFFF8FAFC), RoundedCornerShape(16.dp))
                                            .padding(16.dp)
                                    ) {
                                        Column {
                                            Row(
                                                modifier = Modifier.fillMaxWidth(),
                                                horizontalArrangement = Arrangement.SpaceBetween,
                                                verticalAlignment = Alignment.CenterVertically
                                            ) {
                                                Text(
                                                    text = "$percent%",
                                                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                                    color = catColor
                                                )
                                                Box(
                                                    modifier = Modifier.size(36.dp).background(catColor.copy(alpha = 0.1f), CircleShape),
                                                    contentAlignment = Alignment.Center
                                                ) {
                                                    Text(text = style.emoji, fontSize = 16.sp)
                                                }
                                            }
                                            Spacer(modifier = Modifier.height(16.dp))
                                            Text(
                                                text = catName,
                                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                                                color = AppColors.TextPrimary,
                                                maxLines = 1,
                                                overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis
                                            )
                                            Spacer(modifier = Modifier.height(4.dp))
                                            Text(
                                                text = String.format("%,.0f ر.ي", catAmount),
                                                style = MaterialTheme.typography.labelSmall,
                                                color = AppColors.TextSecondary
                                            )
                                        }
                                    }
                                }
                            }
                            
                            // ── قسم الرؤى الذكية (Smart Insights) ────────
                            val highestCat = cats.firstOrNull()
                            if (highestCat != null) {
                                Spacer(modifier = Modifier.height(24.dp))
                                Box(
                                    modifier = Modifier.fillMaxWidth().background(AppColors.Primary.copy(alpha = 0.05f), AppShapes.Card).border(1.dp, AppColors.Primary.copy(alpha = 0.1f), AppShapes.Card).padding(16.dp)
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                        Box(modifier = Modifier.size(40.dp).background(AppColors.Primary.copy(alpha = 0.1f), CircleShape), contentAlignment = Alignment.Center) {
                                            Icon(Icons.Rounded.Lightbulb, contentDescription = null, tint = AppColors.Primary)
                                        }
                                        Column {
                                            Text(text = "رؤية تحليلية ذكية", style = MaterialTheme.typography.labelSmall, color = AppColors.Primary)
                                            Spacer(modifier = Modifier.height(4.dp))
                                            Text(
                                                text = "أعلى استهلاك لديك كان في «${highestCat.first}» بمبلغ ${String.format("%,.0f", highestCat.second)} ر.ي.",
                                                style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold, lineHeight = 20.sp),
                                                color = AppColors.TextPrimary
                                            )
                                        }
                                    }
                                }
                            }
                        } else {
                            // Default Empty State
                            Text(
                                text = "لا توجد بيانات مصروفات كافية للتحليل",
                                style = MaterialTheme.typography.bodyMedium,
                                color = AppColors.TextSecondary,
                                modifier = Modifier.fillMaxWidth(),
                                textAlign = TextAlign.Center
                            )
                        }
                    }
                }

                // ... moved ...

                Spacer(modifier = Modifier.height(32.dp))

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
                            modifier = Modifier.clickable { onNavigateToTransactions() }
                        )
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    Column(verticalArrangement = Arrangement.spacedBy(0.dp)) {
                        val classifiedTransactions = transactions.filter { it.isClassified || (it.transactionType != "Transfer In" && it.transactionType != "Transfer Out") }
                            .sortedByDescending { it.timestamp }
                        if (classifiedTransactions.isEmpty()) {
                            // Empty State Message
                            Text(
                                text = "محفظتك في فترة راحة اليوم... استمتع بيومك!",
                                style = MaterialTheme.typography.bodyMedium,
                                color = AppColors.TextSecondary,
                                modifier = Modifier.padding(vertical = 24.dp).fillMaxWidth(),
                                textAlign = TextAlign.Center
                            )
                        } else {
                            val groupedTransactions = classifiedTransactions.take(5).groupBy { tx ->
                                val cal = java.util.Calendar.getInstance()
                                val today = cal.get(java.util.Calendar.DAY_OF_YEAR)
                                cal.timeInMillis = tx.timestamp
                                val txDay = cal.get(java.util.Calendar.DAY_OF_YEAR)
                                when (today - txDay) {
                                    0 -> "اليوم"
                                    1 -> "أمس"
                                    else -> SimpleDateFormat("dd MMM", Locale("ar")).format(Date(tx.timestamp))
                                }
                            }
                            
                            groupedTransactions.forEach { (dateGroup, txList) ->
                                Text(
                                    text = dateGroup,
                                    style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                                    color = AppColors.TextSecondary,
                                    modifier = Modifier.padding(top = 16.dp, bottom = 12.dp, start = 8.dp)
                                )
                                
                                txList.forEachIndexed { index, tx ->
                                    val isIncome = tx.transactionType == "TransferIn" || tx.transactionType == "Transfer In"
                                    val style = com.shehabgo.smartfinancialtracker.ui.utils.CategoryMapper.getEmojiAndColorForText(tx.category ?: tx.counterpart, isIncome)
                                    val amountPrefix = if(isIncome) "+ " else "- "
                                    
                                    Row(modifier = Modifier.fillMaxWidth().height(androidx.compose.foundation.layout.IntrinsicSize.Min)) {
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
                
                Spacer(modifier = Modifier.height(120.dp))
            }
            }

            if (transactionToCategorize != null) {
                ModalBottomSheet(
                    onDismissRequest = { transactionToCategorize = null },
                    sheetState = sheetState,
                    containerColor = AppColors.Surface
                ) {
                    Column(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(horizontal = 24.dp, vertical = 16.dp)
                    ) {
                        Text(
                            text = "اختر فئة المصروف",
                            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                            color = AppColors.TextPrimary
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "حدد الفئة المناسبة لهذه المعاملة",
                            style = MaterialTheme.typography.bodyMedium,
                            color = AppColors.TextSecondary
                        )
                        Spacer(modifier = Modifier.height(24.dp))
                        
                        LazyVerticalGrid(
                            columns = GridCells.Fixed(3),
                            horizontalArrangement = Arrangement.spacedBy(16.dp),
                            verticalArrangement = Arrangement.spacedBy(16.dp),
                            modifier = Modifier.heightIn(max = 400.dp)
                        ) {
                            items(categories) { cat ->
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    modifier = Modifier
                                        .clickable {
                                            viewModel.classifyTransaction(
                                                context = context,
                                                tx = transactionToCategorize!!,
                                                isDebt = false,
                                                category = cat.name
                                            )
                                            transactionToCategorize = null
                                        }
                                        .padding(8.dp)
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(56.dp)
                                            .background(cat.color.copy(alpha = 0.1f), CircleShape),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            imageVector = cat.icon,
                                            contentDescription = null,
                                            tint = cat.color,
                                            modifier = Modifier.size(28.dp)
                                        )
                                    }
                                    Spacer(modifier = Modifier.height(8.dp))
                                    Text(
                                        text = cat.name,
                                        style = MaterialTheme.typography.labelSmall,
                                        color = AppColors.TextPrimary,
                                        textAlign = TextAlign.Center
                                    )
                                }
                            }
                            item {
                                Column(
                                    horizontalAlignment = Alignment.CenterHorizontally,
                                    modifier = Modifier
                                        .clickable {
                                            isAddingCategory = true
                                        }
                                        .padding(8.dp)
                                ) {
                                    Box(
                                        modifier = Modifier
                                            .size(56.dp)
                                            .border(1.dp, AppColors.Primary, CircleShape)
                                            .background(Color.Transparent, CircleShape),
                                        contentAlignment = Alignment.Center
                                    ) {
                                        Icon(
                                            imageVector = Icons.Rounded.Add,
                                            contentDescription = null,
                                            tint = AppColors.Primary,
                                            modifier = Modifier.size(28.dp)
                                        )
                                    }
                                    Spacer(modifier = Modifier.height(8.dp))
                                    Text(
                                        text = "إضافة فئة",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = AppColors.Primary,
                                        textAlign = TextAlign.Center
                                    )
                                }
                            }
                        }
                        Spacer(modifier = Modifier.height(24.dp))
                    }
                }

                if (isAddingCategory) {
                    AlertDialog(
                        onDismissRequest = { isAddingCategory = false },
                        containerColor = AppColors.Surface,
                        title = {
                            Text(
                                text = "إضافة فئة جديدة",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                color = AppColors.TextPrimary
                            )
                        },
                        text = {
                            Column {
                                OutlinedTextField(
                                    value = newCategoryName,
                                    onValueChange = { newCategoryName = it },
                                    label = { Text("اسم الفئة") },
                                    modifier = Modifier.fillMaxWidth(),
                                    colors = OutlinedTextFieldDefaults.colors(
                                        focusedBorderColor = AppColors.Primary,
                                        unfocusedBorderColor = AppColors.Border
                                    )
                                )
                                Spacer(modifier = Modifier.height(16.dp))
                                Text(
                                    text = "اختر لوناً:",
                                    style = MaterialTheme.typography.labelMedium,
                                    color = AppColors.TextSecondary
                                )
                                Spacer(modifier = Modifier.height(8.dp))
                                Row(
                                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                                    modifier = Modifier.fillMaxWidth()
                                ) {
                                    presetColors.forEach { color ->
                                        Box(
                                            modifier = Modifier
                                                .size(32.dp)
                                                .background(color, CircleShape)
                                                .border(
                                                    width = if (newCategoryColor == color) 2.dp else 0.dp,
                                                    color = if (newCategoryColor == color) AppColors.TextPrimary else Color.Transparent,
                                                    shape = CircleShape
                                                )
                                                .clickable { newCategoryColor = color }
                                        )
                                    }
                                }
                            }
                        },
                        confirmButton = {
                            Button(
                                onClick = {
                                    if (newCategoryName.isNotBlank()) {
                                        val newId = (categories.maxOfOrNull { it.id } ?: 0) + 1
                                        val newCat = CategoryItem(
                                            id = newId,
                                            name = newCategoryName,
                                            subtitle = "فئة مخصصة",
                                            icon = Icons.Rounded.ShoppingBasket,
                                            color = newCategoryColor
                                        )
                                        val updatedList = categories + newCat
                                        CategoryManager.saveCategories(context, updatedList)
                                        categories = updatedList
                                        newCategoryName = ""
                                        isAddingCategory = false
                                    }
                                },
                                colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary)
                            ) {
                                Text("إضافة", color = AppColors.Surface)
                            }
                        },
                        dismissButton = {
                            TextButton(onClick = { isAddingCategory = false }) {
                                Text("إلغاء", color = AppColors.TextSecondary)
                            }
                        }
                    )
                }
        }
    }
}

@Composable
fun QuickActionItem(
    icon: ImageVector,
    label: String,
    onClick: () -> Unit
) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.clickable { onClick() }
    ) {
        Box(
            modifier = Modifier
                .size(56.dp)
                .background(Color.White.copy(alpha = 0.15f), CircleShape)
                .border(1.dp, Color.White.copy(alpha = 0.2f), CircleShape),
            contentAlignment = Alignment.Center
        ) {
            Icon(
                imageVector = icon,
                contentDescription = label,
                tint = Color.White,
                modifier = Modifier.size(24.dp)
            )
        }
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = label,
            style = MaterialTheme.typography.labelSmall,
            color = Color.White.copy(alpha = 0.9f)
        )
    }
}

@Composable
fun WalletCardItem(
    title: String,
    amount: Double,
    icon: ImageVector,
    badgeText: String,
    isPrimary: Boolean,
    isSurface: Boolean = false,
    gradientColors: List<Color> = listOf(AppColors.Primary, Color(0xFFE61D2B))
) {
    val modifier = Modifier
        .width(280.dp) // Wider for credit card feel
        .height(160.dp)
        .shadow(AppElevation.md, AppShapes.CardLg, spotColor = gradientColors.first().copy(alpha = 0.3f))
        .background(Brush.linearGradient(colors = gradientColors), AppShapes.CardLg)

    Box(
        modifier = modifier.padding(20.dp)
    ) {
        // Decorative background elements for credit card look
        Box(modifier = Modifier.offset(x = 180.dp, y = (-20).dp).size(100.dp).background(Color.White.copy(alpha = 0.05f), CircleShape))
        Box(modifier = Modifier.offset(x = (-30).dp, y = 80.dp).size(120.dp).background(Color.White.copy(alpha = 0.05f), CircleShape))
        
        Column(modifier = Modifier.fillMaxSize(), verticalArrangement = Arrangement.SpaceBetween) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                // شارة النوع
                Box(
                    modifier = Modifier
                        .background(Color.White.copy(alpha = 0.2f), RoundedCornerShape(12.dp))
                        .padding(horizontal = 10.dp, vertical = 4.dp)
                ) {
                    Text(
                        text = badgeText,
                        style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                        color = Color.White
                    )
                }

                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = Color.White.copy(alpha = 0.8f),
                    modifier = Modifier.size(28.dp)
                )
            }

            Column {
                Text(
                    text = title,
                    style = MaterialTheme.typography.labelMedium,
                    color = Color.White.copy(alpha = 0.7f)
                )
                Spacer(modifier = Modifier.height(4.dp))
                Row(
                    verticalAlignment = Alignment.Bottom,
                    horizontalArrangement = Arrangement.spacedBy(6.dp)
                ) {
                    val formattedAmount = if (amount < 0) "- ${String.format("%,.0f", -amount)}" else String.format("%,.0f", amount)
                    Text(
                        text = formattedAmount,
                        style = MaterialTheme.typography.headlineMedium.copy(
                            fontWeight = FontWeight.Bold,
                            fontSize = 28.sp,
                            textDirection = androidx.compose.ui.text.style.TextDirection.Ltr
                        ),
                        color = Color.White
                    )
                    Text(
                        text = "ر.ي",
                        style = MaterialTheme.typography.labelMedium,
                        color = Color.White.copy(alpha = 0.7f),
                        modifier = Modifier.padding(bottom = 4.dp)
                    )
                }
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
    emoji: String,
    iconBgColor: Color,
    iconTint: Color,
    accentColor: Color? = null,
    showIcon: Boolean = true
) {
    val amountColor = if (isIncome) Color(0xFF141D23) else AppColors.Primary

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(AppElevation.sm, AppShapes.Card, spotColor = Color.Black.copy(alpha = 0.04f))
            .background(Color.White, AppShapes.Card)
            .border(1.dp, Color(0xFFF1F5F9), AppShapes.Card)
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
                modifier = Modifier.weight(1f).padding(end = 12.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(14.dp)
            ) {
                if (showIcon) {
                    // دائرة الأيقونة
                    Box(
                        modifier = Modifier
                            .size(44.dp)
                            .background(iconBgColor, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Text(
                            text = emoji,
                            fontSize = 20.sp
                        )
                    }
                }
                Column {
                    Text(
                        text = title,
                        style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold),
                        color = AppColors.TextPrimary,
                        maxLines = 1,
                        overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis
                    )
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(
                        text = subtitle,
                        style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp),
                        color = AppColors.TextSecondary,
                        maxLines = 1,
                        overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis
                    )
                }
            }

            Column(horizontalAlignment = Alignment.End) {
                Text(
                    text = amount,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontWeight = FontWeight.Bold,
                        fontSize = 15.sp,
                        textDirection = androidx.compose.ui.text.style.TextDirection.Ltr
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


