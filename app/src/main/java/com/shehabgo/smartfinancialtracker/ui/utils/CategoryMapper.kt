package com.shehabgo.smartfinancialtracker.ui.utils

import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.*
import androidx.compose.material.icons.automirrored.filled.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector

data class CategoryStyle(
    val icon: ImageVector,
    val containerColor: Color,
    val contentColor: Color,
    val emoji: String = "💰"
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
        return getEmojiAndColorForText(counterpart)
    }

    fun getEmojiAndColorForText(text: String, isIncome: Boolean = false): CategoryStyle {
        val lowerCaseName = text.lowercase()
        
        return when {
            lowerCaseName.contains("يمن موبايل") || lowerCaseName.contains("سبأفون") || lowerCaseName.contains("you") || lowerCaseName.contains("اتصالات") || lowerCaseName.contains("رصيد وباقات") || lowerCaseName.contains("نت") || lowerCaseName.contains("يمن نت") || lowerCaseName.contains("عدن نت") -> {
                CategoryStyle(
                    icon = Icons.Default.Wifi,
                    containerColor = colorInternet.copy(alpha = 0.2f),
                    contentColor = colorInternet,
                    emoji = "📶"
                )
            }
            lowerCaseName.contains("مطعم") || lowerCaseName.contains("أكل") || lowerCaseName.contains("طعام") || lowerCaseName.contains("كافيه") -> {
                CategoryStyle(
                    icon = Icons.Default.Fastfood,
                    containerColor = colorCharity.copy(alpha = 0.2f),
                    contentColor = colorCharity,
                    emoji = "🍔"
                )
            }
            lowerCaseName.contains("جامعة") || lowerCaseName.contains("مدرسة") || lowerCaseName.contains("تعليم") || lowerCaseName.contains("معهد") -> {
                CategoryStyle(
                    icon = Icons.Default.School,
                    containerColor = colorEducation.copy(alpha = 0.2f),
                    contentColor = colorEducation,
                    emoji = "📚"
                )
            }
            lowerCaseName.contains("مواصلات") || lowerCaseName.contains("بترول") || lowerCaseName.contains("محطة") || lowerCaseName.contains("بنزين") -> {
                CategoryStyle(
                    icon = Icons.Default.DirectionsCar,
                    containerColor = colorGov.copy(alpha = 0.2f),
                    contentColor = colorGov,
                    emoji = "🚗"
                )
            }
            lowerCaseName.contains("بقالة") || lowerCaseName.contains("سوبر ماركت") -> {
                CategoryStyle(
                    icon = Icons.Default.ShoppingCart,
                    containerColor = colorDefault.copy(alpha = 0.2f),
                    contentColor = colorDefault,
                    emoji = "🛒"
                )
            }
            lowerCaseName.contains("صيدلية") || lowerCaseName.contains("علاج") || lowerCaseName.contains("مستشفى") -> {
                CategoryStyle(
                    icon = Icons.Default.LocalPharmacy,
                    containerColor = colorTelecom.copy(alpha = 0.2f),
                    contentColor = colorTelecom,
                    emoji = "💊"
                )
            }
            lowerCaseName.contains("ببجي") || lowerCaseName.contains("جوجل بلاي") || lowerCaseName.contains("ترفيه") -> {
                CategoryStyle(
                    icon = Icons.Default.SportsEsports,
                    containerColor = colorGaming.copy(alpha = 0.2f),
                    contentColor = colorGaming,
                    emoji = "🎮"
                )
            }
            lowerCaseName.contains("جوازات") || lowerCaseName.contains("مرور") || lowerCaseName.contains("حكومي") -> {
                CategoryStyle(
                    icon = Icons.Default.AccountBalance,
                    containerColor = colorGov.copy(alpha = 0.2f),
                    contentColor = colorGov,
                    emoji = "🏛️"
                )
            }
            lowerCaseName.contains("تبرع") || lowerCaseName.contains("زكاة") || lowerCaseName.contains("صدقة") -> {
                CategoryStyle(
                    icon = Icons.Default.Favorite,
                    containerColor = colorCharity.copy(alpha = 0.2f),
                    contentColor = colorCharity,
                    emoji = "❤️"
                )
            }
            isIncome -> {
                CategoryStyle(
                    icon = Icons.AutoMirrored.Default.TrendingUp,
                    containerColor = colorEducation.copy(alpha = 0.2f),
                    contentColor = colorEducation,
                    emoji = "📈"
                )
            }
            else -> {
                CategoryStyle(
                    icon = Icons.AutoMirrored.Default.TrendingDown,
                    containerColor = colorTelecom.copy(alpha = 0.2f),
                    contentColor = colorTelecom,
                    emoji = "📉"
                )
            }
        }
    }
}
