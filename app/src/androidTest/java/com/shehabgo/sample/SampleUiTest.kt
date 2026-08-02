package com.shehabgo.sample

import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import org.junit.Rule
import org.junit.Test

class SampleUiTest {
    @get:Rule
    val composeTestRule = createAndroidComposeRule<MainActivity>()

    @Test
    fun testAppLaunch() {
        // Since we can't easily grant notification access in tests without adb,
        // we check if either the dashboard or the permission guide is visible.

        try {
            composeTestRule.onNodeWithText("Smart Financial Tracker").assertIsDisplayed()
        } catch (e: AssertionError) {
            composeTestRule.onNodeWithText("Notification Access Required").assertIsDisplayed()
        }
    }
}
