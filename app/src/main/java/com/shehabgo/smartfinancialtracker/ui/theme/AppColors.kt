package com.shehabgo.smartfinancialtracker.ui.theme

import androidx.compose.ui.graphics.Color

/**
 * Design System — Color Tokens
 * مصدر الحقيقة الوحيد لكل ألوان التطبيق.
 * لا تكتب Color(0xFF...) مباشرة في الشاشات — استخدم هذه الثوابت دائماً.
 */
object AppColors {

    // ── الألوان الأساسية (Brand) ──────────────────────────────
    val Primary         = Color(0xFFBD001B)   // الأحمر الرئيسي
    val PrimaryDark     = Color(0xFF96000F)   // أحمر غامق للضغط
    val PrimaryLight    = Color(0xFFE61D2B)   // أحمر فاتح
    val PrimaryContainer= Color(0xFFFFDAD9)   // حاوية أحمر خفيف
    val OnPrimary       = Color.White

    // ── ألوان الخلفية (Background / Surface) ─────────────────
    val Background      = Color(0xFFF6FAFF)   // خلفية الشاشات
    val Surface         = Color.White         // خلفية البطاقات
    val SurfaceVariant  = Color(0xFFF0F4F8)   // خلفية عناصر ثانوية
    val SurfaceDim      = Color(0xFFE8EEF5)   // خلفية خافتة

    // ── ألوان النصوص (Text) ───────────────────────────────────
    val TextPrimary     = Color(0xFF141D23)   // النص الرئيسي
    val TextSecondary   = Color(0xFF5D5E61)   // النص الثانوي
    val TextHint        = Color(0xFFB0B8C1)   // النص الخافت / placeholder
    val TextOnDark      = Color.White         // نص على خلفية داكنة

    // ── ألوان الحدود (Border) ─────────────────────────────────
    val Border          = Color(0xFFE0E9F2)   // حد عادي
    val BorderSoft      = Color(0xFFE7BDB9)   // حد ناعم (بمسحة حمراء)
    val BorderStrong    = Color(0xFFD2DBE4)   // حد أقوى

    // ── ألوان الحالات (State) ─────────────────────────────────
    val Success         = Color(0xFF10B981)   // نجاح / إيجابي
    val Warning         = Color(0xFFF59E0B)   // تحذير
    val Error           = Color(0xFFBA1A1A)   // خطأ
    val Info            = Color(0xFF3B82F6)   // معلومة

    // ── ألوان فئات المعاملات (Category Colors) ────────────────
    val CatTelecom      = Color(0xFF3B82F6)   // اتصالات
    val CatInternet     = Color(0xFF06B6D4)   // إنترنت
    val CatUtilities    = Color(0xFFF59E0B)   // خدمات (كهرباء/مياه)
    val CatEducation    = Color(0xFF8B5CF6)   // تعليم
    val CatEntertainment= Color(0xFFF97316)   // ترفيه
    val CatServices     = Color(0xFF64748B)   // خدمات أخرى
    val CatShopping     = Color(0xFF10B981)   // مشتريات
    val CatTransfer     = Color(0xFFBD001B)   // تحويل
    val CatWithdraw     = Color(0xFF64748B)   // سحب
    val CatDonation     = Color(0xFFEC4899)   // تبرعات

    // ── ألوان Overlay / Tint ──────────────────────────────────
    val PrimaryAlpha05  = Color(0x0DBD001B)   // 5% primary
    val PrimaryAlpha08  = Color(0x14BD001B)   // 8% primary
    val PrimaryAlpha10  = Color(0x1ABD001B)   // 10% primary
    val PrimaryAlpha12  = Color(0x1FBD001B)   // 12% primary

    // ── ألوان النظام ──────────────────────────────────────────
    val Scrim           = Color(0xFF000000)
    val Shadow          = Color(0xFF000000)
    val Transparent     = Color.Transparent
}
