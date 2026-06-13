package com.shehabgo.smartfinancialtracker.ui.theme

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Shapes
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.platform.LocalLayoutDirection
import androidx.compose.ui.unit.LayoutDirection

private val LightColorScheme = lightColorScheme(
    primary                = md_theme_light_primary,
    onPrimary              = md_theme_light_onPrimary,
    primaryContainer       = md_theme_light_primaryContainer,
    onPrimaryContainer     = md_theme_light_onPrimaryContainer,
    secondary              = md_theme_light_secondary,
    onSecondary            = md_theme_light_onSecondary,
    secondaryContainer     = md_theme_light_secondaryContainer,
    onSecondaryContainer   = md_theme_light_onSecondaryContainer,
    tertiary               = md_theme_light_tertiary,
    onTertiary             = md_theme_light_onTertiary,
    tertiaryContainer      = md_theme_light_tertiaryContainer,
    onTertiaryContainer    = md_theme_light_onTertiaryContainer,
    error                  = md_theme_light_error,
    errorContainer         = md_theme_light_errorContainer,
    onError                = md_theme_light_onError,
    onErrorContainer       = md_theme_light_onErrorContainer,
    background             = md_theme_light_background,
    onBackground           = md_theme_light_onBackground,
    surface                = md_theme_light_surface,
    onSurface              = md_theme_light_onSurface,
    surfaceVariant         = md_theme_light_surfaceVariant,
    onSurfaceVariant       = md_theme_light_onSurfaceVariant,
    outline                = md_theme_light_outline,
    inverseOnSurface       = md_theme_light_inverseOnSurface,
    inverseSurface         = md_theme_light_inverseSurface,
    inversePrimary         = md_theme_light_inversePrimary,
    surfaceTint            = md_theme_light_surfaceTint,
    outlineVariant         = md_theme_light_outlineVariant,
    scrim                  = md_theme_light_scrim,
)

// ── Shape System مرتبط بـ AppShapes ──────────────────────────
private val AppShapeScheme = Shapes(
    extraSmall = AppShapes.ButtonSm,
    small      = AppShapes.CardSm,
    medium     = AppShapes.Card,
    large      = AppShapes.CardLg,
    extraLarge = AppShapes.Sheet
)

@Composable
fun SmartFinancialTrackerTheme(
    content: @Composable () -> Unit
) {
    MaterialTheme(
        colorScheme = LightColorScheme,
        typography  = Typography,
        shapes      = AppShapeScheme
    ) {
        // فرض اتجاه RTL للغة العربية
        CompositionLocalProvider(LocalLayoutDirection provides LayoutDirection.Rtl) {
            content()
        }
    }
}