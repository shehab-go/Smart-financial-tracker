package com.financial.tracker.module.parser

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Test

class DynamicParserTest {
    @Test
    fun testSTCPayParsing() {
        val packageName = "com.stc.pay"
        val title = "stc pay"
        val text = "Purchase at Merchant with amount 150.00 SAR. Ref: 12345"

        // Mock config for STC Pay
        val configJson =
            """
            {
                "packageName": "com.stc.pay",
                "rules": [
                    {
                        "identifierRegex": "Purchase at .* amount",
                        "transactionType": "Purchase",
                        "parsers": {
                            "amount": "amount\\s+(?<value>[0-9.]+)",
                            "currency": "amount\\s+[0-9.]+\\s+(?<value>[A-Z]{3})",
                            "counterpart": "Purchase at\\s+(?<value>.*?)\\s+with",
                            "referenceId": "Ref:\\s+(?<value>[0-9]+)"
                        }
                    }
                ]
            }
            """.trimIndent()

        val result = DynamicParser.parse(packageName, title, text, configJson)

        assertNotNull("Result should not be null", result)
        assertEquals(150.0, result?.amount ?: 0.0, 0.0)
        assertEquals("SAR", result?.currency)
        assertEquals("Merchant", result?.counterpart)
        assertEquals("12345", result?.referenceId)
    }
}
