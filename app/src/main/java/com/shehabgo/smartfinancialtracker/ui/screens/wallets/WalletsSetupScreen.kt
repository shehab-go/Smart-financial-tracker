package com.shehabgo.smartfinancialtracker.ui.screens.wallets

import androidx.compose.animation.animateColorAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp


@Composable
fun WalletsSetupScreen(
    onJeebSelected: (Boolean) -> Unit = {}
) {
    var isJeebSelected by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        LazyColumn(
            verticalArrangement = Arrangement.spacedBy(16.dp),
            contentPadding = PaddingValues(bottom = 32.dp),
            modifier = Modifier.fillMaxSize()
        ) {
            item {
                Column(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalAlignment = Alignment.CenterHorizontally
                ) {
                    Text(
                        text = "اختر محفظتك الذكية",
                        style = MaterialTheme.typography.headlineMedium.copy(fontSize = 26.sp, fontWeight = FontWeight.Bold, lineHeight = 36.sp),
                        color = Color(0xFF141D23),
                        textAlign = TextAlign.Center
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "محفظة جيب مدعومة بالكامل بالأتمتة الصامتة لإدارة أصولك بدقة متناهية.",
                        style = MaterialTheme.typography.bodyLarge.copy(fontSize = 16.sp, lineHeight = 24.sp),
                        color = Color(0xFF5D5E61),
                        textAlign = TextAlign.Center,
                        modifier = Modifier.padding(horizontal = 24.dp)
                    )
                    Spacer(modifier = Modifier.height(32.dp))
                }
            }
            item {
                WalletCardJeeb(
                    isSelected = isJeebSelected,
                    onClick = {
                        isJeebSelected = !isJeebSelected
                        onJeebSelected(isJeebSelected)
                    }
                )
            }
            item {
                WalletCardPending("الكريمي", "تحت الدمج التقني", Icons.Rounded.AccountBalance, 0.15f)
            }
            item {
                WalletCardPending("جوالي", "مرحلة الاختبار", Icons.Rounded.Smartphone, 0.05f)
            }
            item {
                WalletCardPending("فلوس", "تحديث الأنظمة", Icons.Rounded.Payments, 0f)
            }
            item {
                WalletCardPending("بلس", "جدولة الربط", Icons.Rounded.AddCard, 0f)
            }
            item {
                // Add new method card
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .height(140.dp)
                        .background(Color.White.copy(alpha = 0.4f), RoundedCornerShape(12.dp))
                        .border(2.dp, MaterialTheme.colorScheme.secondaryContainer, RoundedCornerShape(12.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Column(horizontalAlignment = Alignment.CenterHorizontally) {
                        Icon(
                            imageVector = Icons.Rounded.Add,
                            contentDescription = null,
                            tint = MaterialTheme.colorScheme.tertiary,
                            modifier = Modifier.size(36.dp)
                        )
                        Spacer(modifier = Modifier.height(8.dp))
                        Text(
                            text = "إضافة محفظة أخرى",
                            style = MaterialTheme.typography.labelLarge,
                            color = MaterialTheme.colorScheme.tertiary
                        )
                    }
                }
            }
        }
    }
}

@Composable
fun WalletCardJeeb(
    isSelected: Boolean,
    onClick: () -> Unit
) {
    val borderColor by animateColorAsState(
        targetValue = if (isSelected) Color(0xFFBD001B) else Color(0xFFE0E9F2),
        animationSpec = tween(300),
        label = "borderColor"
    )
    val shadowElevation = if (isSelected) 12.dp else 2.dp

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(shadowElevation, RoundedCornerShape(12.dp), spotColor = Color(0xFFBD001B).copy(alpha = 0.15f))
            .background(Color.White, RoundedCornerShape(12.dp))
            .border(2.dp, borderColor, RoundedCornerShape(12.dp))
            .clickable { onClick() }
            .padding(24.dp)
    ) {
        // Badge
        if (isSelected) {
            Row(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .background(Color(0xFFBD001B), RoundedCornerShape(12.dp))
                    .padding(horizontal = 10.dp, vertical = 2.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(4.dp)
            ) {
                Icon(
                    imageVector = Icons.Rounded.CheckCircle,
                    contentDescription = null,
                    tint = Color.White,
                    modifier = Modifier.size(14.dp)
                )
                Text(
                    text = "نشط",
                    style = MaterialTheme.typography.labelSmall,
                    color = Color.White
                )
            }
        }

        val iconTint by animateColorAsState(
            targetValue = if (isSelected) Color(0xFFBD001B) else Color(0xFFB0B8C1),
            animationSpec = tween(300),
            label = "iconTint"
        )
        val iconBg by animateColorAsState(
            targetValue = if (isSelected) Color(0xFFBD001B).copy(alpha = 0.1f) else Color(0xFFF0F2F5),
            animationSpec = tween(300),
            label = "iconBg"
        )
        val nameColor by animateColorAsState(
            targetValue = if (isSelected) Color(0xFFBD001B) else Color(0xFF5D5E61),
            animationSpec = tween(300),
            label = "nameColor"
        )
        val progressColor by animateColorAsState(
            targetValue = if (isSelected) Color(0xFFBD001B) else Color(0xFFD2DBE4),
            animationSpec = tween(300),
            label = "progressColor"
        )

        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(iconBg, RoundedCornerShape(16.dp))
                    .padding(2.dp)
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.White, RoundedCornerShape(14.dp)),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Rounded.AccountBalanceWallet,
                        contentDescription = null,
                        tint = iconTint,
                        modifier = Modifier.size(36.dp)
                    )
                }
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = "Jeeb - جيب",
                    style = MaterialTheme.typography.headlineMedium.copy(fontSize = 20.sp),
                    color = nameColor
                )
                Text(
                    text = "جاهز بنسبة 100%",
                    style = MaterialTheme.typography.labelLarge,
                    color = Color(0xFF5D5E61)
                )
            }

            // Progress bar
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .background(Color(0xFFBD001B).copy(alpha = 0.1f), RoundedCornerShape(4.dp))
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth()
                        .fillMaxHeight()
                        .background(progressColor, RoundedCornerShape(4.dp))
                )
            }
        }
    }
}

@Composable
fun WalletCardPending(title: String, subtitle: String, icon: androidx.compose.ui.graphics.vector.ImageVector, progress: Float) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(Color.White, RoundedCornerShape(12.dp))
            .border(1.dp, MaterialTheme.colorScheme.secondaryFixed, RoundedCornerShape(12.dp))
            .padding(24.dp)
    ) {
        // Pending Badge
        Box(
            modifier = Modifier
                .align(Alignment.TopEnd)
                .background(MaterialTheme.colorScheme.surfaceContainerHigh, RoundedCornerShape(12.dp))
                .border(1.dp, MaterialTheme.colorScheme.secondaryContainer, RoundedCornerShape(12.dp))
                .padding(horizontal = 10.dp, vertical = 2.dp),
            contentAlignment = Alignment.Center
        ) {
            Text(
                text = "قريباً",
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.secondary
            )
        }

        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(80.dp)
                    .background(MaterialTheme.colorScheme.surfaceContainer, RoundedCornerShape(16.dp)),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.tertiary,
                    modifier = Modifier.size(36.dp)
                )
            }

            Column(horizontalAlignment = Alignment.CenterHorizontally) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.headlineMedium.copy(fontSize = 20.sp),
                    color = MaterialTheme.colorScheme.onSurface
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.labelLarge,
                    color = MaterialTheme.colorScheme.tertiary
                )
            }

            // Progress bar
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .background(MaterialTheme.colorScheme.surfaceContainer, RoundedCornerShape(4.dp))
            ) {
                Box(
                    modifier = Modifier
                        .fillMaxWidth(progress)
                        .fillMaxHeight()
                        .background(MaterialTheme.colorScheme.tertiary, RoundedCornerShape(4.dp))
                )
            }
        }
    }
}
