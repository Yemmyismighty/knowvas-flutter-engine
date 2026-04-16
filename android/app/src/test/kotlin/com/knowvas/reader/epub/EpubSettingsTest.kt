package com.knowvas.reader.epub

import android.graphics.Color
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for EpubSettings
 * Tests font size, font family, theme, line height, margin, and layout settings
 */
class EpubSettingsTest {

    private lateinit var settings: EpubSettings

    @Before
    fun setUp() {
        settings = EpubSettings()
    }

    @Test
    fun testDefaultSettings() {
        assertEquals(16, settings.fontSize)
        assertEquals(EpubSettings.FontFamily.SERIF, settings.fontFamily)
        assertEquals(EpubSettings.Theme.LIGHT, settings.theme)
        assertEquals(1.5, settings.lineHeight, 0.001)
        assertEquals(1.0, settings.margin, 0.001)
        assertEquals(EpubSettings.LayoutMode.SINGLE, settings.layout)
    }

    @Test
    fun testFontSizeRange() {
        // Test minimum
        settings.fontSize = 10
        assertEquals(EpubSettings.MIN_FONT_SIZE, settings.fontSize)

        // Test maximum
        settings.fontSize = 40
        assertEquals(EpubSettings.MAX_FONT_SIZE, settings.fontSize)

        // Test valid value
        settings.fontSize = 20
        assertEquals(20, settings.fontSize)
    }

    @Test
    fun testFontFamilyFromString() {
        assertEquals(EpubSettings.FontFamily.SERIF, 
            EpubSettings.FontFamily.fromString("serif"))
        assertEquals(EpubSettings.FontFamily.SANS_SERIF, 
            EpubSettings.FontFamily.fromString("sans-serif"))
        assertEquals(EpubSettings.FontFamily.SANS_SERIF, 
            EpubSettings.FontFamily.fromString("sans_serif"))
        assertEquals(EpubSettings.FontFamily.MONOSPACE, 
            EpubSettings.FontFamily.fromString("monospace"))
        assertEquals(EpubSettings.FontFamily.SERIF, 
            EpubSettings.FontFamily.fromString("invalid"))
    }

    @Test
    fun testThemeFromString() {
        assertEquals(EpubSettings.Theme.LIGHT, 
            EpubSettings.Theme.fromString("light"))
        assertEquals(EpubSettings.Theme.SEPIA, 
            EpubSettings.Theme.fromString("sepia"))
        assertEquals(EpubSettings.Theme.DARK, 
            EpubSettings.Theme.fromString("dark"))
        assertEquals(EpubSettings.Theme.LIGHT, 
            EpubSettings.Theme.fromString("invalid"))
    }

    @Test
    fun testThemeColors() {
        val lightTheme = EpubSettings.Theme.LIGHT
        assertEquals(Color.WHITE, lightTheme.backgroundColor)
        assertEquals(Color.BLACK, lightTheme.textColor)

        val darkTheme = EpubSettings.Theme.DARK
        assertEquals(Color.parseColor("#1E1E1E"), darkTheme.backgroundColor)
        assertEquals(Color.parseColor("#E0E0E0"), darkTheme.textColor)

        val sepiaTheme = EpubSettings.Theme.SEPIA
        assertEquals(Color.parseColor("#F4ECD8"), sepiaTheme.backgroundColor)
        assertEquals(Color.parseColor("#5B4636"), sepiaTheme.textColor)
    }

    @Test
    fun testLayoutModeFromString() {
        assertEquals(EpubSettings.LayoutMode.SINGLE, 
            EpubSettings.LayoutMode.fromString("single"))
        assertEquals(EpubSettings.LayoutMode.DOUBLE, 
            EpubSettings.LayoutMode.fromString("double"))
        assertEquals(EpubSettings.LayoutMode.DOUBLE, 
            EpubSettings.LayoutMode.fromString("spread"))
        assertEquals(EpubSettings.LayoutMode.SINGLE, 
            EpubSettings.LayoutMode.fromString("invalid"))
    }

    @Test
    fun testLineHeightRange() {
        // Test minimum
        settings.lineHeight = 0.5
        assertEquals(EpubSettings.MIN_LINE_HEIGHT, settings.lineHeight, 0.001)

        // Test maximum
        settings.lineHeight = 3.0
        assertEquals(EpubSettings.MAX_LINE_HEIGHT, settings.lineHeight, 0.001)

        // Test valid value
        settings.lineHeight = 1.8
        assertEquals(1.8, settings.lineHeight, 0.001)
    }

    @Test
    fun testMarginRange() {
        // Test minimum
        settings.margin = 0.2
        assertEquals(EpubSettings.MIN_MARGIN, settings.margin, 0.001)

        // Test maximum
        settings.margin = 3.0
        assertEquals(EpubSettings.MAX_MARGIN, settings.margin, 0.001)

        // Test valid value
        settings.margin = 1.5
        assertEquals(1.5, settings.margin, 0.001)
    }

    @Test
    fun testUpdateFromMap() {
        val preferences = mapOf(
            "font_size" to 24,
            "font_family" to "sans-serif",
            "theme" to "dark",
            "line_height" to 2.0,
            "margin" to 1.5,
            "layout" to "double"
        )

        settings.updateFromMap(preferences)

        assertEquals(24, settings.fontSize)
        assertEquals(EpubSettings.FontFamily.SANS_SERIF, settings.fontFamily)
        assertEquals(EpubSettings.Theme.DARK, settings.theme)
        assertEquals(2.0, settings.lineHeight, 0.001)
        assertEquals(1.5, settings.margin, 0.001)
        assertEquals(EpubSettings.LayoutMode.DOUBLE, settings.layout)
    }

    @Test
    fun testUpdateFromMapWithInvalidValues() {
        val preferences = mapOf(
            "font_size" to "not a number",
            "font_family" to "invalid",
            "theme" to "invalid"
        )

        settings.updateFromMap(preferences)

        // Should keep default values when invalid
        assertEquals(16, settings.fontSize)
        assertEquals(EpubSettings.FontFamily.SERIF, settings.fontFamily)
        assertEquals(EpubSettings.Theme.LIGHT, settings.theme)
    }

    @Test
    fun testGenerateCSS() {
        settings.fontSize = 18
        settings.fontFamily = EpubSettings.FontFamily.SANS_SERIF
        settings.theme = EpubSettings.Theme.DARK
        settings.lineHeight = 1.8
        settings.margin = 1.2

        val css = settings.generateCSS()

        assertTrue(css.contains("--font-size: 18px"))
        assertTrue(css.contains("--font-family: sans-serif"))
        assertTrue(css.contains("--line-height: 1.8"))
        assertTrue(css.contains("--margin-multiplier: 1.2"))
        assertTrue(css.contains("font-size: var(--font-size) !important"))
        assertTrue(css.contains("background-color: var(--background-color) !important"))
    }

    @Test
    fun testToMap() {
        settings.fontSize = 20
        settings.fontFamily = EpubSettings.FontFamily.MONOSPACE
        settings.theme = EpubSettings.Theme.SEPIA
        settings.lineHeight = 1.6
        settings.margin = 1.3
        settings.layout = EpubSettings.LayoutMode.DOUBLE

        val map = settings.toMap()

        assertEquals(20, map["font_size"])
        assertEquals("monospace", map["font_family"])
        assertEquals("sepia", map["theme"])
        assertEquals(1.6, map["line_height"])
        assertEquals(1.3, map["margin"])
        assertEquals("double", map["layout"])
    }

    @Test
    fun testCopy() {
        settings.fontSize = 22
        settings.fontFamily = EpubSettings.FontFamily.SANS_SERIF
        settings.theme = EpubSettings.Theme.DARK

        val copy = settings.copy()

        assertEquals(settings.fontSize, copy.fontSize)
        assertEquals(settings.fontFamily, copy.fontFamily)
        assertEquals(settings.theme, copy.theme)
        assertEquals(settings.lineHeight, copy.lineHeight, 0.001)
        assertEquals(settings.margin, copy.margin, 0.001)
        assertEquals(settings.layout, copy.layout)

        // Verify it's a true copy
        copy.fontSize = 14
        assertNotEquals(settings.fontSize, copy.fontSize)
    }

    @Test
    fun testToString() {
        val str = settings.toString()
        assertTrue(str.contains("EpubSettings"))
        assertTrue(str.contains("fontSize="))
        assertTrue(str.contains("fontFamily="))
        assertTrue(str.contains("theme="))
        assertTrue(str.contains("lineHeight="))
        assertTrue(str.contains("margin="))
        assertTrue(str.contains("layout="))
    }
}
