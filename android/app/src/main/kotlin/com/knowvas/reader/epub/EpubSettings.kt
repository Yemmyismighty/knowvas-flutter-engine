package com.knowvas.reader.epub

import android.graphics.Color
import org.readium.r2.navigator.epub.EpubNavigatorFragment
import org.readium.r2.shared.publication.epub.EpubLayout
import org.readium.r2.shared.publication.presentation.Presentation
import org.readium.r2.shared.publication.presentation.presentation

/**
 * EpubSettings manages reader preferences for EPUB content
 * Handles font size, font family, theme, line height, margins, and layout
 * Applies settings to Readium navigator in real-time
 */
class EpubSettings {
    
    // Font size range: 12-32px
    var fontSize: Int = 16
        set(value) {
            field = value.coerceIn(MIN_FONT_SIZE, MAX_FONT_SIZE)
        }
    
    // Font family options: serif, sans-serif, monospace
    var fontFamily: FontFamily = FontFamily.SERIF
    
    // Theme options: light, sepia, dark
    var theme: Theme = Theme.LIGHT
    
    // Line height multiplier (1.0 = normal, 1.5 = 150%, etc.)
    var lineHeight: Double = 1.5
        set(value) {
            field = value.coerceIn(MIN_LINE_HEIGHT, MAX_LINE_HEIGHT)
        }
    
    // Margin multiplier (0.5 = 50%, 1.0 = 100%, 2.0 = 200%)
    var margin: Double = 1.0
        set(value) {
            field = value.coerceIn(MIN_MARGIN, MAX_MARGIN)
        }
    
    // Layout mode: single page or double page spread
    var layout: LayoutMode = LayoutMode.SINGLE
    
    companion object {
        const val MIN_FONT_SIZE = 12
        const val MAX_FONT_SIZE = 32
        const val MIN_LINE_HEIGHT = 1.0
        const val MAX_LINE_HEIGHT = 2.5
        const val MIN_MARGIN = 0.5
        const val MAX_MARGIN = 2.0
    }
    
    /**
     * Font family enumeration
     */
    enum class FontFamily(val cssValue: String) {
        SERIF("serif"),
        SANS_SERIF("sans-serif"),
        MONOSPACE("monospace");
        
        companion object {
            fun fromString(value: String): FontFamily {
                return when (value.lowercase()) {
                    "serif" -> SERIF
                    "sans-serif", "sans_serif" -> SANS_SERIF
                    "monospace" -> MONOSPACE
                    else -> SERIF
                }
            }
        }
    }
    
    /**
     * Theme enumeration with color definitions
     */
    enum class Theme(
        val backgroundColor: Int,
        val textColor: Int,
        val cssClass: String
    ) {
        LIGHT(
            backgroundColor = Color.WHITE,
            textColor = Color.BLACK,
            cssClass = "light-theme"
        ),
        SEPIA(
            backgroundColor = Color.parseColor("#F4ECD8"),
            textColor = Color.parseColor("#5B4636"),
            cssClass = "sepia-theme"
        ),
        DARK(
            backgroundColor = Color.parseColor("#1E1E1E"),
            textColor = Color.parseColor("#E0E0E0"),
            cssClass = "dark-theme"
        );
        
        companion object {
            fun fromString(value: String): Theme {
                return when (value.lowercase()) {
                    "light" -> LIGHT
                    "sepia" -> SEPIA
                    "dark" -> DARK
                    else -> LIGHT
                }
            }
        }
    }
    
    /**
     * Layout mode enumeration
     */
    enum class LayoutMode {
        SINGLE,
        DOUBLE;
        
        companion object {
            fun fromString(value: String): LayoutMode {
                return when (value.lowercase()) {
                    "single" -> SINGLE
                    "double", "spread" -> DOUBLE
                    else -> SINGLE
                }
            }
        }
    }
    
    /**
     * Update settings from a map of preferences
     * @param preferences Map containing preference key-value pairs
     */
    fun updateFromMap(preferences: Map<*, *>) {
        preferences["font_size"]?.let { 
            fontSize = (it as? Number)?.toInt() ?: fontSize
        }
        
        preferences["font_family"]?.let { 
            fontFamily = FontFamily.fromString(it.toString())
        }
        
        preferences["theme"]?.let { 
            theme = Theme.fromString(it.toString())
        }
        
        preferences["line_height"]?.let { 
            lineHeight = (it as? Number)?.toDouble() ?: lineHeight
        }
        
        preferences["margin"]?.let { 
            margin = (it as? Number)?.toDouble() ?: margin
        }
        
        preferences["layout"]?.let { 
            layout = LayoutMode.fromString(it.toString())
        }
    }
    
    /**
     * Generate CSS string to apply settings
     * This CSS will be injected into the EPUB content
     */
    fun generateCSS(): String {
        return """
            :root {
                --font-size: ${fontSize}px;
                --font-family: ${fontFamily.cssValue};
                --line-height: $lineHeight;
                --margin-multiplier: $margin;
                --background-color: ${colorToHex(theme.backgroundColor)};
                --text-color: ${colorToHex(theme.textColor)};
            }
            
            body {
                font-size: var(--font-size) !important;
                font-family: var(--font-family) !important;
                line-height: var(--line-height) !important;
                background-color: var(--background-color) !important;
                color: var(--text-color) !important;
                margin-left: calc(1rem * var(--margin-multiplier)) !important;
                margin-right: calc(1rem * var(--margin-multiplier)) !important;
                padding-left: calc(1rem * var(--margin-multiplier)) !important;
                padding-right: calc(1rem * var(--margin-multiplier)) !important;
            }
            
            p, div, span {
                font-size: inherit !important;
                font-family: inherit !important;
                line-height: inherit !important;
            }
            
            h1, h2, h3, h4, h5, h6 {
                font-family: inherit !important;
                line-height: calc(var(--line-height) * 0.9) !important;
            }
        """.trimIndent()
    }
    
    /**
     * Convert Android Color int to hex string
     */
    private fun colorToHex(color: Int): String {
        return String.format("#%06X", 0xFFFFFF and color)
    }
    
    /**
     * Create a copy of current settings
     */
    fun copy(): EpubSettings {
        return EpubSettings().apply {
            fontSize = this@EpubSettings.fontSize
            fontFamily = this@EpubSettings.fontFamily
            theme = this@EpubSettings.theme
            lineHeight = this@EpubSettings.lineHeight
            margin = this@EpubSettings.margin
            layout = this@EpubSettings.layout
        }
    }
    
    /**
     * Convert settings to a map for serialization
     */
    fun toMap(): Map<String, Any> {
        return mapOf(
            "font_size" to fontSize,
            "font_family" to fontFamily.cssValue,
            "theme" to theme.name.lowercase(),
            "line_height" to lineHeight,
            "margin" to margin,
            "layout" to layout.name.lowercase()
        )
    }
    
    override fun toString(): String {
        return "EpubSettings(fontSize=$fontSize, fontFamily=$fontFamily, " +
                "theme=$theme, lineHeight=$lineHeight, margin=$margin, layout=$layout)"
    }
}
