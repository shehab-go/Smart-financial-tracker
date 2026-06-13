package com.shehabgo.smartfinancialtracker.ui.theme

import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.ui.unit.dp

/**
 * Design System — Shape Tokens
 * جميع أشكال الزوايا في التطبيق معرّفة هنا.
 */
object AppShapes {

    // ── بطاقات (Cards) ───────────────────────────────────────
    val CardSm      = RoundedCornerShape(10.dp)   // بطاقة صغيرة
    val Card        = RoundedCornerShape(14.dp)   // بطاقة قياسية
    val CardLg      = RoundedCornerShape(20.dp)   // بطاقة كبيرة

    // ── أزرار (Buttons) ───────────────────────────────────────
    val Button      = RoundedCornerShape(12.dp)   // زر قياسي
    val ButtonSm    = RoundedCornerShape(8.dp)    // زر صغير
    val ButtonPill  = RoundedCornerShape(50.dp)   // زر حبة دائرية

    // ── حقول النص (Fields) ────────────────────────────────────
    val Field       = RoundedCornerShape(12.dp)   // حقل نص قياسي

    // ── Bottom Sheet ──────────────────────────────────────────
    val Sheet       = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp)

    // ── شارات وعلامات (Badges / Chips) ───────────────────────
    val Badge       = RoundedCornerShape(20.dp)
    val Chip        = RoundedCornerShape(8.dp)
    val Tag         = RoundedCornerShape(6.dp)

    // ── أشكال خاصة ────────────────────────────────────────────
    val Icon        = RoundedCornerShape(12.dp)   // حاوية أيقونة
    val Toggle      = RoundedCornerShape(16.dp)   // بطاقة toggle
    val Dialog      = RoundedCornerShape(20.dp)   // نافذة حوار
}
