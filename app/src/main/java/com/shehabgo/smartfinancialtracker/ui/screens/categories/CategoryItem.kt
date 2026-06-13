package com.shehabgo.smartfinancialtracker.ui.screens.categories

import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector

data class CategoryItem(
    val id: Int,
    val name: String,
    val subtitle: String,
    val icon: ImageVector,
    val color: Color
)
