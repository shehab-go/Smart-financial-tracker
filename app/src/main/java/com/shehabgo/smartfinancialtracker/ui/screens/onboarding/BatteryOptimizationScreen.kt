package com.shehabgo.smartfinancialtracker.ui.screens.onboarding

import android.provider.Settings
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.BatteryFull
import androidx.compose.material.icons.rounded.CheckCircle
import androidx.compose.material.icons.rounded.Security
import androidx.compose.material.icons.rounded.Settings
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.animation.core.*
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun BatteryOptimizationScreen(
    hasPermission: Boolean = false,
    onOpenSettings: () -> Unit = {}
) {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        // Title and Subtitle at the Top
        Text(
            text = "استمرارية المستشار الذكي",
            style = MaterialTheme.typography.headlineMedium.copy(fontSize = 26.sp, fontWeight = FontWeight.Bold, lineHeight = 36.sp),
            color = Color(0xFF141D23),
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "لضمان عمل التطبيق في الخلفية دون توقف، يرجى استثناء 'CapitalCore' من تحسين البطارية.",
            style = MaterialTheme.typography.bodyLarge.copy(fontSize = 15.sp, lineHeight = 24.sp),
            color = Color(0xFF5D5E61),
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 24.dp)
        )
        
        Spacer(modifier = Modifier.weight(1f))

        val infiniteTransition = rememberInfiniteTransition(label = "battery_anim")

        val shieldScale by infiniteTransition.animateFloat(
            initialValue = 0.95f,
            targetValue = 1.05f,
            animationSpec = infiniteRepeatable(
                animation = tween(2500, easing = FastOutSlowInEasing),
                repeatMode = RepeatMode.Reverse
            ),
            label = "shieldScale"
        )

        val activeItemScale by infiniteTransition.animateFloat(
            initialValue = 0.98f,
            targetValue = 1.02f,
            animationSpec = infiniteRepeatable(
                animation = tween(1200, easing = FastOutSlowInEasing),
                repeatMode = RepeatMode.Reverse
            ),
            label = "activeItemScale"
        )

        val badgeFloat by infiniteTransition.animateFloat(
            initialValue = -6f,
            targetValue = 6f,
            animationSpec = infiniteRepeatable(
                animation = tween(2000, easing = FastOutSlowInEasing),
                repeatMode = RepeatMode.Reverse
            ),
            label = "badgeFloat"
        )

        // Center Graphic Mockup
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .aspectRatio(0.85f)
                .background(Color.White.copy(alpha = 0.5f), RoundedCornerShape(24.dp)),
            contentAlignment = Alignment.Center
        ) {
            // Outer device mockup
            Box(
                modifier = Modifier
                    .fillMaxHeight()
                    .fillMaxWidth(0.8f)
                    .background(Color.White, RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 0.dp, bottomEnd = 0.dp))
                    .border(1.dp, Color(0xFFE0E9F2), RoundedCornerShape(topStart = 24.dp, topEnd = 24.dp, bottomStart = 0.dp, bottomEnd = 0.dp))
                    .padding(top = 24.dp, start = 16.dp, end = 16.dp),
                contentAlignment = Alignment.TopCenter
            ) {
                // Background Icon
                Icon(
                    imageVector = Icons.Rounded.BatteryFull,
                    contentDescription = null,
                    tint = Color(0xFFF6FAFF),
                    modifier = Modifier
                        .align(Alignment.BottomCenter)
                        .size(160.dp)
                        .graphicsLayer {
                            scaleX = shieldScale
                            scaleY = shieldScale
                        }
                        .offset(y = 40.dp)
                )

                Column(verticalArrangement = Arrangement.spacedBy(16.dp)) {
                    // Mock Item 1 (Faded)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color(0xFFF6FAFF), RoundedCornerShape(12.dp))
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Box(
                            modifier = Modifier
                                .size(32.dp)
                                .background(Color(0xFFE0E9F2), RoundedCornerShape(8.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(imageVector = Icons.Rounded.Security, contentDescription = null, tint = Color(0xFFD2DBE4), modifier = Modifier.size(16.dp))
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Box(modifier = Modifier.width(60.dp).height(6.dp).background(Color(0xFFD2DBE4), RoundedCornerShape(3.dp)))
                            Spacer(modifier = Modifier.height(6.dp))
                            Box(modifier = Modifier.width(100.dp).height(4.dp).background(Color(0xFFE0E9F2), RoundedCornerShape(2.dp)))
                        }
                    }

                    // Mock Item 2 (Active highlighted)
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .graphicsLayer {
                                scaleX = activeItemScale
                                scaleY = activeItemScale
                            }
                            .shadow(8.dp, RoundedCornerShape(16.dp), spotColor = Color(0xFFBD001B).copy(alpha = 0.1f))
                            .background(Color.White, RoundedCornerShape(16.dp))
                            .border(2.dp, Color(0xFFE7BDB9), RoundedCornerShape(16.dp))
                            .padding(16.dp)
                    ) {
                        Column {
                            Row(
                                modifier = Modifier.fillMaxWidth(),
                                horizontalArrangement = Arrangement.SpaceBetween,
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Icon(imageVector = Icons.Rounded.BatteryFull, contentDescription = null, tint = Color(0xFFBD001B), modifier = Modifier.size(20.dp))
                                Text(
                                    text = "استثناء البطارية",
                                    style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                                    color = Color(0xFF141D23)
                                )
                                // Red Toggle Switch Mockup
                                Box(
                                    modifier = Modifier
                                        .width(36.dp)
                                        .height(20.dp)
                                        .background(Color(0xFFBD001B), RoundedCornerShape(10.dp))
                                        .padding(2.dp),
                                    contentAlignment = Alignment.CenterStart
                                ) {
                                    Box(modifier = Modifier.size(16.dp).background(Color.White, CircleShape))
                                }
                            }
                            Spacer(modifier = Modifier.height(16.dp))
                            Box(modifier = Modifier.fillMaxWidth().height(4.dp).background(Color(0xFFE0E9F2), RoundedCornerShape(2.dp)))
                            Spacer(modifier = Modifier.height(4.dp))
                            Box(modifier = Modifier.width(80.dp).height(4.dp).background(Color(0xFFF6FAFF), RoundedCornerShape(2.dp)))
                        }
                    }

                    // Mock Item 3 (Faded)
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .background(Color(0xFFF6FAFF), RoundedCornerShape(12.dp))
                            .padding(12.dp),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.SpaceBetween
                    ) {
                        Box(
                            modifier = Modifier
                                .size(32.dp)
                                .background(Color(0xFFE0E9F2), RoundedCornerShape(8.dp)),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(imageVector = Icons.Rounded.CheckCircle, contentDescription = null, tint = Color(0xFFD2DBE4), modifier = Modifier.size(16.dp))
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Box(modifier = Modifier.width(60.dp).height(6.dp).background(Color(0xFFD2DBE4), RoundedCornerShape(3.dp)))
                            Spacer(modifier = Modifier.height(6.dp))
                            Box(modifier = Modifier.width(100.dp).height(4.dp).background(Color(0xFFE0E9F2), RoundedCornerShape(2.dp)))
                        }
                    }
                }
            }

            // Status Badge Overlay
            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .offset(x = (-8).dp, y = (-24).dp)
                    .offset(y = badgeFloat.dp)
                    .shadow(16.dp, RoundedCornerShape(16.dp), spotColor = Color(0xFFBD001B).copy(alpha = 0.15f))
                    .background(Color.White, RoundedCornerShape(16.dp))
                    .border(1.dp, Color(0xFFE7BDB9).copy(alpha = 0.3f), RoundedCornerShape(16.dp))
                    .padding(horizontal = 16.dp, vertical = 12.dp)
            ) {
                Row(
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    Box(
                        modifier = Modifier
                            .size(24.dp)
                            .background(Color(0xFFBD001B), CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(imageVector = Icons.Rounded.CheckCircle, contentDescription = null, tint = Color.White, modifier = Modifier.size(16.dp))
                    }
                    Text(
                        text = "نشاط دائم",
                        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                        color = Color(0xFF141D23)
                    )
                }
            }
        }

        if (!hasPermission) {
            Spacer(modifier = Modifier.height(32.dp))

            Button(
                onClick = onOpenSettings,
                modifier = Modifier.height(48.dp),
                shape = RoundedCornerShape(24.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = Color(0xFFBD001B).copy(alpha = 0.1f),
                    contentColor = Color(0xFFBD001B)
                ),
                elevation = null
            ) {
                Icon(imageVector = Icons.Rounded.Settings, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("فتح إعدادات البطارية", style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold))
            }
        }

        Spacer(modifier = Modifier.weight(1f))
    }
}
