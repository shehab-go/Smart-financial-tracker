package com.shehabgo.smartfinancialtracker.ui.screens.ledger

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material.icons.automirrored.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection.Rtl
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shehabgo.smartfinancialtracker.ui.theme.AppColors
import com.shehabgo.smartfinancialtracker.ui.theme.AppShapes
import com.shehabgo.smartfinancialtracker.ui.theme.AppSpacing
import com.shehabgo.smartfinancialtracker.ui.theme.AppElevation
import com.financial.tracker.module.data.FinancialTransaction

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SocialLedgerScreen(
    onNavigateToDashboard: () -> Unit = {},
    onNavigateToAdmin: () -> Unit = {},
    viewModel: LedgerViewModel = androidx.lifecycle.viewmodel.compose.viewModel()
) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val transactions by viewModel.transactions.collectAsState()
    val totalOwedToMe by viewModel.totalOwedToMe.collectAsState()
    val totalOwedByMe by viewModel.totalOwedByMe.collectAsState()
    val unclassifiedQueue by viewModel.unclassifiedQueue.collectAsState()
    
    androidx.lifecycle.compose.LifecycleEventEffect(androidx.lifecycle.Lifecycle.Event.ON_RESUME) {
        viewModel.loadTransactions(context)
    }

    CompositionLocalProvider(LocalLayoutDirection provides Rtl) {
        Scaffold(
            containerColor = AppColors.Background
        ) { innerPadding ->
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(innerPadding)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = AppSpacing.ScreenH)
            ) {
                Spacer(modifier = Modifier.height(28.dp))

                // ── العنوان الرئيسي (Ledger Header) ────────────────────────
                Column(modifier = Modifier.fillMaxWidth()) {
                    Text(
                        text = "السجل الاجتماعي",
                        style = MaterialTheme.typography.headlineLarge.copy(fontSize = 28.sp, fontWeight = FontWeight.Bold),
                        color = AppColors.TextPrimary
                    )
                    Spacer(modifier = Modifier.height(6.dp))
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Icon(imageVector = Icons.Rounded.SyncAlt, contentDescription = null, modifier = Modifier.size(16.dp), tint = AppColors.TextSecondary)
                        Text(text = "مزامنة لحظية لديونك والتزاماتك مع الأشخاص", style = MaterialTheme.typography.labelSmall.copy(fontSize = 12.sp), color = AppColors.TextSecondary)
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // ── شريط الإجراءات المعلقة (Sleek Action Required Carousel) ──
                AnimatedVisibility(visible = unclassifiedQueue.isNotEmpty(), enter = expandVertically() + fadeIn(), exit = shrinkVertically() + fadeOut()) {
                    val tx = unclassifiedQueue.firstOrNull()
                    tx?.let {
                        var showSheet by remember { mutableStateOf(false) }
                        
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(bottom = AppSpacing.lg)
                                .shadow(AppElevation.sm, AppShapes.CardSm, spotColor = AppColors.Warning.copy(alpha = 0.2f))
                                .background(AppColors.Surface, AppShapes.CardSm)
                                .border(1.dp, AppColors.Warning.copy(alpha = 0.4f), AppShapes.CardSm)
                                .clickable { showSheet = true }
                                .padding(horizontal = AppSpacing.md, vertical = AppSpacing.sm)
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                    Box(modifier = Modifier.size(40.dp).background(AppColors.Warning.copy(alpha = 0.15f), CircleShape), contentAlignment = Alignment.Center) {
                                        Icon(Icons.Rounded.NotificationsActive, contentDescription = null, tint = AppColors.Warning, modifier = Modifier.size(20.dp))
                                    }
                                    Column {
                                        Text(text = "عملية تحتاج تصنيفك", style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold), color = AppColors.TextPrimary)
                                        Text(text = "بقيمة ${tx.amount} ر.ي مع ${tx.counterpart.ifEmpty { "مجهول" }}", style = MaterialTheme.typography.labelSmall, color = AppColors.TextSecondary)
                                    }
                                }
                                Icon(Icons.AutoMirrored.Rounded.ArrowForwardIos, contentDescription = null, tint = AppColors.TextHint, modifier = Modifier.size(14.dp))
                            }
                        }
                        
                        if (showSheet) {
                            val sheetState = rememberModalBottomSheetState()
                            ModalBottomSheet(
                                onDismissRequest = { showSheet = false },
                                sheetState = sheetState,
                                containerColor = AppColors.Surface,
                                shape = AppShapes.Sheet
                            ) {
                                UnclassifiedBottomSheetContent(tx, viewModel, context) { showSheet = false }
                            }
                        }
                    }
                }

                // ── بطاقة الميزان الموحدة (Unified Balance Card) ───────────
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(16.dp, AppShapes.CardLg, spotColor = AppColors.Primary.copy(alpha = 0.2f))
                        .background(
                            brush = androidx.compose.ui.graphics.Brush.linearGradient(
                                colors = listOf(AppColors.Surface, AppColors.Background)
                            ),
                            shape = AppShapes.CardLg
                        )
                        .border(1.dp, AppColors.Border, AppShapes.CardLg)
                        .padding(AppSpacing.CardPadLg)
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Text(text = "الميزان الصافي (الديون)", style = MaterialTheme.typography.labelLarge, color = AppColors.TextSecondary)
                        Spacer(modifier = Modifier.height(8.dp))
                        
                        val netBalance = totalOwedToMe - totalOwedByMe
                        val isPositive = netBalance >= 0
                        
                        Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                            Text(
                                text = String.format("%,.0f", Math.abs(netBalance)),
                                style = MaterialTheme.typography.headlineLarge.copy(fontWeight = FontWeight.Black, fontSize = 36.sp),
                                color = if (netBalance == 0.0) AppColors.TextPrimary else if (isPositive) AppColors.Success else AppColors.Primary
                            )
                            Text(
                                text = "ر.ي",
                                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                color = AppColors.TextSecondary,
                                modifier = Modifier.padding(bottom = 6.dp)
                            )
                        }
                        
                        Text(
                            text = if (netBalance == 0.0) "ميزانيتك متعادلة تماماً" else if (isPositive) "الناس مدينون لك أكثر" else "أنت مدين للناس أكثر",
                            style = MaterialTheme.typography.bodyMedium,
                            color = AppColors.TextHint
                        )
                        
                        Spacer(modifier = Modifier.height(24.dp))
                        
                        // ProgressBar الموحد
                        val totalDebtAndCredit = (totalOwedToMe + totalOwedByMe).coerceAtLeast(1.0)
                        val greenWeight = (totalOwedToMe / totalDebtAndCredit).toFloat()
                        val redWeight = (totalOwedByMe / totalDebtAndCredit).toFloat()
                        
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text(text = "مستحقات لك: ${String.format("%,.0f", totalOwedToMe)}", style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold), color = AppColors.Success)
                            Text(text = "التزامات عليك: ${String.format("%,.0f", totalOwedByMe)}", style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold), color = AppColors.Primary)
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Row(modifier = Modifier.fillMaxWidth().height(10.dp).clip(AppShapes.ButtonPill).background(AppColors.SurfaceVariant)) {
                            if (greenWeight > 0f) Box(modifier = Modifier.weight(greenWeight).fillMaxHeight().background(AppColors.Success))
                            if (redWeight > 0f) Box(modifier = Modifier.weight(redWeight).fillMaxHeight().background(AppColors.Primary))
                        }
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))

                // ── رأس قائمة الأشخاص ─────────────────────────────────
                Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                    Text(text = "علاقاتك المالية", style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold), color = AppColors.TextPrimary)
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp), modifier = Modifier.clickable { /*TODO Filter*/ }) {
                        Text(text = "أرشيف التسويات", style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold), color = AppColors.Primary)
                        Icon(imageVector = Icons.Rounded.History, contentDescription = null, tint = AppColors.Primary, modifier = Modifier.size(16.dp))
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // ── قائمة الديون المجمعة حسب الأشخاص ─────────────────────
                val activeDebts = transactions.filter { it.isDebt && !it.isSettled }
                val groupedDebts = activeDebts.groupBy { it.counterpart.ifEmpty { "غير محدد" } }

                if (groupedDebts.isEmpty()) {
                    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 40.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        Box(modifier = Modifier.size(80.dp).background(AppColors.Primary.copy(alpha = 0.05f), CircleShape), contentAlignment = Alignment.Center) {
                            Icon(imageVector = Icons.Rounded.VerifiedUser, contentDescription = null, tint = AppColors.Primary.copy(alpha = 0.5f), modifier = Modifier.size(40.dp))
                        }
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(text = "لا توجد ديون معلقة", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold), color = AppColors.TextPrimary)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(text = "سجلك نظيف تماماً. لا أحد يطالبك بشيء، ولا أنت تطالب أحداً!", style = MaterialTheme.typography.bodyMedium, color = AppColors.TextSecondary, textAlign = TextAlign.Center, modifier = Modifier.width(260.dp))
                    }
                } else {
                    groupedDebts.forEach { (personName, personTxs) ->
                        // Calculate Net for this person
                        // Transfer In (Income) + Debt = they lent me money (I owe them) -> negative net
                        // Transfer Out (Expense) + Debt = I lent them money (they owe me) -> positive net
                        val netForPerson = personTxs.sumOf { if (it.transactionType == "Transfer Out") it.amount else -it.amount }
                        PersonDebtCard(
                            personName = personName,
                            netBalance = netForPerson,
                            transactions = personTxs,
                            onSettle = { tx -> viewModel.settleTransaction(context, tx) }
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                    }
                }

                Spacer(modifier = Modifier.height(180.dp))
            }
        }
    }
}

@Composable
fun PersonDebtCard(
    personName: String,
    netBalance: Double,
    transactions: List<FinancialTransaction>,
    onSettle: (FinancialTransaction) -> Unit
) {
    var expanded by remember { mutableStateOf(false) }
    val isOwedToMe = netBalance > 0
    val isOwedByMe = netBalance < 0
    val balanceColor = if (netBalance == 0.0) AppColors.TextPrimary else if (isOwedToMe) AppColors.Success else AppColors.Primary
    val balanceText = if (netBalance == 0.0) "تمت التسوية تماماً" else if (isOwedToMe) "يجب أن يدفع لك" else "يجب أن تدفع له"
    
    Card(
        shape = AppShapes.Card,
        colors = CardDefaults.cardColors(containerColor = AppColors.Surface),
        elevation = CardDefaults.cardElevation(defaultElevation = AppElevation.sm),
        modifier = Modifier.fillMaxWidth().border(1.dp, AppColors.Border, AppShapes.Card)
    ) {
        Column(modifier = Modifier.fillMaxWidth()) {
            Row(
                modifier = Modifier
                    .fillMaxWidth()
                    .clickable { expanded = !expanded }
                    .padding(AppSpacing.CardPad),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.SpaceBetween
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically, 
                    horizontalArrangement = Arrangement.spacedBy(16.dp),
                    modifier = Modifier.weight(1f)
                ) {
                    Box(modifier = Modifier.size(52.dp).background(AppColors.SurfaceVariant, CircleShape).border(1.dp, AppColors.Border, CircleShape), contentAlignment = Alignment.Center) {
                        Text(text = personName.take(1).uppercase(), style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold), color = AppColors.TextPrimary)
                    }
                    Column(modifier = Modifier.weight(1f)) {
                        Text(text = personName, style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold), color = AppColors.TextPrimary, maxLines = 1, overflow = androidx.compose.ui.text.style.TextOverflow.Ellipsis)
                        Text(text = balanceText, style = MaterialTheme.typography.labelSmall, color = AppColors.TextSecondary)
                    }
                }
                
                Column(horizontalAlignment = Alignment.End, modifier = Modifier.padding(start = 8.dp)) {
                    Text(text = String.format("%,.0f", Math.abs(netBalance)), style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Black), color = balanceColor)
                    Icon(imageVector = if (expanded) Icons.Rounded.ExpandLess else Icons.Rounded.ExpandMore, contentDescription = null, tint = AppColors.TextHint)
                }
            }
            
            AnimatedVisibility(visible = expanded) {
                Column(modifier = Modifier.fillMaxWidth().background(AppColors.Background).padding(AppSpacing.sm)) {
                    Text("المعاملات النشطة (اسحب للتسوية)", style = MaterialTheme.typography.labelSmall, color = AppColors.TextHint, modifier = Modifier.padding(bottom = 8.dp, start = 8.dp))
                    transactions.forEach { tx ->
                        SwipeableTransactionItem(tx = tx, onSettle = { onSettle(tx) })
                        Spacer(modifier = Modifier.height(8.dp))
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SwipeableTransactionItem(
    tx: FinancialTransaction,
    onSettle: () -> Unit
) {
    val isIncome = tx.transactionType == "Transfer In"
    // Income + Debt = They lent me (I owe them, Primary/Red)
    // Out + Debt = I lent them (They owe me, Success/Green)
    val color = if (isIncome) AppColors.Primary else AppColors.Success 
    val typeText = if (isIncome) "دين عليك (استلفت منه)" else "دين لك (أقرضته)"
    
    val dismissState = rememberSwipeToDismissBoxState(
        confirmValueChange = {
            if (it == SwipeToDismissBoxValue.EndToStart || it == SwipeToDismissBoxValue.StartToEnd) {
                onSettle()
                true
            } else {
                false
            }
        }
    )

    SwipeToDismissBox(
        state = dismissState,
        enableDismissFromStartToEnd = true,
        enableDismissFromEndToStart = true,
        backgroundContent = {
            val bgColor = AppColors.Success
            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .clip(AppShapes.CardSm)
                    .background(bgColor)
                    .padding(horizontal = 20.dp),
                contentAlignment = Alignment.CenterEnd
            ) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Text("تسوية", color = Color.White, fontWeight = FontWeight.Bold)
                    Icon(Icons.Rounded.CheckCircle, contentDescription = null, tint = Color.White)
                }
            }
        },
        content = {
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .clip(AppShapes.CardSm)
                    .background(AppColors.Surface)
                    .border(1.dp, AppColors.Border, AppShapes.CardSm)
                    .padding(16.dp)
            ) {
                Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                    Column {
                        Text(text = typeText, style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold), color = AppColors.TextSecondary)
                        Spacer(modifier = Modifier.height(2.dp))
                        val dateFormat = java.text.SimpleDateFormat("yyyy-MM-dd HH:mm", java.util.Locale.getDefault())
                        val dateString = dateFormat.format(java.util.Date(tx.timestamp))
                        Text(text = "تاريخ: $dateString", style = MaterialTheme.typography.labelSmall, color = AppColors.TextHint)
                    }
                    Text(text = String.format("%,.0f ر.ي", tx.amount), style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold), color = color)
                }
            }
        }
    )
}

@Composable
fun UnclassifiedBottomSheetContent(
    tx: FinancialTransaction,
    viewModel: LedgerViewModel,
    context: android.content.Context,
    onDismiss: () -> Unit
) {
    val isIncome = tx.transactionType == "Transfer In"
    var showCategories by remember { mutableStateOf(false) }
    
    Column(modifier = Modifier.fillMaxWidth().padding(horizontal = AppSpacing.ScreenH).padding(bottom = 32.dp)) {
        Text(
            text = "تصنيف العملية",
            style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
            color = AppColors.TextPrimary
        )
        Spacer(modifier = Modifier.height(8.dp))
        Text(
            text = "تم التقاط حوالة ${if(isIncome) "واردة من" else "صادرة إلى"} (${tx.counterpart.ifEmpty { "غير محدد" }}) بقيمة ${tx.amount} ر.ي.",
            style = MaterialTheme.typography.bodyMedium,
            color = AppColors.TextSecondary
        )
        Spacer(modifier = Modifier.height(24.dp))
        
        if (!showCategories) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                if (isIncome) {
                    Button(onClick = { viewModel.classifyTransaction(context, tx, isDebt = true, category = "Debt"); onDismiss() }, modifier = Modifier.fillMaxWidth().height(AppSpacing.ButtonHeight), shape = AppShapes.Button, colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary)) { Text("سجلها كدين لي (سلف)", fontWeight = FontWeight.Bold) }
                    Button(onClick = { showCategories = true }, modifier = Modifier.fillMaxWidth().height(AppSpacing.ButtonHeight), shape = AppShapes.Button, colors = ButtonDefaults.buttonColors(containerColor = AppColors.Success)) { Text("تسجيل كدخل / إيراد", fontWeight = FontWeight.Bold) }
                    OutlinedButton(onClick = { viewModel.classifyTransaction(context, tx, isDebt = false, category = "Debt Repayment"); onDismiss() }, modifier = Modifier.fillMaxWidth().height(AppSpacing.ButtonHeight), shape = AppShapes.Button) { Text("استرداد دين (سددني)", fontWeight = FontWeight.Bold) }
                } else {
                    Button(onClick = { viewModel.classifyTransaction(context, tx, isDebt = true, category = "Debt"); onDismiss() }, modifier = Modifier.fillMaxWidth().height(AppSpacing.ButtonHeight), shape = AppShapes.Button, colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary)) { Text("سجلها كدين عليه (سلف)", fontWeight = FontWeight.Bold) }
                    Button(onClick = { showCategories = true }, modifier = Modifier.fillMaxWidth().height(AppSpacing.ButtonHeight), shape = AppShapes.Button, colors = ButtonDefaults.buttonColors(containerColor = AppColors.Error)) { Text("تسجيل كمصروف", fontWeight = FontWeight.Bold) }
                    OutlinedButton(onClick = { viewModel.classifyTransaction(context, tx, isDebt = false, category = "Debt Repayment"); onDismiss() }, modifier = Modifier.fillMaxWidth().height(AppSpacing.ButtonHeight), shape = AppShapes.Button) { Text("سداد دين علي", fontWeight = FontWeight.Bold) }
                }
            }
        } else {
            val categories = if (isIncome) listOf("راتب 💰", "أعمال حرة 💻", "هدية 🎁", "أخرى 📝") else listOf("طعام 🍔", "مواصلات 🚕", "فواتير 🧾", "تسوق 🛍️", "أخرى 📝")
            val chunkedCategories = categories.chunked(2)
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                chunkedCategories.forEach { rowItems ->
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                        rowItems.forEach { cat ->
                            OutlinedButton(
                                onClick = { viewModel.classifyTransaction(context, tx, isDebt = false, category = cat); onDismiss() },
                                modifier = Modifier.weight(1f).height(AppSpacing.ButtonHeight),
                                shape = AppShapes.Button
                            ) { Text(text = cat, fontSize = 13.sp) }
                        }
                        if (rowItems.size < 2) repeat(2 - rowItems.size) { Spacer(modifier = Modifier.weight(1f)) }
                    }
                }
            }
            Spacer(modifier = Modifier.height(16.dp))
            TextButton(onClick = { showCategories = false }, modifier = Modifier.fillMaxWidth()) { Text("رجوع", color = AppColors.TextSecondary) }
        }
    }
}
