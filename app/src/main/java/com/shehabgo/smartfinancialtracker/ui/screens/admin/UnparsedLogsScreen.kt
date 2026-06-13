package com.shehabgo.smartfinancialtracker.ui.screens.admin

import androidx.compose.animation.core.*
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun UnparsedLogsScreen(
    onNavigateToDashboard: () -> Unit = {},
    onNavigateToLedger: () -> Unit = {},
    viewModel: UnparsedLogsViewModel = androidx.lifecycle.viewmodel.compose.viewModel()
) {
    val context = androidx.compose.ui.platform.LocalContext.current
    val logs by viewModel.logs.collectAsState()
    val isReprocessing by viewModel.isReprocessing.collectAsState()
    
    var reprocessProgress by remember { mutableStateOf(0f) }
    var reprocessCompleted by remember { mutableStateOf(false) }
    val coroutineScope = rememberCoroutineScope()

    androidx.lifecycle.compose.LifecycleEventEffect(androidx.lifecycle.Lifecycle.Event.ON_RESUME) {
        viewModel.loadLogs(context)
    }

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
                                .background(MaterialTheme.colorScheme.primaryContainer),
                            contentAlignment = Alignment.Center
                        ) {
                            Icon(
                                imageVector = Icons.Rounded.Person,
                                contentDescription = "Admin Profile",
                                tint = MaterialTheme.colorScheme.onPrimaryContainer
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
                    Text(
                        text = "المسؤول",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary,
                        modifier = Modifier
                            .padding(end = 16.dp)
                            .background(MaterialTheme.colorScheme.primaryContainer, RoundedCornerShape(16.dp))
                            .padding(horizontal = 12.dp, vertical = 4.dp)
                    )
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.9f)
                ),
                modifier = Modifier.shadow(1.dp)
            )
        },
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

            // Dashboard Header
            Text("مركز الإدارة والمرونة", style = MaterialTheme.typography.headlineLarge, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
            Spacer(modifier = Modifier.height(8.dp))
            Text("مراقبة سلامة البيانات ومعالجة الحالات الاستثنائية لضمان الدقة المالية.", style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurfaceVariant)

            Spacer(modifier = Modifier.height(24.dp))

            // Unprocessed Logs Section
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(4.dp, RoundedCornerShape(16.dp), spotColor = Color.Black.copy(alpha = 0.05f))
                    .background(Color.White, RoundedCornerShape(16.dp))
                    .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(16.dp))
                    .padding(24.dp)
            ) {
                Column {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                            Icon(imageVector = Icons.Rounded.Report, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
                            Text("إشعارات غير معالجة", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
                        }
                        if (logs.isNotEmpty()) {
                            Text(
                                text = "${logs.size} سجلات",
                                style = MaterialTheme.typography.labelSmall,
                                color = MaterialTheme.colorScheme.error,
                                fontWeight = FontWeight.Bold,
                                modifier = Modifier.background(MaterialTheme.colorScheme.errorContainer, RoundedCornerShape(12.dp)).padding(horizontal = 12.dp, vertical = 4.dp)
                            )
                        }
                    }

                    Spacer(modifier = Modifier.height(16.dp))

                    if (logs.isEmpty()) {
                        Text(
                            text = "جميع الإشعارات معالجة ومطابقة بنجاح.",
                            style = MaterialTheme.typography.bodyMedium,
                            color = MaterialTheme.colorScheme.primary,
                            modifier = Modifier.padding(vertical = 16.dp)
                        )
                    } else {
                        logs.take(5).forEach { log ->
                            LogItem(
                                icon = Icons.Rounded.Report,
                                title = log.packageName,
                                subtitle = log.text.take(40) + "...",
                                time = java.text.SimpleDateFormat("dd/MM HH:mm", java.util.Locale.US).format(java.util.Date(log.timestamp)),
                                status = "غير معالج"
                            )
                            Spacer(modifier = Modifier.height(12.dp))
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))
                    Button(
                        onClick = { /*TODO*/ },
                        modifier = Modifier.fillMaxWidth().height(48.dp),
                        colors = ButtonDefaults.buttonColors(containerColor = Color.Transparent, contentColor = MaterialTheme.colorScheme.primary),
                        shape = RoundedCornerShape(12.dp),
                        border = androidx.compose.foundation.BorderStroke(1.dp, MaterialTheme.colorScheme.primary.copy(alpha = 0.4f))
                    ) {
                        Text("عرض جميع السجلات الفاشلة", style = MaterialTheme.typography.labelLarge, fontWeight = FontWeight.Bold)
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Export Tools
            Row(horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                ExportToolCard(
                    modifier = Modifier.weight(1f),
                    icon = Icons.Rounded.FileDownload,
                    title = "تصدير البيانات",
                    subtitle = "تنسيق CSV مشفر AES-256",
                    actionText = "بدء التصدير"
                )
                ExportToolCard(
                    modifier = Modifier.weight(1f),
                    icon = Icons.Rounded.CloudUpload,
                    title = "نسخ احتياطي للسحابة",
                    subtitle = "تخزين آمن في خوادم مشفرة",
                    actionText = "تفعيل المزامنة"
                )
            }

            Spacer(modifier = Modifier.height(24.dp))

            // Reprocess Section
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(4.dp, RoundedCornerShape(16.dp), spotColor = Color.Black.copy(alpha = 0.05f))
                    .background(Color.White, RoundedCornerShape(16.dp))
                    .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(16.dp))
                    .padding(24.dp)
            ) {
                // Top Border
                Box(modifier = Modifier.fillMaxWidth().height(4.dp).offset(y = (-24).dp).background(MaterialTheme.colorScheme.primary))

                Column {
                    Text("إعادة معالجة الذكاء", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
                    Spacer(modifier = Modifier.height(8.dp))
                    Text("تحديث قواعد Regex ومطابقة الأنماط على السجلات العالقة.", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)

                    Spacer(modifier = Modifier.height(32.dp))

                    Box(modifier = Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) {
                        Box(
                            modifier = Modifier.size(120.dp).border(4.dp, MaterialTheme.colorScheme.surfaceVariant, CircleShape),
                            contentAlignment = Alignment.Center
                        ) {
                            val infiniteTransition = rememberInfiniteTransition()
                            val rotation by infiniteTransition.animateFloat(
                                initialValue = 0f,
                                targetValue = 360f,
                                animationSpec = infiniteRepeatable(
                                    animation = tween(1000, easing = LinearEasing),
                                    repeatMode = RepeatMode.Restart
                                )
                            )

                            if (isReprocessing) {
                                CircularProgressIndicator(
                                    progress = { reprocessProgress },
                                    modifier = Modifier.fillMaxSize(),
                                    color = MaterialTheme.colorScheme.primary,
                                    strokeWidth = 4.dp
                                )
                                Icon(
                                    imageVector = Icons.Rounded.Sync,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(48.dp).offset(y = 0.dp) // Removed graphic rotation for icon, usually better kept static or spinning separately
                                )
                            } else if (reprocessCompleted) {
                                Icon(
                                    imageVector = Icons.Rounded.CheckCircle,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(48.dp)
                                )
                            } else {
                                Icon(
                                    imageVector = Icons.Rounded.Sync,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.primary,
                                    modifier = Modifier.size(48.dp)
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(24.dp))
                    Text(
                        text = if (isReprocessing) "جاري المعالجة..." else if (reprocessCompleted) "اكتملت المعالجة" else "جاهز للبدء",
                        style = MaterialTheme.typography.titleMedium,
                        color = if (reprocessCompleted) MaterialTheme.colorScheme.primary else MaterialTheme.colorScheme.onSurface,
                        modifier = Modifier.fillMaxWidth(),
                        textAlign = TextAlign.Center,
                        fontWeight = FontWeight.Bold
                    )
                    Spacer(modifier = Modifier.height(4.dp))
                    Text(
                        text = if (isReprocessing) "${logs.size} سجل قيد المعالجة" else if (reprocessCompleted) "تم تحويل السجلات" else "${logs.size} سجل في الانتظار",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant,
                        modifier = Modifier.fillMaxWidth(),
                        textAlign = TextAlign.Center
                    )

                    Spacer(modifier = Modifier.height(32.dp))

                    Button(
                        onClick = {
                            if (!isReprocessing && !reprocessCompleted) {
                                coroutineScope.launch {
                                    for (i in 1..100) {
                                        reprocessProgress = i / 100f
                                        delay(15)
                                    }
                                }
                                viewModel.reprocessLogs(context) {
                                    reprocessCompleted = true
                                    coroutineScope.launch {
                                        delay(3000)
                                        reprocessCompleted = false
                                        reprocessProgress = 0f
                                    }
                                }
                            }
                        },
                        modifier = Modifier.fillMaxWidth().height(56.dp).shadow(8.dp, RoundedCornerShape(12.dp), spotColor = MaterialTheme.colorScheme.primary.copy(alpha = 0.2f)),
                        colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary),
                        shape = RoundedCornerShape(12.dp),
                        enabled = !isReprocessing
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Icon(imageVector = Icons.Rounded.AutoFixHigh, contentDescription = null, modifier = Modifier.size(20.dp))
                            Text("تشغيل معالج النصوص", style = MaterialTheme.typography.titleMedium, fontWeight = FontWeight.Bold)
                        }
                    }
                }
            }

            Spacer(modifier = Modifier.height(24.dp))

            // System Health Visualization
            Box(
                modifier = Modifier
                    .fillMaxWidth()
                    .shadow(4.dp, RoundedCornerShape(16.dp), spotColor = Color.Black.copy(alpha = 0.05f))
                    .background(Color.White, RoundedCornerShape(16.dp))
                    .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(16.dp))
                    .padding(24.dp)
            ) {
                Column {
                    Row(modifier = Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.Top) {
                        Column {
                            Text("سلامة تدفق البيانات", style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
                            Spacer(modifier = Modifier.height(4.dp))
                            Text("معدل تحويل السجلات الخام إلى معاملات مالية", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                        Column(horizontalAlignment = Alignment.End) {
                            Text(if (logs.isEmpty()) "١٠٠٪" else "٠٪", style = MaterialTheme.typography.headlineMedium, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                            Text("دقة التشغيل الآلي", style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                        }
                    }

                    Spacer(modifier = Modifier.height(32.dp))

                    // Chart Mockup
                    Row(
                        modifier = Modifier.fillMaxWidth().height(160.dp),
                        verticalAlignment = Alignment.Bottom,
                        horizontalArrangement = Arrangement.spacedBy(4.dp)
                    ) {
                        repeat(12) {
                            ChartBar(heightFraction = if (logs.isEmpty()) 1f else 0.1f, color = if (logs.isEmpty()) MaterialTheme.colorScheme.primary.copy(alpha = 0.4f) else MaterialTheme.colorScheme.surfaceVariant)
                        }
                    }
                    Box(modifier = Modifier.fillMaxWidth().height(1.dp).background(MaterialTheme.colorScheme.surfaceVariant))
                }
            }

            Spacer(modifier = Modifier.height(100.dp))
        }
    }
}

@Composable
fun LogItem(icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, subtitle: String, time: String, status: String) {
    Box(
        modifier = Modifier
            .fillMaxWidth()
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.3f), RoundedCornerShape(8.dp))
            .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(8.dp))
            .padding(12.dp)
    ) {
        Row(
            modifier = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment = Alignment.CenterVertically
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                Icon(imageVector = icon, contentDescription = null, tint = MaterialTheme.colorScheme.outline)
                Column {
                    Text(title, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
                    Text(subtitle, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
                }
            }
            Column(horizontalAlignment = Alignment.Start) {
                Text(time, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.onSurface)
                Text(status, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
            }
        }
    }
}

@Composable
fun ExportToolCard(modifier: Modifier = Modifier, icon: androidx.compose.ui.graphics.vector.ImageVector, title: String, subtitle: String, actionText: String) {
    Box(
        modifier = modifier
            .shadow(4.dp, RoundedCornerShape(16.dp), spotColor = Color.Black.copy(alpha = 0.05f))
            .background(Color.White, RoundedCornerShape(16.dp))
            .border(1.dp, MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(16.dp))
            .padding(16.dp)
            .clickable { /*TODO*/ }
    ) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(modifier = Modifier.size(48.dp).background(MaterialTheme.colorScheme.surfaceVariant, RoundedCornerShape(12.dp)), contentAlignment = Alignment.Center) {
                Icon(imageVector = icon, contentDescription = null, tint = MaterialTheme.colorScheme.primary)
            }
            Column {
                Text(title, style = MaterialTheme.typography.titleMedium, color = MaterialTheme.colorScheme.onSurface, fontWeight = FontWeight.Bold)
                Text(subtitle, style = MaterialTheme.typography.labelSmall, color = MaterialTheme.colorScheme.onSurfaceVariant)
            }
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(actionText, style = MaterialTheme.typography.labelMedium, color = MaterialTheme.colorScheme.primary, fontWeight = FontWeight.Bold)
                Icon(imageVector = Icons.Rounded.ChevronLeft, contentDescription = null, tint = MaterialTheme.colorScheme.primary, modifier = Modifier.size(16.dp))
            }
        }
    }
}

@Composable
fun RowScope.ChartBar(heightFraction: Float, color: Color) {
    Box(
        modifier = Modifier
            .weight(1f)
            .fillMaxHeight(heightFraction)
            .background(color, RoundedCornerShape(topStart = 4.dp, topEnd = 4.dp))
    )
}


