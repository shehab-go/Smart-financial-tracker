package com.shehabgo.smartfinancialtracker.ui.screens.categories

import androidx.compose.animation.*
import androidx.compose.animation.core.*
import androidx.compose.foundation.*
import androidx.compose.foundation.layout.*
import androidx.compose.foundation.lazy.grid.*
import androidx.compose.foundation.shape.CircleShape
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.shehabgo.smartfinancialtracker.ui.theme.AppColors
import com.shehabgo.smartfinancialtracker.ui.theme.AppShapes
import com.shehabgo.smartfinancialtracker.ui.theme.AppSpacing
import com.shehabgo.smartfinancialtracker.ui.theme.AppElevation

// ── الألوان المتاحة ───────────────────────────────────────────
val availableColors = listOf(
    AppColors.Primary,
    AppColors.CatEntertainment,
    AppColors.CatTelecom,
    AppColors.CatShopping,
    AppColors.CatEducation,
    AppColors.CatUtilities,
    AppColors.CatInternet,
)

// ── الأيقونات المتاحة ─────────────────────────────────────────
val availableIcons: List<ImageVector> = listOf(
    Icons.Rounded.ShoppingBasket,
    Icons.Rounded.CellTower,
    Icons.Rounded.Wifi,
    Icons.Rounded.Eco,
    Icons.Rounded.LocalTaxi,
    Icons.Rounded.Bolt,
    Icons.Rounded.Restaurant,
    Icons.Rounded.Home,
    Icons.Rounded.School,
    Icons.Rounded.HealthAndSafety,
    Icons.Rounded.Work,
    Icons.Rounded.SportsEsports,
    Icons.Rounded.FitnessCenter,
    Icons.Rounded.Flight,
    Icons.Rounded.Medication,
    Icons.Rounded.Coffee,
)

// ── الفئات الافتراضية — مبنية على أنواع معاملات موديول الالتقاط ──
fun defaultCategories() = listOf(

    // ── مدفوعات التشغيل (Payment) ────────────────────────────
    CategoryItem(
        id       = 1,
        name     = "اتصالات وباقات",
        subtitle = "رصيد وباقات",
        icon     = Icons.Rounded.CellTower,
        color    = AppColors.CatTelecom
    ),
    CategoryItem(
        id       = 2,
        name     = "إنترنت منزلي",
        subtitle = "ADSL / فيبر / 4G",
        icon     = Icons.Rounded.Wifi,
        color    = AppColors.CatInternet
    ),
    CategoryItem(
        id       = 3,
        name     = "كهرباء ومياه",
        subtitle = "فواتير حكومية",
        icon     = Icons.Rounded.Bolt,
        color    = AppColors.CatUtilities
    ),
    CategoryItem(
        id       = 4,
        name     = "تعليم",
        subtitle = "جامعات وكليات ومعاهد",
        icon     = Icons.Rounded.School,
        color    = AppColors.CatEducation
    ),
    CategoryItem(
        id       = 5,
        name     = "ترفيه",
        subtitle = "خدمات ترفيه وتطبيقات",
        icon     = Icons.Rounded.SportsEsports,
        color    = AppColors.CatEntertainment
    ),
    CategoryItem(
        id       = 6,
        name     = "خدمات أخرى",
        subtitle = "مدفوعات حكومية وشركات",
        icon     = Icons.Rounded.Work,
        color    = AppColors.CatServices
    ),

    // ── مشتريات (Purchase) ────────────────────────────────────
    CategoryItem(
        id       = 7,
        name     = "مشتريات",
        subtitle = "سوبرماركت وتسوق",
        icon     = Icons.Rounded.ShoppingBasket,
        color    = AppColors.CatShopping
    ),

    // ── تحويلات (Transfer Out) ────────────────────────────────
    CategoryItem(
        id       = 8,
        name     = "تحويل مالي",
        subtitle = "إرسال حوالات وتغذية",
        icon     = Icons.Rounded.SendToMobile,
        color    = AppColors.CatTransfer
    ),

    // ── سحب نقدي (Withdraw) ───────────────────────────────────
    CategoryItem(
        id       = 9,
        name     = "سحب نقدي",
        subtitle = "صراف آلي أو نقدي",
        icon     = Icons.Rounded.LocalAtm,
        color    = AppColors.CatWithdraw
    ),

    // ── تبرعات (Donation) ─────────────────────────────────────
    CategoryItem(
        id       = 10,
        name     = "تبرعات",
        subtitle = "جمعيات ومؤسسات خيرية",
        icon     = Icons.Rounded.VolunteerActivism,
        color    = AppColors.CatDonation
    ),
)

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun CategoriesCustomizationScreen() {
    val context = androidx.compose.ui.platform.LocalContext.current
    var manualCashEnabled by remember { mutableStateOf(true) }
    var categories        by remember { mutableStateOf(com.shehabgo.smartfinancialtracker.data.CategoryManager.getCategories(context)) }
    var selectedId        by remember { mutableStateOf<Int?>(null) }
    var showSheet         by remember { mutableStateOf(false) }

    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)

    // ── الشاشة الرئيسية ───────────────────────────────────────
    Scaffold(
        containerColor = AppColors.Surface
    ) { innerPadding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(innerPadding)
                .padding(horizontal = AppSpacing.ScreenH)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Spacer(modifier = Modifier.height(AppSpacing.xl))

        // ── العنوان ───────────────────────────────────────────
        Text(
            text  = "تخصيص الفئات الذكية",
            style = MaterialTheme.typography.headlineMedium.copy(
                fontSize   = 26.sp,
                fontWeight = FontWeight.Bold,
                lineHeight = 36.sp
            ),
            color     = AppColors.TextPrimary,
            textAlign = TextAlign.Center
        )
        Spacer(modifier = Modifier.height(AppSpacing.md))
        Text(
            text  = "صمم هيكلك المالي. اختر وعدل الفئات التي تتناسب مع أسلوب حياتك.",
            style = MaterialTheme.typography.bodyLarge.copy(fontSize = 15.sp, lineHeight = 24.sp),
            color = AppColors.TextSecondary,
            textAlign = TextAlign.Center,
            modifier  = Modifier.padding(horizontal = AppSpacing.sm)
        )

        Spacer(modifier = Modifier.height(AppSpacing.xl))

        // ── Toggle الكاش اليدوي ────────────────────────────────
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(AppElevation.xs, AppShapes.Toggle, spotColor = AppColors.Primary.copy(alpha = 0.06f))
                .background(AppColors.Surface, AppShapes.Toggle)
                .border(1.dp, AppColors.BorderSoft.copy(alpha = 0.4f), AppShapes.Toggle)
                .padding(horizontal = AppSpacing.lg, vertical = AppSpacing.base)
        ) {
            Row(
                modifier  = Modifier.fillMaxWidth(),
                verticalAlignment = Alignment.CenterVertically
            ) {
                // أيقونة
                Box(
                    modifier = Modifier
                        .size(AppSpacing.IconContainer)
                        .background(
                            if (manualCashEnabled) AppColors.PrimaryAlpha10
                            else AppColors.SurfaceVariant,
                            AppShapes.Icon
                        ),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = Icons.Rounded.AccountBalanceWallet,
                        contentDescription = null,
                        tint = if (manualCashEnabled) AppColors.Primary else AppColors.TextHint,
                        modifier = Modifier.size(AppSpacing.IconSm)
                    )
                }
                Spacer(modifier = Modifier.width(AppSpacing.CardPadSm))
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text  = "ميزانية الكاش اليدوية",
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold),
                        color = AppColors.TextPrimary
                    )
                    Text(
                        text  = "تتبع المصاريف النقدية اليومية بسهولة",
                        style = MaterialTheme.typography.labelMedium,
                        color = AppColors.TextSecondary
                    )
                }
                Switch(
                    checked  = manualCashEnabled,
                    onCheckedChange = { manualCashEnabled = it },
                    colors   = SwitchDefaults.colors(
                        checkedThumbColor   = AppColors.Surface,
                        checkedTrackColor   = AppColors.Primary,
                        uncheckedThumbColor = AppColors.Surface,
                        uncheckedTrackColor = AppColors.BorderStrong
                    )
                )
            }
        }

        Spacer(modifier = Modifier.height(AppSpacing.xl))

        // ── ملخص المصروفات (Expense Analytics) ────────────────────
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .shadow(AppElevation.sm, AppShapes.CardLg, spotColor = AppColors.Error.copy(alpha = 0.1f))
                .background(AppColors.Surface, AppShapes.CardLg)
                .border(1.dp, AppColors.Border, AppShapes.CardLg)
                .padding(AppSpacing.CardPadLg)
        ) {
            Column {
                Text(
                    text = "تحليل مصروفات الشهر",
                    style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                    color = AppColors.TextPrimary
                )
                Spacer(modifier = Modifier.height(AppSpacing.md))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.SpaceBetween
                ) {
                    // الدائرة البيانية الوهمية للجماليات (Pie Chart Placeholder)
                    Box(
                        modifier = Modifier
                            .size(100.dp)
                            .background(AppColors.SurfaceVariant, CircleShape)
                            .border(8.dp, AppColors.Primary, CircleShape)
                            .padding(8.dp)
                            .border(8.dp, AppColors.CatShopping, CircleShape)
                            .padding(8.dp)
                            .border(8.dp, AppColors.CatTelecom, CircleShape),
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(Icons.Rounded.Analytics, contentDescription = null, tint = AppColors.TextSecondary)
                    }
                    
                    Column(
                        modifier = Modifier.weight(1f).padding(start = AppSpacing.md),
                        verticalArrangement = Arrangement.spacedBy(AppSpacing.sm)
                    ) {
                        AnalyticsLegendItem(color = AppColors.Primary, label = "اتصالات وإنترنت", percentage = "45%")
                        AnalyticsLegendItem(color = AppColors.CatShopping, label = "مشتريات وبقالة", percentage = "35%")
                        AnalyticsLegendItem(color = AppColors.CatTelecom, label = "مواصلات", percentage = "20%")
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(AppSpacing.xl))

        // ── رأس الـ Grid ───────────────────────────────────────
        Row(
            modifier  = Modifier.fillMaxWidth(),
            horizontalArrangement = Arrangement.SpaceBetween,
            verticalAlignment     = Alignment.CenterVertically
        ) {
            Text(
                text  = "فئات المصاريف",
                style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                color = AppColors.TextPrimary
            )
            Surface(
                onClick = {
                    // إضافة فئة جديدة
                    val newId = (categories.maxOfOrNull { it.id } ?: 0) + 1
                    val newCat = CategoryItem(
                        id       = newId,
                        name     = "فئة جديدة",
                        subtitle = "انقر للتعديل",
                        icon     = Icons.Rounded.Add,
                        color    = AppColors.Primary
                    )
                    val newCats = categories + newCat
                    categories = newCats
                    com.shehabgo.smartfinancialtracker.data.CategoryManager.saveCategories(context, newCats)
                    selectedId = newId
                    showSheet  = true
                },
                shape  = AppShapes.Badge,
                color  = AppColors.PrimaryAlpha08
            ) {
                Row(
                    modifier  = Modifier.padding(horizontal = AppSpacing.CardPadSm, vertical = AppSpacing.xs),
                    verticalAlignment     = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(AppSpacing.xs)
                ) {
                    Icon(
                        imageVector = Icons.Rounded.Add,
                        contentDescription = null,
                        tint     = AppColors.Primary,
                        modifier = Modifier.size(AppSpacing.IconXs)
                    )
                    Text(
                        text  = "إضافة فئة",
                        style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                        color = AppColors.Primary
                    )
                }
            }
        }

        Spacer(modifier = Modifier.height(AppSpacing.base))

        // ── Grid الفئات ────────────────────────────────────────
        val rows = categories.chunked(2)
        Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.sm)) {
            rows.forEach { rowItems ->
                Row(horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)) {
                    rowItems.forEach { cat ->
                        Box(modifier = Modifier.weight(1f)) {
                            CategoryCard(
                                category    = cat,
                                isSelected  = cat.id == selectedId,
                                onClick     = {
                                    selectedId = cat.id
                                    showSheet  = true
                                }
                            )
                        }
                    }
                    // تعبئة فراغ إن كان العدد فردي
                    if (rowItems.size == 1) {
                        Spacer(modifier = Modifier.weight(1f))
                    }
                }
            }
        }

        Spacer(modifier = Modifier.height(AppSpacing.base))
        // ── مساحة فارغة سفلية لتجنب شريط التنقل ─────────────────────
        Spacer(modifier = Modifier.height(120.dp))
    }

    // ── نافذة التعديل (Bottom Sheet) ──────────────────────────
    val selectedCategory = categories.find { it.id == selectedId }
    if (showSheet && selectedCategory != null) {
        ModalBottomSheet(
            onDismissRequest  = { showSheet = false; selectedId = null },
            sheetState        = sheetState,
            containerColor    = AppColors.Surface,
            shape             = AppShapes.Sheet,
            dragHandle        = {
                Box(
                    modifier = Modifier
                        .padding(top = AppSpacing.md, bottom = AppSpacing.sm)
                        .size(width = 40.dp, height = 4.dp)
                        .background(AppColors.BorderStrong, CircleShape)
                )
            }
        ) {
            CategoryEditBottomSheet(
                category = selectedCategory,
                onSave   = { updated ->
                    val updatedCats = categories.map { if (it.id == updated.id) updated else it }
                    categories = updatedCats
                    com.shehabgo.smartfinancialtracker.data.CategoryManager.saveCategories(context, updatedCats)
                    showSheet  = false
                    selectedId = null
                },
                onDelete = {
                    val filteredCats = categories.filter { it.id != selectedCategory.id }
                    categories = filteredCats
                    com.shehabgo.smartfinancialtracker.data.CategoryManager.saveCategories(context, filteredCats)
                    showSheet  = false
                    selectedId = null
                },
                onDismiss = { showSheet = false; selectedId = null }
            )
        }
    }
}
}

// ══════════════════════════════════════════════════════════════
// بطاقة الفئة
// ══════════════════════════════════════════════════════════════
@Composable
fun CategoryCard(
    category   : CategoryItem,
    isSelected : Boolean,
    onClick    : () -> Unit
) {
    val borderColor by animateColorAsState(
        targetValue   = if (isSelected) category.color else AppColors.Border,
        animationSpec = tween(250),
        label = "border"
    )
    val bgColor by animateColorAsState(
        targetValue   = if (isSelected) category.color.copy(alpha = 0.05f) else AppColors.Surface,
        animationSpec = tween(250),
        label = "bg"
    )
    val iconBg by animateColorAsState(
        targetValue   = if (isSelected) category.color else category.color.copy(alpha = 0.1f),
        animationSpec = tween(250),
        label = "iconBg"
    )
    val iconTint by animateColorAsState(
        targetValue   = if (isSelected) AppColors.Surface else category.color,
        animationSpec = tween(250),
        label = "iconTint"
    )
    val elevation = if (isSelected) AppElevation.md else AppElevation.xs

    Box(
        modifier = Modifier
            .fillMaxWidth()
            .shadow(elevation, AppShapes.Card, spotColor = category.color.copy(alpha = 0.15f))
            .background(bgColor, AppShapes.Card)
            .border(
                width = if (isSelected) 2.dp else 1.dp,
                color = borderColor,
                shape = AppShapes.Card
            )
            .clickable { onClick() }
            .padding(AppSpacing.CardPadSm)
    ) {
        // نقطة التحديد
        if (isSelected) {
            Box(
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .size(AppSpacing.IconSm)
                    .background(category.color, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Rounded.Check,
                    contentDescription = null,
                    tint     = AppColors.Surface,
                    modifier = Modifier.size(AppSpacing.IconXs)
                )
            }
        }

        Column(
            modifier              = Modifier.fillMaxWidth(),
            horizontalAlignment   = Alignment.CenterHorizontally,
            verticalArrangement   = Arrangement.spacedBy(AppSpacing.sm)
        ) {
            Box(
                modifier = Modifier
                    .size(AppSpacing.IconContainerMd)
                    .background(iconBg, CircleShape),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = category.icon,
                    contentDescription = null,
                    tint     = iconTint,
                    modifier = Modifier.size(AppSpacing.IconMd)
                )
            }
            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                verticalArrangement = Arrangement.spacedBy(2.dp)
            ) {
                Text(
                    text  = category.name,
                    style = MaterialTheme.typography.labelLarge.copy(
                        fontWeight = if (isSelected) FontWeight.Bold else FontWeight.Medium
                    ),
                    color = AppColors.TextPrimary,
                    textAlign = TextAlign.Center
                )
                Text(
                    text  = category.subtitle,
                    style = MaterialTheme.typography.labelSmall.copy(fontSize = 10.sp),
                    color = if (isSelected) category.color else AppColors.TextSecondary,
                    fontWeight = FontWeight.SemiBold,
                    textAlign  = TextAlign.Center
                )
            }
        }
    }
}

// ══════════════════════════════════════════════════════════════
// Bottom Sheet للتعديل
// ══════════════════════════════════════════════════════════════
@Composable
fun CategoryEditBottomSheet(
    category  : CategoryItem,
    onSave    : (CategoryItem) -> Unit,
    onDelete  : () -> Unit,
    onDismiss : () -> Unit
) {
    var editName     by remember(category.id) { mutableStateOf(category.name) }
    var editSubtitle by remember(category.id) { mutableStateOf(category.subtitle) }
    var editColor    by remember(category.id) { mutableStateOf(category.color) }
    var editIcon     by remember(category.id) { mutableStateOf(category.icon) }
    var showDelete   by remember { mutableStateOf(false) }

    Column(
        modifier = Modifier
            .fillMaxWidth()
            .verticalScroll(rememberScrollState())
            .padding(horizontal = AppSpacing.ScreenH)
            .padding(bottom = AppSpacing.xxl),
        verticalArrangement = Arrangement.spacedBy(AppSpacing.xl)
    ) {

        // ── Preview مباشر ─────────────────────────────────────
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .background(editColor.copy(alpha = 0.05f), AppShapes.Toggle)
                .border(1.dp, editColor.copy(alpha = 0.3f), AppShapes.Toggle)
                .padding(AppSpacing.CardPadLg)
        ) {
            Row(
                verticalAlignment     = Alignment.CenterVertically,
                horizontalArrangement = Arrangement.spacedBy(AppSpacing.base)
            ) {
                Box(
                    modifier = Modifier
                        .size(AppSpacing.IconContainerLg)
                        .shadow(AppElevation.lg, AppShapes.Card, spotColor = editColor.copy(alpha = 0.3f))
                        .background(editColor, AppShapes.Card),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(
                        imageVector = editIcon,
                        contentDescription = null,
                        tint     = AppColors.Surface,
                        modifier = Modifier.size(AppSpacing.IconLg)
                    )
                }
                Column(modifier = Modifier.weight(1f)) {
                    Text(
                        text  = editName.ifBlank { "اسم الفئة" },
                        style = MaterialTheme.typography.titleMedium.copy(fontWeight = FontWeight.Bold),
                        color = AppColors.TextPrimary
                    )
                    Text(
                        text  = editSubtitle.ifBlank { "وصف الفئة" },
                        style = MaterialTheme.typography.labelMedium,
                        color = AppColors.TextSecondary
                    )
                }
                // تسمية "معاينة"
                Box(
                    modifier = Modifier
                        .background(editColor.copy(alpha = 0.12f), AppShapes.ButtonSm)
                        .padding(horizontal = AppSpacing.sm, vertical = AppSpacing.xs)
                ) {
                    Text(
                        text  = "معاينة",
                        style = MaterialTheme.typography.labelSmall.copy(fontWeight = FontWeight.Bold),
                        color = editColor
                    )
                }
            }
        }

        // ── حقل الاسم ─────────────────────────────────────────
        Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.sm)) {
            Text(
                text  = "اسم الفئة",
                style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                color = AppColors.TextPrimary
            )
            OutlinedTextField(
                value         = editName,
                onValueChange = { editName = it },
                modifier      = Modifier.fillMaxWidth(),
                singleLine    = true,
                shape         = AppShapes.Field,
                placeholder   = { Text("مثال: مواد غذائية", color = AppColors.TextHint) },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor   = editColor,
                    unfocusedBorderColor = AppColors.BorderStrong,
                    focusedLabelColor    = editColor,
                    cursorColor          = editColor
                )
            )
        }

        // ── حقل الوصف ─────────────────────────────────────────
        Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.sm)) {
            Text(
                text  = "وصف الفئة",
                style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                color = AppColors.TextPrimary
            )
            OutlinedTextField(
                value         = editSubtitle,
                onValueChange = { editSubtitle = it },
                modifier      = Modifier.fillMaxWidth(),
                singleLine    = true,
                shape         = AppShapes.Field,
                placeholder   = { Text("مثال: سوبر ماركت", color = AppColors.TextHint) },
                colors = OutlinedTextFieldDefaults.colors(
                    focusedBorderColor   = editColor,
                    unfocusedBorderColor = AppColors.BorderStrong,
                    focusedLabelColor    = editColor,
                    cursorColor          = editColor
                )
            )
        }

        // ── اختيار اللون ───────────────────────────────────────
        Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.md)) {
            Text(
                text  = "لون الفئة",
                style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                color = AppColors.TextPrimary
            )
            Row(
                modifier              = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)
            ) {
                availableColors.forEach { color ->
                    val isChosen = color == editColor
                    Box(
                        modifier = Modifier
                            .size(36.dp)
                            .then(
                                if (isChosen) Modifier.border(2.5.dp, color, CircleShape)
                                else Modifier
                            )
                            .padding(if (isChosen) 4.dp else 0.dp)
                            .background(color, CircleShape)
                            .clickable { editColor = color }
                    ) {
                        if (isChosen) {
                            Icon(
                                imageVector = Icons.Rounded.Check,
                                contentDescription = null,
                                tint     = AppColors.Surface,
                                modifier = Modifier
                                    .size(AppSpacing.IconXs)
                                    .align(Alignment.Center)
                            )
                        }
                    }
                }
            }
        }

        // ── اختيار الأيقونة ────────────────────────────────────
        Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.md)) {
            Text(
                text  = "أيقونة الفئة",
                style = MaterialTheme.typography.labelLarge.copy(fontWeight = FontWeight.Bold),
                color = AppColors.TextPrimary
            )
            LazyVerticalGrid(
                columns             = GridCells.Fixed(4),
                horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm),
                verticalArrangement   = Arrangement.spacedBy(AppSpacing.sm),
                modifier = Modifier.heightIn(max = 300.dp)
            ) {
                items(availableIcons) { icon ->
                    val isChosen = icon == editIcon
                    Box(
                        modifier = Modifier
                            .aspectRatio(1f)
                            .shadow(
                                if (isChosen) AppElevation.sm else AppElevation.none,
                                AppShapes.Field,
                                spotColor = editColor.copy(alpha = 0.2f)
                            )
                            .background(
                                if (isChosen) editColor else AppColors.SurfaceVariant,
                                AppShapes.Field
                            )
                            .border(
                                width = if (isChosen) 0.dp else 1.dp,
                                color = AppColors.Border,
                                shape = AppShapes.Field
                            )
                            .clickable { editIcon = icon },
                        contentAlignment = Alignment.Center
                    ) {
                        Icon(
                            imageVector = icon,
                            contentDescription = null,
                            tint     = if (isChosen) AppColors.Surface else AppColors.TextSecondary,
                            modifier = Modifier.size(AppSpacing.IconMd)
                        )
                    }
                }
            }
        }

        // ── أزرار الإجراء ──────────────────────────────────────
        Column(verticalArrangement = Arrangement.spacedBy(AppSpacing.sm)) {

            // حفظ التغييرات
            Button(
                onClick = {
                    onSave(
                        category.copy(
                            name     = editName.trim().ifBlank { category.name },
                            subtitle = editSubtitle.trim().ifBlank { category.subtitle },
                            color    = editColor,
                            icon     = editIcon
                        )
                    )
                },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(AppSpacing.ButtonHeight),
                shape  = AppShapes.Button,
                colors = ButtonDefaults.buttonColors(
                    containerColor = editColor,
                    contentColor   = AppColors.Surface
                )
            ) {
                Row(
                    verticalAlignment     = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)
                ) {
                    Icon(Icons.Rounded.Check, contentDescription = null, modifier = Modifier.size(AppSpacing.IconSm))
                    Text(
                        text  = "حفظ التغييرات",
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold)
                    )
                }
            }

            // حذف الفئة
            OutlinedButton(
                onClick = { showDelete = true },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(AppSpacing.ButtonHeight),
                shape  = AppShapes.Button,
                border = BorderStroke(1.dp, AppColors.Primary.copy(alpha = 0.4f)),
                colors = ButtonDefaults.outlinedButtonColors(contentColor = AppColors.Primary)
            ) {
                Row(
                    verticalAlignment     = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)
                ) {
                    Icon(Icons.Rounded.Delete, contentDescription = null, modifier = Modifier.size(AppSpacing.IconXs))
                    Text(
                        text  = "حذف الفئة",
                        style = MaterialTheme.typography.titleSmall.copy(fontWeight = FontWeight.Bold)
                    )
                }
            }
        }
    }

    // ── Dialog تأكيد الحذف ────────────────────────────────────
    if (showDelete) {
        AlertDialog(
            onDismissRequest  = { showDelete = false },
            containerColor    = AppColors.Surface,
            shape             = AppShapes.Dialog,
            icon = {
                Box(
                    modifier = Modifier
                        .size(AppSpacing.IconContainerMd)
                        .background(AppColors.Primary.copy(alpha = 0.1f), CircleShape),
                    contentAlignment = Alignment.Center
                ) {
                    Icon(Icons.Rounded.Delete, contentDescription = null, tint = AppColors.Primary, modifier = Modifier.size(AppSpacing.IconMd))
                }
            },
            title = {
                Text(
                    text      = "حذف الفئة",
                    style     = MaterialTheme.typography.titleLarge.copy(fontWeight = FontWeight.Bold),
                    color     = AppColors.TextPrimary,
                    textAlign = TextAlign.Center,
                    modifier  = Modifier.fillMaxWidth()
                )
            },
            text = {
                Text(
                    text      = "هل أنت متأكد من حذف فئة \"${category.name}\"؟ لا يمكن التراجع عن هذا الإجراء.",
                    style     = MaterialTheme.typography.bodyMedium,
                    color     = AppColors.TextSecondary,
                    textAlign = TextAlign.Center,
                    modifier  = Modifier.fillMaxWidth()
                )
            },
            confirmButton = {
                Button(
                    onClick = { showDelete = false; onDelete() },
                    shape   = AppShapes.ButtonSm,
                    colors  = ButtonDefaults.buttonColors(
                        containerColor = AppColors.Primary,
                        contentColor   = AppColors.Surface
                    )
                ) { Text("حذف", fontWeight = FontWeight.Bold) }
            },
            dismissButton = {
                TextButton(onClick = { showDelete = false }) {
                    Text("إلغاء", color = AppColors.TextSecondary)
                }
            }
        )
    }
}

@Composable
fun AnalyticsLegendItem(color: Color, label: String, percentage: String) {
    Row(
        modifier = Modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceBetween,
        verticalAlignment = Alignment.CenterVertically
    ) {
        Row(
            verticalAlignment = Alignment.CenterVertically,
            horizontalArrangement = Arrangement.spacedBy(AppSpacing.sm)
        ) {
            Box(
                modifier = Modifier
                    .size(10.dp)
                    .background(color, CircleShape)
            )
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Bold),
                color = AppColors.TextPrimary
            )
        }
        Text(
            text = percentage,
            style = MaterialTheme.typography.labelMedium.copy(fontWeight = FontWeight.Black),
            color = AppColors.TextSecondary
        )
    }
}

