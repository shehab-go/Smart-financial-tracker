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
    viewModel: DashboardViewModel = viewModel(),
    onNavigateToLedger: () -> Unit = {},
    onNavigateToAdmin: () -> Unit = {}
) {
    val transactions by viewModel.transactions.collectAsStateWithLifecycle()

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

                // ── العنوان الرئيسي (Dashboard Header) ────────────────────────
                Column(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = AppSpacing.ScreenH),
                    horizontalAlignment = Alignment.CenterHorizontally
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
                                val displayExpense = if (totalExpense > 0) totalExpense else 154000.0 // Mock if empty
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

                        // ── مخطط الأعمدة الاحترافي (Professional Bar Chart) ────────
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(160.dp)
                        ) {
                            // Average Dashed Line
                            androidx.compose.foundation.Canvas(modifier = Modifier.fillMaxSize()) {
                                val canvasWidth = size.width
                                val canvasHeight = size.height
                                val yOffset = canvasHeight * 0.4f // 40% from top
                                drawLine(
                                    color = AppColors.BorderStrong,
                                    start = androidx.compose.ui.geometry.Offset(0f, yOffset),
                                    end = androidx.compose.ui.geometry.Offset(canvasWidth, yOffset),
                                    strokeWidth = 2f,
                                    pathEffect = androidx.compose.ui.graphics.PathEffect.dashPathEffect(floatArrayOf(10f, 10f), 0f)
                                )
                            }

                            Row(
                                modifier = Modifier.fillMaxSize(),
                                verticalAlignment = Alignment.Bottom,
                                horizontalArrangement = Arrangement.SpaceBetween
                            ) {
                                val days = listOf("السبت", "الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة")
                                val values = listOf(0.3f, 0.5f, 0.2f, 0.8f, 0.4f, 0.9f, 0.6f)
                                
                                days.forEachIndexed { index, day ->
                                    val isToday = index == 5 // الخميس (Today)
                                    Column(
                                        horizontalAlignment = Alignment.CenterHorizontally,
                                        verticalArrangement = Arrangement.Bottom,
                                        modifier = Modifier.fillMaxHeight()
                                    ) {
                                        // The Bar Track
                                        Box(
                                            modifier = Modifier
                                                .width(16.dp)
                                                .weight(1f)
                                                .background(AppColors.SurfaceVariant.copy(alpha = 0.5f), RoundedCornerShape(100)),
                                            contentAlignment = Alignment.BottomCenter
                                        ) {
                                            // The Actual Bar Fill
                                            Box(
                                                modifier = Modifier
                                                    .fillMaxWidth()
                                                    .fillMaxHeight(values[index])
                                                    .background(if (isToday) AppColors.Primary else Color(0xFFFFB3A7), RoundedCornerShape(100))
                                            )
                                        }
                                        Spacer(modifier = Modifier.height(8.dp))
                                        Text(
                                            text = day.take(2), // اول حرفين
                                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp, fontWeight = if(isToday) FontWeight.Bold else FontWeight.Normal),
                                            color = if (isToday) AppColors.Primary else AppColors.TextHint
                                        )
                                    }
                                }
                            }
                        }

                        Spacer(modifier = Modifier.height(28.dp))

                        // ── تسميات التوضيح (Legend / Insights) ────────
                        Row(
                            modifier = Modifier.fillMaxWidth(),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Box(modifier = Modifier.size(8.dp).background(AppColors.Primary, CircleShape))
                                    Text(
                                        text = "متوسط الإنفاق اليومي",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = AppColors.TextSecondary
                                    )
                                }
                                val displayAvg = if (totalExpense > 0) totalExpense / 7 else 22000.0
                                Text(
                                    text = String.format("%,.0f ر.ي", displayAvg),
                                    style = MaterialTheme.typography.titleSmall.copy(
                                        fontWeight = FontWeight.Bold,
                                        textDirection = androidx.compose.ui.text.style.TextDirection.Ltr
                                    ),
                                    color = AppColors.TextPrimary,
                                    modifier = Modifier.padding(start = 14.dp, top = 4.dp)
                                )
                            }
                            Column(horizontalAlignment = Alignment.End) {
                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                                    Box(modifier = Modifier.size(8.dp).background(AppColors.Success, CircleShape))
                                    Text(
                                        text = "توفير عن الأسبوع الماضي",
                                        style = MaterialTheme.typography.labelSmall,
                                        color = AppColors.TextSecondary
                                    )
                                }
                                Text(
                                    text = "+ 12%",
                                    style = MaterialTheme.typography.titleSmall.copy(
                                        fontWeight = FontWeight.Bold,
                                        textDirection = androidx.compose.ui.text.style.TextDirection.Ltr
                                    ),
                                    color = AppColors.Success,
                                    modifier = Modifier.padding(end = 14.dp, top = 4.dp)
                                )
                            }
                        }
                    }
                }

                // ... moved ...

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
                        val classifiedTransactions = transactions.filter { it.isClassified || (it.transactionType != "Transfer In" && it.transactionType != "Transfer Out") }
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
                            classifiedTransactions.take(10).forEach { tx ->
                                val style = com.shehabgo.smartfinancialtracker.ui.utils.CategoryMapper.getStyleForCounterpart(tx.counterpart)
                                val isIncome = tx.transactionType == "TransferIn" || tx.transactionType == "Transfer In"
                                val amountPrefix = if(isIncome) "+ " else "- "
                                
                                TransactionItemRow(
                                    title = tx.counterpart.ifEmpty { "عملية مالية" },
                                    subtitle = if(isIncome) "إيراد - ${tx.category ?: "تلقائي"}" else "مصروف - ${tx.category ?: "تلقائي"}",
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
                val formattedAmount = if (amount < 0) "- ${String.format("%,.0f", -amount)}" else String.format("%,.0f", amount)
                Text(
                    text = formattedAmount,
                    style = MaterialTheme.typography.headlineMedium.copy(
                        fontWeight = FontWeight.Bold,
                        fontSize = 24.sp,
                        textDirection = androidx.compose.ui.text.style.TextDirection.Ltr
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
                modifier = Modifier.weight(1f).padding(end = 12.dp),
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


