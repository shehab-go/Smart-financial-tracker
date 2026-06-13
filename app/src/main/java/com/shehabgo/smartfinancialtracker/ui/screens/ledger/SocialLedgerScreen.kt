package com.shehabgo.smartfinancialtracker.ui.screens.ledger

import androidx.compose.animation.AnimatedVisibility
import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.fadeIn
import androidx.compose.animation.fadeOut
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
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
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.layout.boundsInRoot
import androidx.compose.ui.layout.onGloballyPositioned
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.LayoutDirection.Rtl
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.IntOffset
import androidx.compose.ui.unit.sp
import com.shehabgo.smartfinancialtracker.ui.theme.AppColors
import com.shehabgo.smartfinancialtracker.ui.theme.AppShapes
import com.shehabgo.smartfinancialtracker.ui.theme.AppSpacing
import com.shehabgo.smartfinancialtracker.ui.theme.AppElevation
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.geometry.Rect
import com.financial.tracker.module.data.FinancialTransaction
import kotlinx.coroutines.launch
import kotlin.math.roundToInt

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

    // Drop Zone state
    var dropZoneRect by remember { mutableStateOf(Rect.Zero) }
    var isHoveringDropZone by remember { mutableStateOf(false) }

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
                        Text(text = "مزامنة لحظية لديونك والتزاماتك", style = MaterialTheme.typography.labelSmall.copy(fontSize = 12.sp), color = AppColors.TextSecondary)
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // ── نافذة التصنيف الذكي (Dynamic Intent Prompt - Queue) ───────────────
                AnimatedVisibility(visible = unclassifiedQueue.isNotEmpty(), enter = fadeIn(), exit = fadeOut()) {
                    val tx = unclassifiedQueue.firstOrNull()
                    tx?.let { 
                        val isIncome = tx.transactionType == "Transfer In"
                        var showCategories by remember { mutableStateOf(false) }

                        // Reset state if transaction changes
                        LaunchedEffect(tx.referenceId) { showCategories = false }

                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(bottom = 24.dp)
                                .shadow(8.dp, AppShapes.CardLg, spotColor = AppColors.Warning.copy(alpha = 0.2f))
                                .background(AppColors.Warning.copy(alpha = 0.05f), AppShapes.CardLg)
                                .border(1.dp, AppColors.Warning.copy(alpha = 0.3f), AppShapes.CardLg)
                                .padding(20.dp)
                        ) {
                            Column {
                                Row(
                                    modifier = Modifier.fillMaxWidth(),
                                    horizontalArrangement = Arrangement.SpaceBetween,
                                    verticalAlignment = Alignment.CenterVertically
                                ) {
                                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                        Icon(imageVector = Icons.Rounded.TipsAndUpdates, contentDescription = null, tint = AppColors.Warning, modifier = Modifier.size(24.dp))
                                        Text(
                                            text = "عملية غير مصنفة!",
                                            style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                                            color = AppColors.Warning
                                        )
                                    }
                                    if (unclassifiedQueue.size > 1) {
                                        Box(modifier = Modifier.background(AppColors.Warning.copy(alpha = 0.15f), RoundedCornerShape(8.dp)).padding(horizontal = 8.dp, vertical = 4.dp)) {
                                            Text(text = "طابور: ${unclassifiedQueue.size}", style = MaterialTheme.typography.labelSmall, color = AppColors.Warning)
                                        }
                                    }
                                }
                                Spacer(modifier = Modifier.height(12.dp))
                                Text(
                                    text = "تم التقاط حوالة ${if(isIncome) "واردة من" else "صادرة إلى"} (${tx.counterpart}) بقيمة ${tx.amount} ر.ي. كيف تود تصنيفها؟",
                                    style = MaterialTheme.typography.bodyMedium,
                                    color = AppColors.TextPrimary
                                )
                                Spacer(modifier = Modifier.height(16.dp))
                                
                                AnimatedVisibility(visible = !showCategories) {
                                    Column(verticalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                                        if (isIncome) {
                                            Button(onClick = { viewModel.classifyTransaction(context, tx, isDebt = true, category = "Debt") }, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary)) { Text("سجلها كدين لي (سلف)", color = Color.White) }
                                            Button(onClick = { showCategories = true }, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = AppColors.Success)) { Text("تسجيل كدخل / إيراد", color = Color.White) }
                                            OutlinedButton(onClick = { viewModel.classifyTransaction(context, tx, isDebt = false, category = "Debt Repayment") }, modifier = Modifier.fillMaxWidth()) { Text("استرداد دين (سددني)") }
                                        } else {
                                            Button(onClick = { viewModel.classifyTransaction(context, tx, isDebt = true, category = "Debt") }, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = AppColors.Primary)) { Text("سجلها كدين عليه (سلف)", color = Color.White) }
                                            Button(onClick = { showCategories = true }, modifier = Modifier.fillMaxWidth(), colors = ButtonDefaults.buttonColors(containerColor = AppColors.Error)) { Text("تسجيل كمصروف", color = Color.White) }
                                            OutlinedButton(onClick = { viewModel.classifyTransaction(context, tx, isDebt = false, category = "Debt Repayment") }, modifier = Modifier.fillMaxWidth()) { Text("سداد دين علي") }
                                        }
                                    }
                                }

                                AnimatedVisibility(visible = showCategories) {
                                    Column {
                                        Text(text = if (isIncome) "اختر تصنيف الدخل:" else "اختر تصنيف المصروف:", style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold), color = AppColors.TextSecondary)
                                        Spacer(modifier = Modifier.height(12.dp))
                                        
                                        val categories = if (isIncome) listOf("راتب 💰", "أعمال حرة 💻", "هدية 🎁", "أخرى 📝") else listOf("طعام 🍔", "مواصلات 🚕", "فواتير 🧾", "تسوق 🛍️", "أخرى 📝")
                                        
                                        val chunkedCategories = categories.chunked(2)
                                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                                            chunkedCategories.forEach { rowItems ->
                                                Row(horizontalArrangement = Arrangement.spacedBy(8.dp), modifier = Modifier.fillMaxWidth()) {
                                                    rowItems.forEach { cat ->
                                                        OutlinedButton(
                                                            onClick = { viewModel.classifyTransaction(context, tx, isDebt = false, category = cat) },
                                                            modifier = Modifier.weight(1f),
                                                            contentPadding = PaddingValues(horizontal = 4.dp, vertical = 10.dp)
                                                        ) {
                                                            Text(text = cat, fontSize = 13.sp, maxLines = 1, textAlign = TextAlign.Center)
                                                        }
                                                    }
                                                    if (rowItems.size < 2) {
                                                        repeat(2 - rowItems.size) { Spacer(modifier = Modifier.weight(1f)) }
                                                    }
                                                }
                                            }
                                        }
                                        Spacer(modifier = Modifier.height(12.dp))
                                        TextButton(onClick = { showCategories = false }, modifier = Modifier.fillMaxWidth()) {
                                            Text("رجوع للخلف", color = AppColors.TextSecondary)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // ── مؤشر توازن الديون (Debt Equilibrium Index Cards) ───────────
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(16.dp)
                ) {
                    // كارت مستحقات (لي) - Premium Green Gradient
                    val owedToMeProgress by animateFloatAsState(targetValue = if (totalOwedToMe > 0) 1f else 0f)
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .shadow(12.dp, AppShapes.CardLg, spotColor = AppColors.Success.copy(alpha = 0.4f))
                            .background(
                                brush = androidx.compose.ui.graphics.Brush.linearGradient(colors = listOf(AppColors.Success, AppColors.Success.copy(alpha = 0.8f))),
                                shape = AppShapes.CardLg
                            )
                            .padding(20.dp)
                    ) {
                        Column {
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                Text(text = "مستحقات (لي)", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold), color = Color.White.copy(alpha = 0.9f))
                                Box(modifier = Modifier.background(Color.White.copy(alpha = 0.2f), CircleShape).padding(6.dp)) {
                                    Icon(imageVector = Icons.Rounded.ArrowDownward, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                                }
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text(text = String.format("%,.0f", totalOwedToMe), style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Black, fontSize = 26.sp), color = Color.White)
                                Text(text = "ر.ي", style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold), color = Color.White.copy(alpha = 0.8f), modifier = Modifier.padding(bottom = 4.dp))
                            }
                            Spacer(modifier = Modifier.height(24.dp))
                            Box(modifier = Modifier.fillMaxWidth().height(4.dp).background(Color.White.copy(alpha = 0.3f), CircleShape)) {
                                Box(modifier = Modifier.fillMaxWidth(owedToMeProgress).fillMaxHeight().background(Color.White, CircleShape))
                            }
                        }
                    }

                    // كارت التزامات (علي) - Premium Red Gradient
                    val owedByMeProgress by animateFloatAsState(targetValue = if (totalOwedByMe > 0) 1f else 0f)
                    Box(
                        modifier = Modifier
                            .weight(1f)
                            .shadow(12.dp, AppShapes.CardLg, spotColor = AppColors.Primary.copy(alpha = 0.4f))
                            .background(
                                brush = androidx.compose.ui.graphics.Brush.linearGradient(colors = listOf(AppColors.PrimaryLight, AppColors.Primary)),
                                shape = AppShapes.CardLg
                            )
                            .padding(20.dp)
                    ) {
                        Column {
                            Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                                Text(text = "التزامات (علي)", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold), color = Color.White.copy(alpha = 0.9f))
                                Box(modifier = Modifier.background(Color.White.copy(alpha = 0.2f), CircleShape).padding(6.dp)) {
                                    Icon(imageVector = Icons.Rounded.ArrowUpward, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                                }
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                                Text(text = String.format("%,.0f", totalOwedByMe), style = MaterialTheme.typography.headlineMedium.copy(fontWeight = FontWeight.Black, fontSize = 26.sp), color = Color.White)
                                Text(text = "ر.ي", style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold), color = Color.White.copy(alpha = 0.8f), modifier = Modifier.padding(bottom = 4.dp))
                            }
                            Spacer(modifier = Modifier.height(24.dp))
                            Box(modifier = Modifier.fillMaxWidth().height(4.dp).background(Color.White.copy(alpha = 0.3f), CircleShape)) {
                                Box(modifier = Modifier.fillMaxWidth(owedByMeProgress).fillMaxHeight().background(Color.White, CircleShape))
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(24.dp))

                // ── رأس قائمة سجل الحساب الموحد (Timeline Header) ───────────────
                Row(modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                    Text(text = "الديون النشطة", style = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold), color = AppColors.TextPrimary)
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp), modifier = Modifier.clickable { /*TODO Filter*/ }) {
                        Text(text = "أرشيف التسويات", style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold), color = AppColors.Primary)
                        Icon(imageVector = Icons.Rounded.History, contentDescription = null, tint = AppColors.Primary, modifier = Modifier.size(16.dp))
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))

                // Show only unsettled debts
                val displayTransactions = transactions.filter { it.isDebt && !it.isSettled }

                if (displayTransactions.isEmpty()) {
                    Column(modifier = Modifier.fillMaxWidth().padding(vertical = 40.dp), horizontalAlignment = Alignment.CenterHorizontally) {
                        Box(modifier = Modifier.size(80.dp).background(AppColors.Primary.copy(alpha = 0.05f), CircleShape), contentAlignment = Alignment.Center) {
                            Icon(imageVector = Icons.Rounded.AllInclusive, contentDescription = null, tint = AppColors.Primary.copy(alpha = 0.5f), modifier = Modifier.size(40.dp))
                        }
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(text = "السجل نظيف تماماً", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold), color = AppColors.TextPrimary)
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(text = "لا توجد أي ديون نشطة حالياً. استمتع براحة البال!", style = MaterialTheme.typography.bodyMedium, color = AppColors.TextSecondary, textAlign = TextAlign.Center, modifier = Modifier.width(260.dp))
                    }
                } else {
                    displayTransactions.forEach { tx ->
                        val isIncome = tx.transactionType == "Transfer In"
                        
                        val coroutineScope = rememberCoroutineScope()
                        val offsetX = remember { Animatable(0f) }
                        val offsetY = remember { Animatable(0f) }
                        var isDragging by remember { mutableStateOf(false) }

                        Box(
                            modifier = Modifier
                                .offset { IntOffset(offsetX.value.roundToInt(), offsetY.value.roundToInt()) }
                                .onGloballyPositioned { coordinates ->
                                    if (isDragging) {
                                        val itemBounds = coordinates.boundsInRoot()
                                        isHoveringDropZone = itemBounds.overlaps(dropZoneRect)
                                    }
                                }
                                .pointerInput(Unit) {
                                    detectDragGestures(
                                        onDragStart = { 
                                            isDragging = true 
                                        },
                                        onDragEnd = { 
                                            isDragging = false
                                            if (isHoveringDropZone) {
                                                viewModel.settleTransaction(context, tx)
                                                // It will disappear since it becomes settled
                                                isHoveringDropZone = false
                                            } else {
                                                coroutineScope.launch {
                                                    offsetX.animateTo(0f, spring())
                                                    offsetY.animateTo(0f, spring())
                                                }
                                            }
                                        },
                                        onDragCancel = { 
                                            isDragging = false
                                            isHoveringDropZone = false
                                            coroutineScope.launch {
                                                offsetX.animateTo(0f, spring())
                                                offsetY.animateTo(0f, spring())
                                            }
                                        },
                                        onDrag = { change, dragAmount -> 
                                            change.consume()
                                            coroutineScope.launch {
                                                offsetX.snapTo(offsetX.value + dragAmount.x)
                                                offsetY.snapTo(offsetY.value + dragAmount.y)
                                            }
                                        }
                                    )
                                },
                            // Bring dragged item to front
                            contentAlignment = Alignment.Center
                        ) {
                            LedgerItem(
                                name = tx.counterpart.ifEmpty { "غير محدد" },
                                subtitle = if (isIncome) "دين وارد (سلف لي)" else "دين صادر (سلف مني)",
                                amount = "${if(isIncome) "+" else "-"}${tx.amount} ر.ي",
                                amountSub = "غير مسوى (اسحب للتسوية)",
                                amountColor = if (isIncome) AppColors.Success else AppColors.Primary,
                                icon = if (isIncome) Icons.Rounded.CallReceived else Icons.Rounded.CallMade,
                                iconBg = if (isIncome) AppColors.Success.copy(alpha = 0.1f) else AppColors.PrimaryContainer,
                                iconColor = if (isIncome) AppColors.Success else AppColors.Primary,
                                isSettled = false
                            )
                        }
                        Spacer(modifier = Modifier.height(12.dp))
                    }
                }

                Spacer(modifier = Modifier.height(32.dp))

                // ── لوحة التسوية السريعة بالسحب والإسقاط (Settlement Visualizer) ──
                val dropZoneBg = if (isHoveringDropZone) AppColors.Primary.copy(alpha = 0.15f) else AppColors.Primary.copy(alpha = 0.03f)
                val dropZoneStrokeColor = if (isHoveringDropZone) AppColors.Primary else AppColors.Primary.copy(alpha = 0.3f)

                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(8.dp, AppShapes.CardLg, spotColor = AppColors.Primary.copy(alpha = 0.1f))
                        .background(Color.White, AppShapes.CardLg)
                        .padding(24.dp)
                        .onGloballyPositioned { coordinates ->
                            dropZoneRect = coordinates.boundsInRoot()
                        },
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Box(modifier = Modifier.background(AppColors.SurfaceVariant, CircleShape).padding(12.dp)) {
                            Icon(imageVector = Icons.Rounded.SyncAlt, contentDescription = null, tint = AppColors.Primary, modifier = Modifier.size(28.dp))
                        }
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(text = "التسوية السريعة", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold), color = AppColors.TextPrimary)
                        Spacer(modifier = Modifier.height(6.dp))
                        Text(text = "اسحب الدين من القائمة أعلاه وأسقطه هنا لتسويته وإغلاقه نهائياً", style = MaterialTheme.typography.bodyMedium, color = AppColors.TextSecondary, textAlign = TextAlign.Center, modifier = Modifier.width(240.dp))
                        Spacer(modifier = Modifier.height(24.dp))
                        
                        val stroke = Stroke(width = 4f, pathEffect = PathEffect.dashPathEffect(floatArrayOf(15f, 15f), 0f))
                        Box(
                            modifier = Modifier
                                .fillMaxWidth()
                                .height(90.dp)
                                .clip(RoundedCornerShape(16.dp))
                                .background(dropZoneBg)
                                .drawBehind {
                                    drawRoundRect(color = dropZoneStrokeColor, style = stroke, cornerRadius = CornerRadius(16.dp.toPx()))
                                },
                            contentAlignment = Alignment.Center
                        ) {
                            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Icon(imageVector = Icons.Rounded.Download, contentDescription = null, tint = AppColors.Primary.copy(alpha = if(isHoveringDropZone) 1f else 0.7f), modifier = Modifier.size(20.dp))
                                Text(text = "أفلت المعاملة هنا", style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold), color = AppColors.Primary.copy(alpha = if(isHoveringDropZone) 1f else 0.8f))
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(180.dp))
            }
        }
    }
}

@Composable
fun LedgerItem(
    name: String,
    subtitle: String,
    amount: String,
    amountSub: String,
    amountColor: Color,
    icon: ImageVector,
    iconBg: Color,
    iconColor: Color,
    isSettled: Boolean = false,
    hasIndicator: Boolean = false
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(AppElevation.xs, AppShapes.Card, spotColor = Color.Black.copy(alpha = 0.02f))
            .background(AppColors.Surface, AppShapes.Card)
            .border(1.dp, AppColors.Border, AppShapes.Card)
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Box(modifier = Modifier.size(44.dp).background(iconBg, CircleShape), contentAlignment = Alignment.Center) {
                    Icon(imageVector = icon, contentDescription = null, tint = iconColor, modifier = Modifier.size(22.dp))
                }
                Column {
                    Text(text = name, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold), color = AppColors.TextPrimary)
                    Spacer(modifier = Modifier.height(2.dp))
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        if (hasIndicator) { Box(modifier = Modifier.size(6.dp).background(AppColors.Primary, CircleShape)) }
                        Text(text = subtitle, style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp), color = AppColors.TextSecondary)
                    }
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Column(horizontalAlignment = Alignment.End) {
                    Text(text = amount, style = MaterialTheme.typography.bodyMedium.copy(fontWeight = FontWeight.Bold), color = amountColor)
                    Spacer(modifier = Modifier.height(2.dp))
                    Text(text = amountSub, style = MaterialTheme.typography.labelSmall.copy(fontSize = 11.sp), color = AppColors.TextHint)
                }
                if (isSettled) {
                    Icon(imageVector = Icons.Rounded.CheckCircle, contentDescription = null, tint = AppColors.Success, modifier = Modifier.size(22.dp))
                } else {
                    Icon(imageVector = Icons.Rounded.DragIndicator, contentDescription = null, tint = AppColors.TextHint, modifier = Modifier.size(22.dp))
                }
            }
        }
    }
}


