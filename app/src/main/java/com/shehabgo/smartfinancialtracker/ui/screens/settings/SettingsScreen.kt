package com.shehabgo.smartfinancialtracker.ui.screens.settings

import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.layout.*
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.rounded.ArrowBack
import androidx.compose.material.icons.rounded.FileDownload
import androidx.compose.material3.*
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.shehabgo.smartfinancialtracker.ui.screens.dashboard.DashboardViewModel
import com.shehabgo.smartfinancialtracker.ui.utils.ExportUtils
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(
    onNavigateBack: () -> Unit,
    dashboardViewModel: DashboardViewModel = viewModel()
) {
    val context = LocalContext.current
    val transactions by dashboardViewModel.transactions.collectAsStateWithLifecycle()
    val snackbarHostState = remember { SnackbarHostState() }
    val coroutineScope = rememberCoroutineScope()
    
    val exportLauncher = rememberLauncherForActivityResult(
        contract = ActivityResultContracts.CreateDocument("text/csv")
    ) { uri ->
        if (uri != null) {
            val csvContent = ExportUtils.generateCSVContent(transactions)
            ExportUtils.saveCSVToUri(context, uri, csvContent)
            coroutineScope.launch {
                snackbarHostState.showSnackbar("تم تصدير البيانات بنجاح!")
            }
        }
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text("الإعدادات") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Rounded.ArrowBack, contentDescription = "العودة")
                    }
                }
            )
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(24.dp)
        ) {
            Text(
                text = "النسخ الاحتياطي والأمان",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.primary
            )
            Spacer(modifier = Modifier.height(16.dp))
            Text(
                text = "نحن نؤمن بخصوصيتك. جميع بياناتك تُحفظ محلياً. استخدم زر التصدير لحفظ نسخة آمنة من معاملاتك.",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(24.dp))
            
            Button(
                onClick = {
                    exportLauncher.launch("SmartTracker_Backup.csv")
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.primary)
            ) {
                Icon(Icons.Rounded.FileDownload, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("تصدير العمليات (CSV)", style = MaterialTheme.typography.titleMedium)
            }
        }
    }
}
