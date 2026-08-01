package com.shehabgo.smartfinancialtracker.ui.theme

import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp

/**
 * Design System — Spacing Tokens
 * جميع قيم المسافات والحجوم في التطبيق.
 */
object AppSpacing {

    // ── شبكة المسافات (Spacing Grid — base 4dp) ──────────────
    val xs   : Dp = 4.dp    // خاصة جداً
    val sm   : Dp = 8.dp    // صغيرة
    val md   : Dp = 12.dp   // متوسطة صغيرة
    val base : Dp = 16.dp   // الوحدة الأساسية
    val lg   : Dp = 20.dp   // كبيرة
    val xl   : Dp = 24.dp   // كبيرة جداً
    val xxl  : Dp = 32.dp   // ضخمة
    val xxxl : Dp = 48.dp   // ضخمة جداً

    // ── padding الشاشات (Screen Padding) ─────────────────────
    val ScreenH : Dp = 24.dp   // padding أفقي للشاشة
    val ScreenV : Dp = 16.dp   // padding عمودي للشاشة

    // ── padding البطاقات (Card Padding) ──────────────────────
    val CardPad : Dp = 16.dp   // padding داخلي بطاقة قياسية
    val CardPadSm: Dp = 12.dp  // padding داخلي بطاقة صغيرة
    val CardPadLg: Dp = 20.dp  // padding داخلي بطاقة كبيرة

    // ── حجوم الأيقونات (Icon Sizes) ──────────────────────────
    val IconXs  : Dp = 16.dp
    val IconSm  : Dp = 20.dp
    val Icon    : Dp = 24.dp
    val IconMd  : Dp = 28.dp
    val IconLg  : Dp = 32.dp
    val IconXl  : Dp = 40.dp
    val IconXxl : Dp = 52.dp

    // ── حجوم حاويات الأيقونات (Icon Container Sizes) ─────────
    val IconContainerSm : Dp = 36.dp
    val IconContainer   : Dp = 44.dp
    val IconContainerMd : Dp = 52.dp
    val IconContainerLg : Dp = 60.dp
    val IconContainerXl : Dp = 72.dp

    // ── ارتفاعات الأزرار (Button Heights) ────────────────────
    val ButtonHeightSm  : Dp = 40.dp
    val ButtonHeight    : Dp = 52.dp
    val ButtonHeightLg  : Dp = 56.dp

    // ── ارتفاع الـ Top Bar ────────────────────────────────────
    val TopBarHeight    : Dp = 64.dp
}

/**
 * Design System — Elevation Tokens
 * قيم الظلال الموحدة.
 */
object AppElevation {
    val none   : Dp = 0.dp
    val xs     : Dp = 2.dp
    val sm     : Dp = 4.dp
    val md     : Dp = 8.dp
    val lg     : Dp = 12.dp
    val xl     : Dp = 16.dp
    val xxl    : Dp = 24.dp
    val card   : Dp = 6.dp    // ظل بطاقة قياسية
    val sheet  : Dp = 20.dp   // ظل bottom sheet
    val dialog : Dp = 24.dp   // ظل نافذة حوار
}
