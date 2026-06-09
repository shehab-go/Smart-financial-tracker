package com.shehabgo.smartfinancialtracker.ui.screens.ledger

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
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
import androidx.compose.ui.text.SpanStyle
import androidx.compose.ui.text.buildAnnotatedString
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shehabgo.smartfinancialtracker.ui.screens.dashboard.BottomNavigationBar

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SocialLedgerScreen(
    onNavigateToDashboard: () -> Unit = {},
    onNavigateToAdmin: () -> Unit = {}
) {
    var showPrompt by remember { mutableStateOf(true) }

    Scaffold(
        topBar = {
            TopAppBar(
                title = {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(40.dp)
                                .border(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.2f), CircleShape)
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
                            text = "CapitalCore",
                            style = MaterialTheme.typography.headlineMedium,
                            fontWeight = FontWeight.Bold,
                            color = MaterialTheme.colorScheme.primary
                        )
                    }
                },
                actions = {
                    IconButton(onClick = { /*TODO*/ }) {
                        Icon(
                            imageVector = Icons.Rounded.Notifications,
                            contentDescription = "Notifications",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                    IconButton(onClick = { /*TODO*/ }, modifier = Modifier.padding(end = 8.dp)) {
                        Icon(
                            imageVector = Icons.Rounded.Search,
                            contentDescription = "Search",
                            tint = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
                ),
                modifier = Modifier.shadow(1.dp)
            )
        },
        bottomBar = {
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
                    BottomNavItem(icon = Icons.Rounded.Dashboard, label = "Dashboard", isSelected = false, onClick = onNavigateToDashboard)
                    BottomNavItem(icon = Icons.Rounded.AccountBalanceWallet, label = "Wallets", isSelected = false, onClick = { })
                    BottomNavItem(icon = Icons.Rounded.AccountBalance, label = "Ledger", isSelected = true, onClick = { })
                    BottomNavItem(icon = Icons.Rounded.AdminPanelSettings, label = "Admin", isSelected = false, onClick = onNavigateToAdmin)
                }
            }
        }
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .background(MaterialTheme.colorScheme.background)
                .padding(innerPadding)
                .verticalScroll(rememberScrollState())
                .padding(horizontal = 20.dp)
        ) {
            Spacer(modifier = Modifier.height(24.dp))

            // Debt Equilibrium Index
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                // Receivable
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .shadow(4.dp, RoundedCornerShape(12.dp), spotColor = Color(0xFF4AA348).copy(alpha = 0.1f))
                        .background(Color.White, RoundedCornerShape(12.dp))
                        .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(12.dp))
                        .padding(24.dp)
                ) {
                    Column {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.Top) {
                            Text("مستحقات (لي)", style = MaterialTheme.typography.labelLarge, color = Color(0xFF2E7D32))
                            Icon(imageVector = Icons.Rounded.ArrowDownward, contentDescription = null, tint = Color(0xFF2E7D32), modifier = Modifier.size(20.dp))
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("12,450.00 ر.س", style = MaterialTheme.typography.headlineSmall, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
                        Text("من 8 أشخاص", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        Box(modifier = Modifier.fillMaxWidth().height(6.dp).background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(4.dp))) {
                            Box(modifier = Modifier.fillMaxWidth(0.75f).fillMaxHeight().background(Color(0xFF2E7D32), RoundedCornerShape(4.dp)))
                        }
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "لي عند الناس",
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.dp.value.sp),
                            color = Color.White,
                            modifier = Modifier.background(Color(0xFF2E7D32), RoundedCornerShape(12.dp)).padding(horizontal = 12.dp, vertical = 4.dp)
                        )
                    }
                }

                // Payable
                Box(
                    modifier = Modifier
                        .weight(1f)
                        .shadow(4.dp, RoundedCornerShape(12.dp), spotColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.1f))
                        .background(Color.White, RoundedCornerShape(12.dp))
                        .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(12.dp))
                        .padding(24.dp)
                ) {
                    Column {
                        Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.Top) {
                            Text("التزامات (علي)", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
                            Icon(imageVector = Icons.Rounded.ArrowUpward, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(20.dp))
                        }
                        Spacer(modifier = Modifier.height(8.dp))
                        Text("4,200.00 ر.س", style = MaterialTheme.typography.headlineSmall, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
                        Text("لـ 3 أشخاص", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        
                        Spacer(modifier = Modifier.height(16.dp))
                        Box(modifier = Modifier.fillMaxWidth().height(6.dp).background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(4.dp))) {
                            Box(modifier = Modifier.fillMaxWidth(0.25f).fillMaxHeight().background(MaterialTheme.colorScheme.primary, RoundedCornerShape(4.dp)))
                        }
                        Spacer(modifier = Modifier.height(16.dp))
                        Text(
                            text = "عَليّ للناس",
                            style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.dp.value.sp),
                            color = MaterialTheme.colorScheme.onPrimary,
                            modifier = Modifier.background(MaterialTheme.colorScheme.primary, RoundedCornerShape(12.dp)).padding(horizontal = 12.dp, vertical = 4.dp)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Intent-Aware Prompt
            if (showPrompt) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .shadow(16.dp, RoundedCornerShape(16.dp), spotColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.08f))
                        .background(Color.White, RoundedCornerShape(16.dp))
                        .border(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.2f), RoundedCornerShape(16.dp))
                        .padding(20.dp)
                ) {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.spacedBy(16.dp),
                        verticalAlignment = Alignment.Top
                    ) {
                        Box(
                            modifier = Modifier
                                .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.1f), RoundedCornerShape(12.dp))
                                .padding(12.dp)
                        ) {
                            Icon(imageVector = Icons.Rounded.PsychologyAlt, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(32.dp))
                        }
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "اكتشاف معاملة جديدة",
                                style = MaterialTheme.typography.titleMedium,
                                color = MaterialTheme.colorScheme.onSurface,
                                fontWeight = FontWeight.Bold
                            )
                            Spacer(modifier = Modifier.height(4.dp))
                            Text(
                                text = buildAnnotatedString {
                                    append("تحويل Jeeb بقيمة ")
                                    withStyle(SpanStyle(color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)) {
                                        append("500 ر.س")
                                    }
                                    append(" إلى ")
                                    withStyle(SpanStyle(color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)) {
                                        append("سلطان أحمد")
                                    }
                                    append(".")
                                },
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(8.dp))
                            Text(
                                text = "هل هذه الحوالة سلف أم سداد؟",
                                style = MaterialTheme.typography.labelLarge,
                                color = MaterialTheme.colorScheme.primary
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                Button(
                                    onClick = { showPrompt = false },
                                    modifier = Modifier.weight(1f).height(48.dp),
                                    shape = RoundedCornerShape(8.dp),
                                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
                                ) {
                                    Text("إقراض (سلف)", style = MaterialTheme.typography.labelLarge)
                                }
                                Button(
                                    onClick = { showPrompt = false },
                                    modifier = Modifier.weight(1f).height(48.dp),
                                    shape = RoundedCornerShape(8.dp),
                                    colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.surfaceVariant, contentColor = MaterialTheme.colorScheme.onSurface)
                                ) {
                                    Text("سداد دين", style = MaterialTheme.typography.labelLarge)
                                }
                            }
                        }
                        IconButton(onClick = { showPrompt = false }, modifier = Modifier.size(24.dp)) {
                            Icon(imageVector = Icons.Rounded.Close, contentDescription = "Close", tint = MaterialTheme.colorScheme.outline, modifier = Modifier.size(16.dp))
                        }
                    }
                }
                Spacer(modifier = Modifier.height(24.dp))
            }

            // Timeline / Ledger
            Row(
                modifier = Modifier.fillMaxWidth().padding(horizontal = 4.dp),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.Bottom
            ) {
                Text("سجل المعاملات الموحد", style = MaterialTheme.typography.headlineMedium.copy(fontSize = 20.dp.value.sp), color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp), modifier = Modifier.clickable { /*TODO*/ }) {
                    Text("فلترة", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary)
                    Icon(imageVector = Icons.Rounded.FilterList, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(16.dp))
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            Text("اليوم، 24 أكتوبر", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline, modifier = Modifier.padding(horizontal = 4.dp))
            Spacer(modifier = Modifier.height(12.dp))

            // Item 1
            LedgerItem(
                name = "سعود فهد",
                subtitle = "دين نقدي يدوي",
                amount = "+1,200 ر.س",
                amountSub = "مستحق لي",
                amountColor = Color(0xFF2E7D32),
                icon = Icons.Rounded.AttachMoney,
                iconBg = Color(0xFF2E7D32).copy(alpha = 0.1f),
                iconColor = Color(0xFF2E7D32)
            )
            Spacer(modifier = Modifier.height(12.dp))

            // Item 2
            LedgerItem(
                name = "نورة الشمري",
                subtitle = "حوالة Jeeb",
                amount = "-350 ر.س",
                amountSub = "عليّ سدادها",
                amountColor = MaterialTheme.colorScheme.primary,
                icon = Icons.Rounded.Person,
                iconBg = MaterialTheme.colorScheme.surfaceVariant,
                iconColor = MaterialTheme.colorScheme.onSurfaceVariant
            )

            Spacer(modifier = Modifier.height(24.dp))
            Text("أمس، 23 أكتوبر", style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline, modifier = Modifier.padding(horizontal = 4.dp))
            Spacer(modifier = Modifier.height(12.dp))

            // Item 3
            LedgerItem(
                name = "أحمد منصور",
                subtitle = "قطية عشاء - نقد",
                amount = "+85 ر.س",
                amountSub = "تم الاستلام",
                amountColor = Color(0xFF2E7D32),
                icon = Icons.Rounded.Payments,
                iconBg = MaterialTheme.colorScheme.secondaryContainer,
                iconColor = MaterialTheme.colorScheme.secondary,
                isSettled = true
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Settlement Visualization
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f), RoundedCornerShape(16.dp))
                    .border(1.dp, MaterialTheme.colorScheme.outline.copy(alpha = 0.3f), RoundedCornerShape(16.dp))
                    .padding(24.dp),
                contentAlignment = Alignment.Center
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Icon(imageVector = Icons.Rounded.Handshake, contentDescription = null, tint = MaterialTheme.colorScheme.outline, modifier = Modifier.size(36.dp))
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("تسوية سريعة", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        "اسحب معاملة من السجل هنا لإغلاقها أو مطابقتها مع تحويل بنكي",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        textAlign = TextAlign.Center,
                        modifier = Modifier.width(200.dp)
                    )
                    Spacer(modifier = Modifier.height(24.dp))
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(96.dp)
                            .background(MaterialTheme.colorScheme.primary.copy(alpha = 0.05f), RoundedCornerShape(12.dp))
                            .border(2.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.2f), RoundedCornerShape(12.dp)),
                        contentAlignment = Alignment.Center
                    ) {
                        Text("أفلت المعاملة هنا للتسوية", style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.primary.copy(alpha = 0.6f))
                    }
                }
            }

            Spacer(modifier = Modifier.height(100.dp))
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
    icon: androidx.compose.ui.graphics.vector.ImageVector,
    iconBg: Color,
    iconColor: Color,
    isSettled: Boolean = false
) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White, RoundedCornerShape(12.dp))
            .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(12.dp))
            .padding(16.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.SpaceBetween
        ) {
            Row(
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                Box(
                    modifier = Modifier.size(48.dp).background(iconBg, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(imageVector = icon, contentDescription = null, tint = iconColor, modifier = Modifier.size(24.dp))
                }
                Column {
                    Text(name, style = MaterialTheme.typography.labelLarge, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        if (!isSettled && amountColor == MaterialTheme.colorScheme.primary) {
                            Box(modifier = Modifier.size(8.dp).background(MaterialTheme.colorScheme.primary.copy(alpha = 0.4f), CircleShape))
                        }
                        Text(subtitle, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                    }
                }
            }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                Column(horizontalAlignment = Alignment.Start) {
                    Text(amount, style = MaterialTheme.typography.labelLarge, color = amountColor, fontWeight = FontWeight.Bold)
                    Text(amountSub, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.outline)
                }
                if (isSettled) {
                    Icon(imageVector = Icons.Rounded.CheckCircle, contentDescription = null, tint = Color(0xFF2E7D32), modifier = Modifier.size(24.dp))
                } else {
                    Icon(imageVector = Icons.Rounded.DragIndicator, contentDescription = null, tint = MaterialTheme.colorScheme.outline, modifier = Modifier.size(24.dp))
                }
            }
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
