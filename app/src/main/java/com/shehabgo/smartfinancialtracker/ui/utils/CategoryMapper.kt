package com.shehabgo.smartfinancialtracker.ui.utils

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector

data class CategoryStyle(
    val icon: ImageVector,
    val containerColor: Color,
    val contentColor: Color
)

object CategoryMapper {
    
    // Define brand colors
    private val colorTelecom = Color(0xFFE91E63) // Pink/Red
    private val colorInternet = Color(0xFF2196F3) // Blue
    private val colorGaming = Color(0xFF9C27B0) // Purple
    private val colorEducation = Color(0xFF4CAF50) // Green
    private val colorGov = Color(0xFF607D8B) // Blue Grey
    private val colorCharity = Color(0xFFFF9800) // Orange
    private val colorDefault = Color(0xFF795548) // Brown

    fun getStyleForCounterpart(counterpart: String): CategoryStyle {
        val lowerCaseName = counterpart.lowercase()
        
        return when {
            lowerCaseName.contains("يمن موبايل") || lowerCaseName.contains("سبأفون") || lowerCaseName.contains("you") || lowerCaseName.contains("اتصالات") || lowerCaseName.contains("رصيد وباقات") -> {
                CategoryStyle(
                    icon = Icons.Default.PhoneAndroid,
                    containerColor = colorTelecom.copy(alpha = 0.2f),
                    contentColor = colorTelecom
                )
            }
            lowerCaseName.contains("يمن نت") || lowerCaseName.contains("عدن نت") -> {
                CategoryStyle(
                    icon = Icons.Default.Wifi,
                    containerColor = colorInternet.copy(alpha = 0.2f),
                    contentColor = colorInternet
                )
            }
            lowerCaseName.contains("ببجي") || lowerCaseName.contains("جوجل بلاي") || lowerCaseName.contains("ترفيه") -> {
                CategoryStyle(
                    icon = Icons.Default.SportsEsports,
                    containerColor = colorGaming.copy(alpha = 0.2f),
                    contentColor = colorGaming
                )
            }
            lowerCaseName.contains("جامعة") || lowerCaseName.contains("مدرسة") || lowerCaseName.contains("تعليم") -> {
                CategoryStyle(
                    icon = Icons.Default.School,
                    containerColor = colorEducation.copy(alpha = 0.2f),
                    contentColor = colorEducation
                )
            }
            lowerCaseName.contains("جوازات") || lowerCaseName.contains("مرور") || lowerCaseName.contains("حكومي") -> {
                CategoryStyle(
                    icon = Icons.Default.AccountBalance,
                    containerColor = colorGov.copy(alpha = 0.2f),
                    contentColor = colorGov
                )
            }
            lowerCaseName.contains("تبرع") || lowerCaseName.contains("زكاة") || lowerCaseName.contains("صدقة") -> {
                CategoryStyle(
                    icon = Icons.Default.Favorite,
                    containerColor = colorCharity.copy(alpha = 0.2f),
                    contentColor = colorCharity
                )
            }
            else -> {
                // Default style for unknown counterparts (e.g. personal transfers)
                CategoryStyle(
                    icon = Icons.Default.Person,
                    containerColor = colorDefault.copy(alpha = 0.2f),
                    contentColor = colorDefault
                )
            }
        }
    }
}
