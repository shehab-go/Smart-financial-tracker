package com.shehabgo.smartfinancialtracker.ui.screens.splash

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.AutoGraph
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.*
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.drawscope.rotate
import androidx.compose.ui.graphics.drawscope.withTransform
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlin.math.*

@Composable
fun SplashScreen(
    onNavigate: (String) -> Unit,
    isOnboardingDone: Boolean
) {
    val Brand   = Color(0xFFBD001B)
    val BgColor = Color(0xFFF6FAFF)

    // ── مراحل الظهور ─────────────────────────────────────────
    var phase1 by remember { mutableStateOf(false) } // حلقات الانفجار
    var phase2 by remember { mutableStateOf(false) } // الشعار
    var phase3 by remember { mutableStateOf(false) } // خط المسح
    var phase4 by remember { mutableStateOf(false) } // الاسم
    var phase5 by remember { mutableStateOf(false) } // الوصف + شريط
    var phase6 by remember { mutableStateOf(false) } // خروج

    LaunchedEffect(Unit) {
        delay(80);   phase1 = true
        delay(350);  phase2 = true
        delay(500);  phase3 = true
        delay(550);  phase4 = true
        delay(450);  phase5 = true
        delay(1100); phase6 = true
        delay(350)
        if (isOnboardingDone) onNavigate("dashboard")
        else                  onNavigate("onboarding_pager")
    }

    // ── أنيميشن الشعار: Spring Scale ─────────────────────────
    val logoScale by animateFloatAsState(
        targetValue   = if (phase2) 1f else 0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioLowBouncy,
            stiffness    = Spring.StiffnessMediumLow
        ),
        label = "logoScale"
    )
    val logoAlpha by animateFloatAsState(
        targetValue   = if (phase2) 1f else 0f,
        animationSpec = tween(400),
        label = "logoAlpha"
    )

    // ── حلقات الانفجار (ring expand) ─────────────────────────
    val ring1Radius by animateFloatAsState(
        targetValue   = if (phase1) 1f else 0f,
        animationSpec = tween(800, easing = FastOutSlowInEasing),
        label = "ring1"
    )
    val ring2Radius by animateFloatAsState(
        targetValue   = if (phase1) 1f else 0f,
        animationSpec = tween(1000, delayMillis = 100, easing = FastOutSlowInEasing),
        label = "ring2"
    )
    val ring3Radius by animateFloatAsState(
        targetValue   = if (phase1) 1f else 0f,
        animationSpec = tween(1200, delayMillis = 200, easing = FastOutSlowInEasing),
        label = "ring3"
    )
    val ringsAlpha by animateFloatAsState(
        targetValue   = if (phase1) 1f else 0f,
        animationSpec = tween(600),
        label = "ringsAlpha"
    )

    // ── خط المسح (Scanner Line) ──────────────────────────────
    val scanLine by animateFloatAsState(
        targetValue   = if (phase3) 1f else 0f,
        animationSpec = tween(700, easing = FastOutSlowInEasing),
        label = "scanLine"
    )

    // ── شريط التقدم ───────────────────────────────────────────
    val progressValue by animateFloatAsState(
        targetValue   = if (phase6) 1f else if (phase5) 0.85f else 0f,
        animationSpec = tween(if (phase6) 350 else 1200, easing = FastOutSlowInEasing),
        label = "progress"
    )

    // ── خروج الشاشة ───────────────────────────────────────────
    val exitScale by animateFloatAsState(
        targetValue   = if (phase6) 1.05f else 1f,
        animationSpec = tween(350, easing = FastOutSlowInEasing),
        label = "exitScale"
    )
    val exitAlpha by animateFloatAsState(
        targetValue   = if (phase6) 0f else 1f,
        animationSpec = tween(350),
        label = "exitAlpha"
    )

    // ── أنيميشن دوران لا نهائي ────────────────────────────────
    val infiniteTransition = rememberInfiniteTransition(label = "inf")

    val arc1Rot by infiniteTransition.animateFloat(
        initialValue  = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(5000, easing = LinearEasing)),
        label = "arc1"
    )
    val arc2Rot by infiniteTransition.animateFloat(
        initialValue  = 360f, targetValue = 0f,
        animationSpec = infiniteRepeatable(tween(8000, easing = LinearEasing)),
        label = "arc2"
    )
    val glowPulse by infiniteTransition.animateFloat(
        initialValue  = 0.04f, targetValue = 0.14f,
        animationSpec = infiniteRepeatable(
            tween(1600, easing = FastOutSlowInEasing), RepeatMode.Reverse
        ),
        label = "glow"
    )
    // جسيمات دوّارة (8 نقاط بمدارات مختلفة)
    val particleAngle by infiniteTransition.animateFloat(
        initialValue  = 0f, targetValue = 360f,
        animationSpec = infiniteRepeatable(tween(4000, easing = LinearEasing)),
        label = "particles"
    )
    val shimmer by infiniteTransition.animateFloat(
        initialValue  = -1f, targetValue = 2f,
        animationSpec = infiniteRepeatable(tween(2000, easing = LinearEasing)),
        label = "shimmer"
    )

    // ── الواجهة ───────────────────────────────────────────────
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(BgColor)
            .graphicsLayer {
                scaleX = exitScale; scaleY = exitScale; alpha = exitAlpha
            },
        contentAlignment = Alignment.Center
    ) {

        // ═══ قسم الشعار ══════════════════════════════════════
        Column(
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center,
            modifier = Modifier.fillMaxWidth()
        ) {

            Box(
                modifier = Modifier.size(240.dp),
                contentAlignment = Alignment.Center
            ) {

                // ── حلقات الانفجار ───────────────────────────
                Canvas(modifier = Modifier.fillMaxSize()) {
                    val cx = size.width / 2f
                    val cy = size.height / 2f
                    val maxR = size.minDimension / 2f

                    listOf(
                        Triple(ring1Radius, 0.95f, 0.06f),
                        Triple(ring2Radius, 0.75f, 0.10f),
                        Triple(ring3Radius, 0.55f, 0.08f)
                    ).forEach { (radius, radiusFrac, alphaVal) ->
                        drawCircle(
                            color  = Brand.copy(alpha = alphaVal * ringsAlpha * (1f - radius * 0.5f)),
                            radius = maxR * radiusFrac + maxR * 0.4f * radius,
                            center = Offset(cx, cy),
                            style  = Stroke(width = (2f - radius * 1.5f).coerceAtLeast(0.3f).dp.toPx())
                        )
                    }
                }

                // ── أقواس دوّارة + جسيمات ────────────────────
                Canvas(
                    modifier = Modifier
                        .fillMaxSize()
                        .graphicsLayer { alpha = logoAlpha }
                ) {
                    val cx = size.width / 2f
                    val cy = size.height / 2f
                    val r  = size.minDimension / 2f

                    // قوس ١ (خارجي)
                    rotate(arc1Rot, pivot = Offset(cx, cy)) {
                        drawArc(
                            brush     = Brush.sweepGradient(
                                listOf(Brand.copy(alpha = 0f), Brand.copy(alpha = 0.35f), Brand.copy(alpha = 0f)),
                                center = Offset(cx, cy)
                            ),
                            startAngle = 0f, sweepAngle = 200f, useCenter = false,
                            topLeft = Offset(4.dp.toPx(), 4.dp.toPx()),
                            size    = Size(size.width - 8.dp.toPx(), size.height - 8.dp.toPx()),
                            style   = Stroke(width = 2.5.dp.toPx(), cap = StrokeCap.Round)
                        )
                    }

                    // قوس ٢ (داخلي)
                    rotate(arc2Rot, pivot = Offset(cx, cy)) {
                        val p = 24.dp.toPx()
                        drawArc(
                            brush     = Brush.sweepGradient(
                                listOf(Brand.copy(alpha = 0f), Brand.copy(alpha = 0.2f), Brand.copy(alpha = 0f)),
                                center = Offset(cx, cy)
                            ),
                            startAngle = 0f, sweepAngle = 120f, useCenter = false,
                            topLeft = Offset(p, p),
                            size    = Size(size.width - p * 2, size.height - p * 2),
                            style   = Stroke(width = 1.5.dp.toPx(), cap = StrokeCap.Round)
                        )
                    }

                    // 8 جسيمات دوّارة
                    val orbits = listOf(
                        Triple(r * 0.88f, particleAngle,          5.dp.toPx()),
                        Triple(r * 0.88f, particleAngle + 45f,    3.dp.toPx()),
                        Triple(r * 0.88f, particleAngle + 135f,   4.dp.toPx()),
                        Triple(r * 0.88f, particleAngle + 225f,   3.dp.toPx()),
                        Triple(r * 0.72f, particleAngle * 1.5f,   4.dp.toPx()),
                        Triple(r * 0.72f, particleAngle * 1.5f + 180f, 3.dp.toPx()),
                        Triple(r * 0.60f, -particleAngle * 2f,    3.dp.toPx()),
                        Triple(r * 0.60f, -particleAngle * 2f + 90f,  2.5.dp.toPx()),
                    )
                    orbits.forEachIndexed { i, (orbit, angle, dotR) ->
                        val rad = Math.toRadians(angle.toDouble())
                        val px  = cx + orbit * cos(rad).toFloat()
                        val py  = cy + orbit * sin(rad).toFloat()
                        val a   = if (i % 2 == 0) 0.7f else 0.4f
                        drawCircle(
                            color  = Brand.copy(alpha = a),
                            radius = dotR,
                            center = Offset(px, py)
                        )
                    }
                }

                // ── Glow خلفي ────────────────────────────────
                Box(
                    modifier = Modifier
                        .size(140.dp)
                        .graphicsLayer { alpha = logoAlpha }
                        .clip(CircleShape)
                        .background(Brand.copy(alpha = glowPulse), CircleShape)
                )

                // ── الدائرة الرئيسية ─────────────────────────
                Box(
                    modifier = Modifier
                        .size(110.dp)
                        .graphicsLayer {
                            scaleX = logoScale; scaleY = logoScale; alpha = logoAlpha
                        }
                        .background(Color.White, CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    // Shimmer على الدائرة
                    Box(
                        modifier = Modifier
                            .fillMaxSize()
                            .clip(CircleShape)
                    ) {
                        Canvas(modifier = Modifier.fillMaxSize()) {
                            drawRect(
                                brush = Brush.linearGradient(
                                    colors = listOf(
                                        Color.Transparent,
                                        Color.White.copy(alpha = 0.5f),
                                        Color.Transparent
                                    ),
                                    start = Offset(size.width * (shimmer - 0.5f), 0f),
                                    end   = Offset(size.width * (shimmer + 0.5f), size.height)
                                )
                            )
                        }
                    }
                    Icon(
                        imageVector = Icons.Rounded.AutoGraph,
                        contentDescription = null,
                        tint = Brand,
                        modifier = Modifier.size(52.dp)
                    )
                }

                // ── خط المسح (Scanner) ───────────────────────
                if (phase3 && scanLine < 1f) {
                    Canvas(modifier = Modifier.fillMaxSize()) {
                        val cx = size.width / 2f
                        val cy = size.height / 2f
                        val y  = size.height * scanLine
                        drawLine(
                            brush = Brush.horizontalGradient(
                                colors = listOf(
                                    Color.Transparent,
                                    Brand.copy(alpha = 0.6f),
                                    Brand.copy(alpha = 0.9f),
                                    Brand.copy(alpha = 0.6f),
                                    Color.Transparent
                                )
                            ),
                            start       = Offset(0f, y),
                            end         = Offset(size.width, y),
                            strokeWidth = 2.dp.toPx()
                        )
                        // هالة دائرية تحت الخط (بدلاً من المستطيل)
                        drawCircle(
                            brush  = Brush.radialGradient(
                                colors = listOf(Brand.copy(alpha = 0.10f), Color.Transparent),
                                center = Offset(cx, y),
                                radius = 60.dp.toPx()
                            ),
                            radius = 60.dp.toPx(),
                            center = Offset(cx, y)
                        )
                    }
                }
            }

            Spacer(modifier = Modifier.height(44.dp))

            // ═══ اسم التطبيق ══════════════════════════════════
            AnimatedVisibility(
                visible = phase4,
                enter   = slideInVertically(
                    initialOffsetY = { it },
                    animationSpec  = spring(
                        dampingRatio = Spring.DampingRatioMediumBouncy,
                        stiffness    = Spring.StiffnessMedium
                    )
                ) + fadeIn(tween(400))
            ) {
                Column(horizontalAlignment = Alignment.CenterHorizontally) {
                    Text(
                        text  = "المتتبع المالي الذكي",
                        style = MaterialTheme.typography.headlineLarge.copy(
                            fontWeight   = FontWeight.ExtraBold,
                            fontSize     = 28.sp,
                            lineHeight   = 38.sp,
                            letterSpacing = 0.sp
                        ),
                        color     = Color(0xFF141D23),
                        textAlign = TextAlign.Center
                    )
                }
            }

            Spacer(modifier = Modifier.height(10.dp))

            // ═══ الوصف ════════════════════════════════════════
            AnimatedVisibility(
                visible = phase5,
                enter   = slideInVertically(
                    initialOffsetY = { it / 2 },
                    animationSpec  = tween(500, easing = FastOutSlowInEasing)
                ) + fadeIn(tween(500))
            ) {
                Text(
                    text  = "ذكاء مالي يحترم خصوصيتك",
                    style = MaterialTheme.typography.bodyLarge.copy(
                        fontSize     = 15.sp,
                        letterSpacing = 0.3.sp
                    ),
                    color = Color(0xFF5D5E61),
                    textAlign = TextAlign.Center
                )
            }

            Spacer(modifier = Modifier.height(52.dp))

            // ═══ شريط التقدم ══════════════════════════════════
            AnimatedVisibility(
                visible = phase5,
                enter   = fadeIn(tween(600))
            ) {
                Column(
                    horizontalAlignment = Alignment.CenterHorizontally,
                    modifier = Modifier.padding(horizontal = 64.dp)
                ) {
                    // الشريط
                    Box(
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(3.dp)
                            .background(Brand.copy(alpha = 0.12f), RoundedCornerShape(2.dp))
                    ) {
                        Box(
                            modifier = Modifier
                                .fillMaxWidth(progressValue)
                                .fillMaxHeight()
                                .background(
                                    brush = Brush.horizontalGradient(
                                        colors = listOf(
                                            Brand.copy(alpha = 0.7f),
                                            Brand
                                        )
                                    ),
                                    shape = RoundedCornerShape(2.dp)
                                )
                        ) {
                            // نقطة متوهجة في نهاية الشريط
                            Box(
                                modifier = Modifier
                                    .size(8.dp)
                                    .align(Alignment.CenterEnd)
                                    .offset(x = 4.dp)
                                    .background(Brand, CircleShape)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(20.dp))

                    // نسبة %
                    Text(
                        text  = "${(progressValue * 100).toInt()}%",
                        style = MaterialTheme.typography.labelMedium.copy(
                            fontWeight = FontWeight.Bold,
                            fontSize   = 12.sp
                        ),
                        color = Brand.copy(alpha = 0.7f)
                    )
                }
            }
        }
    }
}
