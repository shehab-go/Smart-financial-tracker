package com.shehabgo.smartfinancialtracker.ui.screens.categories

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
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp


@Composable
fun CategoriesCustomizationScreen() {
    var manualCashEnabled by remember { mutableStateOf(true) }

    Column(
            modifier = Modifier
                .fillMaxSize()
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "تخصيص الفئات الذكية",
                style = MaterialTheme.typography.headlineMedium.copy(fontSize = 26.sp, fontWeight = FontWeight.Bold, lineHeight = 36.sp),
                color = Color(0xFF141D23),
                textAlign = TextAlign.Center
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "صمم هيكلك المالي. اختر وعدل الفئات التي تتناسب مع أسلوب حياتك.",
                style = MaterialTheme.typography.bodyLarge.copy(fontSize = 16.sp, lineHeight = 24.sp),
                color = Color(0xFF5D5E61),
                textAlign = TextAlign.Center,
                modifier = Modifier.padding(horizontal = 24.dp)
            )

            Spacer(modifier = Modifier.height(32.dp))

            // Manual Cash Toggle
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(10.dp, RoundedCornerShape(12.dp), spotColor = Color(0xFFBD001B).copy(alpha = 0.05f))
                    .background(Color.White, RoundedCornerShape(12.dp))
                    .border(1.dp, Color(0xFFE7BDB9).copy(alpha = 0.5f), RoundedCornerShape(12.dp))
                    .padding(24.dp)
            ) {
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Column(modifier = Modifier.weight(1f)) {
                        Text(
                            text = "ميزانية الكاش اليدوية",
                            style = MaterialTheme.typography.titleMedium,
                            color = Color(0xFF141D23),
                            fontWeight = FontWeight.SemiBold
                        )
                        Text(
                            text = "تتبع المصاريف النقدية اليومية بسهولة",
                            style = MaterialTheme.typography.labelMedium,
                            color = Color(0xFF5D5E61)
                        )
                    }
                    Switch(
                        checked = manualCashEnabled,
                        onCheckedChange = { manualCashEnabled = it },
                        colors = SwitchDefaults.colors(
                            checkedThumbColor = Color.White,
                            checkedTrackColor = Color(0xFFBD001B),
                            uncheckedThumbColor = Color.White,
                            uncheckedTrackColor = Color(0xFFD2DBE4)
                        )
                    )
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Category Grid Header
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "فئات المصاريف",
                    style = MaterialTheme.typography.titleMedium,
                    color = Color(0xFF141D23),
                    fontWeight = FontWeight.SemiBold
                )
                TextButton(onClick = { /*TODO*/ }) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        Icon(imageVector = Icons.Rounded.Add, contentDescription = null, modifier = Modifier.size(16.dp), tint = Color(0xFFBD001B))
                        Text("إضافة فئة", style = MaterialTheme.typography.labelLarge, color = Color(0xFFBD001B))
                    }
                }
            }

            Spacer(modifier = Modifier.height(16.dp))

            // Category Grid
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Box(modifier = Modifier.weight(1f)) {
                        CategoryCard("يمن موبايل", "رصيد وباقات", Icons.Rounded.CellTower, false)
                    }
                    Box(modifier = Modifier.weight(1f)) {
                        CategoryCard("مواد غذائية", "سوبر ماركت", Icons.Rounded.ShoppingBasket, false)
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Box(modifier = Modifier.weight(1f)) {
                        CategoryCard("إنترنت منزلي", "ADSL / فيبر", Icons.Rounded.Wifi, false)
                    }
                    Box(modifier = Modifier.weight(1f)) {
                        CategoryCard("قات وديوان", "مجالس محلية", Icons.Rounded.Eco, true)
                    }
                }
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Box(modifier = Modifier.weight(1f)) {
                        CategoryCard("مواصلات", "باصات وتكاسي", Icons.Rounded.LocalTaxi, false)
                    }
                    Box(modifier = Modifier.weight(1f)) {
                        CategoryCard("كهرباء ومياه", "فواتير حكومية", Icons.Rounded.Bolt, false)
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Edit Panel
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(10.dp, RoundedCornerShape(16.dp), spotColor = Color(0xFFBD001B).copy(alpha = 0.05f))
                    .background(Color.White, RoundedCornerShape(16.dp))
                    .border(1.dp, Color(0xFFE7BDB9).copy(alpha = 0.5f), RoundedCornerShape(16.dp))
                    .padding(24.dp)
            ) {
                Column(verticalArrangement = Arrangement.spacedBy(24.dp)) {
                    Row(
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(16.dp)
                    ) {
                        Box(
                            modifier = Modifier
                                .size(64.dp)
                                .shadow(12.dp, RoundedCornerShape(12.dp), spotColor = Color(0xFFBD001B).copy(alpha = 0.2f))
                                .background(Color(0xFFBD001B), RoundedCornerShape(12.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Rounded.Eco,
                                contentDescription = null,
                                tint = Color.White,
                                modifier = Modifier.size(36.dp)
                            )
                        }
                        Column(modifier = Modifier.weight(1f)) {
                            Text(
                                text = "قات وديوان",
                                style = MaterialTheme.typography.headlineSmall,
                                fontWeight = FontWeight.Bold,
                                color = Color(0xFF141D23)
                            )
                            Text(
                                text = "تعديل اسم الفئة",
                                style = MaterialTheme.typography.labelMedium,
                                color = Color(0xFF5D5E61)
                            )
                        }
                    }

                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text(
                                text = "اللون",
                                style = MaterialTheme.typography.labelSmall,
                                color = Color(0xFF5D5E61),
                                fontWeight = FontWeight.Bold
                            )
                            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                                Box(modifier = Modifier
                                    .size(28.dp)
                                    .background(Color(0xFFBD001B), CircleShape)
                                    .border(2.dp, Color(0xFFBD001B).copy(alpha = 0.5f), CircleShape))
                                Box(modifier = Modifier
                                    .size(28.dp)
                                    .background(Color(0xFFF97316), CircleShape))
                                Box(modifier = Modifier
                                    .size(28.dp)
                                    .background(Color(0xFF3B82F6), CircleShape))
                                Box(modifier = Modifier
                                    .size(28.dp)
                                    .background(Color(0xFF10B981), CircleShape))
                            }
                        }
                        Column(
                            verticalArrangement = Arrangement.spacedBy(8.dp),
                            horizontalAlignment = Alignment.End
                        ) {
                            Text(
                                text = "الأيقونة",
                                style = MaterialTheme.typography.labelSmall,
                                color = Color(0xFF5D5E61),
                                fontWeight = FontWeight.Bold
                            )
                            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                                Icon(imageVector = Icons.Rounded.Restaurant, contentDescription = null, tint = Color(0xFF5A5D5F))
                                Icon(imageVector = Icons.Rounded.Home, contentDescription = null, tint = Color(0xFF5A5D5F))
                                Icon(imageVector = Icons.Rounded.Eco, contentDescription = null, tint = Color(0xFFBD001B))
                            }
                        }
                    }
                }
            }
        }
    }

@Composable
fun CategoryCard(title: String, subtitle: String, icon: androidx.compose.ui.graphics.vector.ImageVector, isHighlighted: Boolean) {
    val bgColor = if (isHighlighted) Color(0xFFBD001B).copy(alpha = 0.03f) else Color.White
    val borderColor = if (isHighlighted) Color(0xFFBD001B) else Color(0xFFD2DBE4)
    val iconBgColor = if (isHighlighted) Color(0xFFBD001B) else Color(0xFFBD001B).copy(alpha = 0.1f)
    val iconColor = if (isHighlighted) Color.White else Color(0xFFBD001B)
    val titleColor = Color(0xFF141D23)
    val subtitleColor = if (isHighlighted) Color(0xFFBD001B) else Color(0xFF5D5E61)

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(bgColor, RoundedCornerShape(12.dp))
            .border(1.dp, borderColor, RoundedCornerShape(12.dp))
            .clickable { /*TODO*/ }
            .padding(12.dp)
    ) {
        Column(
            modifier = Modifier.fillMaxWidth(),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            Box(
                modifier = Modifier
                    .size(56.dp)
                    .shadow(if (isHighlighted) 8.dp else 0.dp, CircleShape, spotColor = Color(0xFFBD001B).copy(alpha = 0.2f))
                    .background(iconBgColor, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = icon,
                    contentDescription = null,
                    tint = iconColor,
                    modifier = Modifier.size(32.dp)
                )
            }
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.labelLarge,
                    color = titleColor,
                    fontWeight = if (isHighlighted) FontWeight.Bold else FontWeight.Medium
                )
                Text(
                    text = subtitle,
                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                    color = subtitleColor,
                    fontWeight = FontWeight.SemiBold
                )
            }
        }
    }
}
