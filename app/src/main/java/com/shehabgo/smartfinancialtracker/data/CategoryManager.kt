package com.shehabgo.smartfinancialtracker.data

import android.content.Context
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.rounded.*
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.toArgb
import androidx.compose.ui.graphics.vector.ImageVector
import com.google.gson.Gson
import com.google.gson.reflect.TypeToken
import com.shehabgo.smartfinancialtracker.ui.screens.categories.CategoryItem
import com.shehabgo.smartfinancialtracker.ui.screens.categories.defaultCategories

data class CategoryEntity(
    val id: Int,
    val name: String,
    val subtitle: String,
    val iconName: String,
    val colorValue: Long
)

object CategoryManager {
    private const val PREFS_NAME = "app_prefs"
    private const val KEY_CATEGORIES = "custom_categories"

    fun getCategories(context: Context): List<CategoryItem> {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val json = prefs.getString(KEY_CATEGORIES, null)
        if (json.isNullOrEmpty()) {
            return defaultCategories()
        }

        try {
            val type = object : TypeToken<List<CategoryEntity>>() {}.type
            val entities: List<CategoryEntity> = Gson().fromJson(json, type)
            return entities.map { it.toCategoryItem() }
        } catch (e: Exception) {
            e.printStackTrace()
            return defaultCategories()
        }
    }

    fun saveCategories(context: Context, categories: List<CategoryItem>) {
        val prefs = context.getSharedPreferences(PREFS_NAME, Context.MODE_PRIVATE)
        val entities = categories.map { it.toEntity() }
        val json = Gson().toJson(entities)
        prefs.edit().putString(KEY_CATEGORIES, json).apply()
    }

    private fun CategoryItem.toEntity(): CategoryEntity {
        return CategoryEntity(
            id = id,
            name = name,
            subtitle = subtitle,
            iconName = icon.name,
            colorValue = color.value.toLong()
        )
    }

    private fun CategoryEntity.toCategoryItem(): CategoryItem {
        return CategoryItem(
            id = id,
            name = name,
            subtitle = subtitle,
            icon = getIconByName(iconName),
            color = Color(colorValue.toULong())
        )
    }

    private fun getIconByName(name: String): ImageVector {
        // Fallback or exact match based on available icons in the app
        val map = mapOf(
            Icons.Rounded.ShoppingBasket.name to Icons.Rounded.ShoppingBasket,
            Icons.Rounded.CellTower.name to Icons.Rounded.CellTower,
            Icons.Rounded.Wifi.name to Icons.Rounded.Wifi,
            Icons.Rounded.Eco.name to Icons.Rounded.Eco,
            Icons.Rounded.LocalTaxi.name to Icons.Rounded.LocalTaxi,
            Icons.Rounded.Bolt.name to Icons.Rounded.Bolt,
            Icons.Rounded.Restaurant.name to Icons.Rounded.Restaurant,
            Icons.Rounded.Home.name to Icons.Rounded.Home,
            Icons.Rounded.School.name to Icons.Rounded.School,
            Icons.Rounded.HealthAndSafety.name to Icons.Rounded.HealthAndSafety,
            Icons.Rounded.Work.name to Icons.Rounded.Work,
            Icons.Rounded.SportsEsports.name to Icons.Rounded.SportsEsports,
            Icons.Rounded.FitnessCenter.name to Icons.Rounded.FitnessCenter,
            Icons.Rounded.Flight.name to Icons.Rounded.Flight,
            Icons.Rounded.Medication.name to Icons.Rounded.Medication,
            Icons.Rounded.Coffee.name to Icons.Rounded.Coffee,
            Icons.Rounded.SendToMobile.name to Icons.Rounded.SendToMobile,
            Icons.Rounded.LocalAtm.name to Icons.Rounded.LocalAtm,
            Icons.Rounded.VolunteerActivism.name to Icons.Rounded.VolunteerActivism
        )
        return map[name] ?: Icons.Rounded.ShoppingBasket
    }
}
