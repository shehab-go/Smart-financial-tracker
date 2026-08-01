package com.shehabgo.smartfinancialtracker.ui.screens.onboarding

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.animation.core.*
import androidx.compose.foundation.layout.*
import androidx.compose.runtime.getValue
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.material3.*
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun WelcomeScreen() {
    Column(
        modifier = Modifier.fillMaxSize(),
        horizontalAlignment = Alignment.CenterHorizontally
    ) {
        Spacer(modifier = Modifier.weight(1f))

        val infiniteTransition = rememberInfiniteTransition(label = "welcome_anim")

        val scale by infiniteTransition.animateFloat(
            initialValue = 0.95f,
            targetValue = 1.05f,
            animationSpec = infiniteRepeatable(
                animation = tween(1500, easing = FastOutSlowInEasing),
                repeatMode = RepeatMode.Reverse
            ),
            label = "scale"
        )

        val rotation by infiniteTransition.animateFloat(
            initialValue = 0f,
            targetValue = 360f,
            animationSpec = infiniteRepeatable(
                animation = tween(8000, easing = LinearEasing),
                repeatMode = RepeatMode.Restart
            ),
            label = "rotation"
        )

        val floatY by infiniteTransition.animateFloat(
            initialValue = -8f,
            targetValue = 8f,
            animationSpec = infiniteRepeatable(
                animation = tween(2000, easing = FastOutSlowInEasing),
                repeatMode = RepeatMode.Reverse
            ),
            label = "float"
        )

        // Center Graphic
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(280.dp),
            contentAlignment = Alignment.Center
        ) {
            // Concentric arcs
            Canvas(
                modifier = Modifier
                    .size(240.dp)
                    .graphicsLayer { rotationZ = rotation }
            ) {
                drawArc(
                    color = Color(0xFFBD001B).copy(alpha = 0.1f),
                    startAngle = 135f,
                    sweepAngle = 270f,
                    useCenter = false,
                    style = Stroke(width = 1.dp.toPx(), cap = StrokeCap.Round)
                )
                drawArc(
                    color = Color(0xFFBD001B).copy(alpha = 0.2f),
                    startAngle = 180f,
                    sweepAngle = 180f,
                    useCenter = false,
                    style = Stroke(width = 1.dp.toPx(), cap = StrokeCap.Round),
                    topLeft = Offset(20.dp.toPx(), 20.dp.toPx()),
                    size = androidx.compose.ui.geometry.Size(200.dp.toPx(), 200.dp.toPx())
                )
            }

            // Main Circle
            Box(
                modifier = Modifier
                    .size(160.dp)
                    .graphicsLayer {
                        scaleX = scale
                        scaleY = scale
                    }
                    .shadow(32.dp, CircleShape, spotColor = Color(0xFFBD001B).copy(alpha = 0.15f))
                    .background(Color.White, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Box(contentAlignment = Alignment.Center) {
                    Icon(
                        imageVector = Icons.Rounded.Visibility,
                        contentDescription = null,
                        tint = Color(0xFFBD001B),
                        modifier = Modifier.size(56.dp)
                    )
                    Box(
                        modifier = Modifier
                            .align(Alignment.BottomStart)
                            .offset(x = (-4).dp, y = 4.dp)
                            .background(Color.White, CircleShape)
                            .padding(2.dp)
                    ) {
                        Icon(
                            imageVector = Icons.Rounded.Lock,
                            contentDescription = null,
                            tint = Color(0xFFBD001B),
                            modifier = Modifier.size(20.dp)
                        )
                    }
                }
            }

            // Floating Icons
            Box(
                modifier = Modifier
                    .align(Alignment.TopStart)
                    .offset(x = 16.dp, y = 16.dp)
                    .offset(y = floatY.dp)
                    .size(48.dp)
                    .shadow(8.dp, RoundedCornerShape(12.dp), spotColor = Color(0xFFBD001B).copy(alpha = 0.1f))
                    .background(Color.White, RoundedCornerShape(12.dp))
                    .border(1.dp, Color(0xFFE7BDB9).copy(alpha = 0.5f), RoundedCornerShape(12.dp)),
                contentAlignment = Alignment.Center
            ) {
                Icon(imageVector = Icons.Rounded.LockOpen, contentDescription = null, tint = Color(0xFFBD001B), modifier = Modifier.size(20.dp))
            }

            Box(
                modifier = Modifier
                    .align(Alignment.BottomEnd)
                    .offset(x = (-16).dp, y = (-16).dp)
                    .offset(y = (-floatY).dp)
                    .size(48.dp)
                    .shadow(8.dp, RoundedCornerShape(12.dp), spotColor = Color(0xFFBD001B).copy(alpha = 0.1f))
                    .background(Color.White, RoundedCornerShape(12.dp))
                    .border(1.dp, Color(0xFFE7BDB9).copy(alpha = 0.5f), RoundedCornerShape(12.dp)),
                contentAlignment = Alignment.Center
            ) {
                Icon(imageVector = Icons.Rounded.AutoGraph, contentDescription = null, tint = Color(0xFFBD001B), modifier = Modifier.size(20.dp))
            }
        }

        Spacer(modifier = Modifier.weight(1f))

        // Title and Subtitle
        Text(
            text = "دعنا ندير ميزانيتك بينما تستمتع بحياتك",
            style = MaterialTheme.typography.headlineMedium.copy(fontSize = 26.sp, fontWeight = FontWeight.Bold, lineHeight = 36.sp),
            color = Color(0xFF141D23),
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(16.dp))
        Text(
            text = "ذكاء اصطناعي مالي يتفهم احتياجاتك ويحترم خصوصيتك بالكامل.",
            style = MaterialTheme.typography.bodyLarge.copy(fontSize = 16.sp, lineHeight = 24.sp),
            color = Color(0xFF5D5E61),
            textAlign = TextAlign.Center,
            modifier = Modifier.padding(horizontal = 24.dp)
        )

        Spacer(modifier = Modifier.height(32.dp))

        // Badges
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.Center,
            verticalAlignment = Alignment.CenterVertically
        ) {
            BadgeItem(icon = Icons.Rounded.GppGood, text = "مشفر بالكامل")
            Spacer(modifier = Modifier.width(12.dp))
            BadgeItem(icon = Icons.Rounded.VerifiedUser, text = "سيادة البيانات")
        }
        
        Spacer(modifier = Modifier.height(16.dp))
    }
}

@Composable
fun BadgeItem(icon: androidx.compose.ui.graphics.vector.ImageVector, text: String) {
    Row(
        modifier = Modifier
            .background(Color.White, RoundedCornerShape(24.dp))
            .border(1.dp, Color(0xFFE7BDB9).copy(alpha = 0.5f), RoundedCornerShape(24.dp))
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        Icon(
            imageVector = icon,
            contentDescription = null,
            tint = Color(0xFFBD001B),
            modifier = Modifier.size(16.dp)
        )
        Text(
            text = text,
            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
            color = Color(0xFF5D5E61)
        )
    }
}
