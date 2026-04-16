package com.knowvas.reader.ui

import android.app.Dialog
import android.content.Context
import android.graphics.Color
import android.view.View
import android.view.ViewGroup
import android.widget.*
import androidx.core.content.ContextCompat
import com.knowvas.reader.epub.EpubReader
import com.knowvas.app.R

/**
 * Settings dialog for EPUB reader with comprehensive Readium options
 */
class EpubSettingsDialog(
    private val context: Context,
    private val epubReader: EpubReader,
    private val onSettingsChanged: (Map<String, Any>) -> Unit
) : Dialog(context, android.R.style.Theme_Black_NoTitleBar_Fullscreen) {

    private lateinit var rootLayout: LinearLayout
    private lateinit var tabLayout: LinearLayout
    private lateinit var contentContainer: FrameLayout
    
    // Tab buttons
    private lateinit var displayTab: TextView
    private lateinit var layoutTab: TextView
    private lateinit var behaviorTab: TextView
    
    // Current settings
    private val currentSettings = mutableMapOf<String, Any>()
    
    init {
        createDialog()
        loadCurrentSettings()
        showDisplaySettings() // Show display tab by default
    }
    
    private fun createDialog() {
        // Create root layout
        rootLayout = LinearLayout(context).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#1A1A1A"))
        }
        
        // Create header with close button
        createHeader()
        
        // Create tab layout
        createTabLayout()
        
        // Create content container
        contentContainer = FrameLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                0,
                1f
            )
        }
        
        rootLayout.addView(contentContainer)
        setContentView(rootLayout)
    }
    
    private fun createHeader() {
        val header = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(64)
            )
            orientation = LinearLayout.HORIZONTAL
            gravity = android.view.Gravity.CENTER_VERTICAL
            setBackgroundColor(Color.parseColor("#2A2A2A"))
            setPadding(dpToPx(16), 0, dpToPx(16), 0)
        }
        
        // Title
        val title = TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            text = "Reader Settings"
            textSize = 20f
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        
        // Close button
        val closeButton = ImageButton(context).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(40), dpToPx(40))
            setBackgroundResource(android.R.drawable.btn_default)
            setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            setColorFilter(Color.WHITE)
            contentDescription = "Close"
            setOnClickListener { dismiss() }
        }
        
        header.addView(title)
        header.addView(closeButton)
        rootLayout.addView(header)
    }
    
    private fun createTabLayout() {
        tabLayout = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(48)
            )
            orientation = LinearLayout.HORIZONTAL
            setBackgroundColor(Color.parseColor("#333333"))
        }
        
        // Display tab
        displayTab = createTabButton("Display", true)
        displayTab.setOnClickListener { 
            selectTab(displayTab)
            showDisplaySettings() 
        }
        
        // Layout tab
        layoutTab = createTabButton("Layout", false)
        layoutTab.setOnClickListener { 
            selectTab(layoutTab)
            showLayoutSettings() 
        }
        
        // Behavior tab
        behaviorTab = createTabButton("Behavior", false)
        behaviorTab.setOnClickListener { 
            selectTab(behaviorTab)
            showBehaviorSettings() 
        }
        
        tabLayout.addView(displayTab)
        tabLayout.addView(layoutTab)
        tabLayout.addView(behaviorTab)
        rootLayout.addView(tabLayout)
    }
    
    private fun createTabButton(text: String, selected: Boolean): TextView {
        return TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.MATCH_PARENT, 1f)
            this.text = text
            textSize = 16f
            gravity = android.view.Gravity.CENTER
            setTextColor(if (selected) Color.parseColor("#FF6B35") else Color.WHITE)
            setBackgroundColor(if (selected) Color.parseColor("#404040") else Color.TRANSPARENT)
            typeface = if (selected) android.graphics.Typeface.DEFAULT_BOLD else android.graphics.Typeface.DEFAULT
        }
    }
    
    private fun selectTab(selectedTab: TextView) {
        // Reset all tabs
        listOf(displayTab, layoutTab, behaviorTab).forEach { tab ->
            tab.setTextColor(Color.WHITE)
            tab.setBackgroundColor(Color.TRANSPARENT)
            tab.typeface = android.graphics.Typeface.DEFAULT
        }
        
        // Highlight selected tab
        selectedTab.setTextColor(Color.parseColor("#FF6B35"))
        selectedTab.setBackgroundColor(Color.parseColor("#404040"))
        selectedTab.typeface = android.graphics.Typeface.DEFAULT_BOLD
    }
    
    private fun showDisplaySettings() {
        contentContainer.removeAllViews()
        
        val scrollView = ScrollView(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        
        val container = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(16), dpToPx(16), dpToPx(16), dpToPx(16))
        }
        
        // Theme selection
        container.addView(createSectionTitle("Theme"))
        container.addView(createThemeSelector())
        
        // Font settings
        container.addView(createSectionTitle("Font"))
        container.addView(createFontFamilySelector())
        container.addView(createSliderSetting("Font Size", "font_size", 12f, 32f, 18f, "sp"))
        container.addView(createSliderSetting("Line Height", "line_height", 1.0f, 2.0f, 1.4f, "x"))
        
        // Spacing settings
        container.addView(createSectionTitle("Spacing"))
        container.addView(createSliderSetting("Letter Spacing", "letter_spacing", -0.1f, 0.3f, 0f, "em"))
        container.addView(createSliderSetting("Word Spacing", "word_spacing", -0.2f, 1.0f, 0f, "em"))
        container.addView(createSliderSetting("Paragraph Spacing", "paragraph_spacing", 0f, 2.0f, 1.0f, "em"))
        
        // Brightness
        container.addView(createSectionTitle("Display"))
        container.addView(createSliderSetting("Brightness", "brightness", 0.1f, 1.0f, 0.8f, "%"))
        
        scrollView.addView(container)
        contentContainer.addView(scrollView)
    }
    
    private fun showLayoutSettings() {
        contentContainer.removeAllViews()
        
        val scrollView = ScrollView(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        
        val container = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(16), dpToPx(16), dpToPx(16), dpToPx(16))
        }
        
        // Reading mode
        container.addView(createSectionTitle("Reading Mode"))
        container.addView(createReadingModeSelector())
        
        // Page layout
        container.addView(createSectionTitle("Page Layout"))
        container.addView(createToggleSetting("Double Page", "double_page", false))
        container.addView(createToggleSetting("Spread", "spread", false))
        
        // Margins
        container.addView(createSectionTitle("Margins"))
        container.addView(createSliderSetting("Horizontal Margin", "margin_horizontal", 0f, 100f, 20f, "px"))
        container.addView(createSliderSetting("Vertical Margin", "margin_vertical", 0f, 100f, 20f, "px"))
        
        // Column settings
        container.addView(createSectionTitle("Columns"))
        container.addView(createSliderSetting("Column Count", "column_count", 1f, 3f, 1f, ""))
        container.addView(createSliderSetting("Column Gap", "column_gap", 10f, 50f, 20f, "px"))
        
        scrollView.addView(container)
        contentContainer.addView(scrollView)
    }
    
    private fun showBehaviorSettings() {
        contentContainer.removeAllViews()
        
        val scrollView = ScrollView(context).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
        }
        
        val container = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(16), dpToPx(16), dpToPx(16), dpToPx(16))
        }
        
        // Navigation
        container.addView(createSectionTitle("Navigation"))
        container.addView(createToggleSetting("Tap to Turn Page", "tap_to_turn", true))
        container.addView(createToggleSetting("Swipe to Turn Page", "swipe_to_turn", true))
        container.addView(createToggleSetting("Volume Keys Navigation", "volume_keys", false))
        
        // Animations
        container.addView(createSectionTitle("Animations"))
        container.addView(createToggleSetting("Page Turn Animation", "page_animation", true))
        container.addView(createSliderSetting("Animation Speed", "animation_speed", 0.5f, 2.0f, 1.0f, "x"))
        
        // Accessibility
        container.addView(createSectionTitle("Accessibility"))
        container.addView(createToggleSetting("High Contrast", "high_contrast", false))
        container.addView(createToggleSetting("Reduce Motion", "reduce_motion", false))
        container.addView(createToggleSetting("Screen Reader Support", "screen_reader", false))
        
        // Auto features
        container.addView(createSectionTitle("Auto Features"))
        container.addView(createToggleSetting("Auto-hide Controls", "auto_hide_controls", true))
        container.addView(createToggleSetting("Keep Screen On", "keep_screen_on", true))
        
        scrollView.addView(container)
        contentContainer.addView(scrollView)
    }
    
    private fun createSectionTitle(title: String): TextView {
        return TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                topMargin = dpToPx(24)
                bottomMargin = dpToPx(12)
            }
            text = title
            textSize = 18f
            setTextColor(Color.parseColor("#FF6B35"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
    }
    
    private fun createThemeSelector(): LinearLayout {
        val container = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            orientation = LinearLayout.HORIZONTAL
        }
        
        val themes = listOf(
            "Light" to "#FFFFFF",
            "Sepia" to "#F4F1E8", 
            "Dark" to "#1A1A1A",
            "Black" to "#000000"
        )
        
        themes.forEach { (name, color) ->
            val button = Button(context).apply {
                layoutParams = LinearLayout.LayoutParams(0, dpToPx(48), 1f).apply {
                    marginEnd = dpToPx(8)
                }
                text = name
                textSize = 14f
                setBackgroundColor(Color.parseColor(color))
                setTextColor(if (color == "#FFFFFF" || color == "#F4F1E8") Color.BLACK else Color.WHITE)
                setOnClickListener {
                    currentSettings["theme"] = name.lowercase()
                    applySettings()
                }
            }
            container.addView(button)
        }
        
        return container
    }
    
    private fun createFontFamilySelector(): Spinner {
        val spinner = Spinner(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(48)
            ).apply {
                bottomMargin = dpToPx(16)
            }
        }
        
        val fonts = arrayOf("Default", "Serif", "Sans-serif", "Monospace", "OpenDyslexic")
        val adapter = ArrayAdapter(context, android.R.layout.simple_spinner_item, fonts)
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item)
        spinner.adapter = adapter
        
        spinner.onItemSelectedListener = object : AdapterView.OnItemSelectedListener {
            override fun onItemSelected(parent: AdapterView<*>?, view: View?, position: Int, id: Long) {
                currentSettings["font_family"] = fonts[position].lowercase()
                applySettings()
            }
            override fun onNothingSelected(parent: AdapterView<*>?) {}
        }
        
        return spinner
    }
    
    private fun createReadingModeSelector(): LinearLayout {
        val container = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            orientation = LinearLayout.HORIZONTAL
        }
        
        val modes = listOf("Paginated", "Scrolling")
        
        modes.forEach { mode ->
            val button = Button(context).apply {
                layoutParams = LinearLayout.LayoutParams(0, dpToPx(48), 1f).apply {
                    marginEnd = dpToPx(8)
                }
                text = mode
                textSize = 14f
                setBackgroundColor(Color.parseColor("#404040"))
                setTextColor(Color.WHITE)
                setOnClickListener {
                    currentSettings["reading_mode"] = mode.lowercase()
                    applySettings()
                }
            }
            container.addView(button)
        }
        
        return container
    }
    
    private fun createSliderSetting(
        label: String, 
        key: String, 
        min: Float, 
        max: Float, 
        default: Float,
        unit: String
    ): LinearLayout {
        val container = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                bottomMargin = dpToPx(16)
            }
            orientation = LinearLayout.VERTICAL
        }
        
        // Label and value
        val labelContainer = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            orientation = LinearLayout.HORIZONTAL
        }
        
        val labelText = TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            text = label
            textSize = 16f
            setTextColor(Color.WHITE)
        }
        
        val valueText = TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            text = "${default.toInt()}$unit"
            textSize = 16f
            setTextColor(Color.parseColor("#FF6B35"))
            typeface = android.graphics.Typeface.DEFAULT_BOLD
        }
        
        labelContainer.addView(labelText)
        labelContainer.addView(valueText)
        
        // Slider
        val slider = SeekBar(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            this.max = ((max - min) * 10).toInt()
            progress = ((default - min) * 10).toInt()
            progressTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#FF6B35"))
            thumbTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#FF6B35"))
            
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    if (fromUser) {
                        val value = min + (progress / 10f)
                        valueText.text = "${value.toInt()}$unit"
                        currentSettings[key] = value
                        applySettings()
                    }
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })
        }
        
        container.addView(labelContainer)
        container.addView(slider)
        return container
    }
    
    private fun createToggleSetting(label: String, key: String, default: Boolean): LinearLayout {
        val container = LinearLayout(context).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                dpToPx(48)
            ).apply {
                bottomMargin = dpToPx(8)
            }
            orientation = LinearLayout.HORIZONTAL
            gravity = android.view.Gravity.CENTER_VERTICAL
        }
        
        val labelText = TextView(context).apply {
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f)
            text = label
            textSize = 16f
            setTextColor(Color.WHITE)
        }
        
        val toggle = Switch(context).apply {
            isChecked = default
            thumbTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#FF6B35"))
            trackTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#404040"))
            
            setOnCheckedChangeListener { _, isChecked ->
                currentSettings[key] = isChecked
                applySettings()
            }
        }
        
        container.addView(labelText)
        container.addView(toggle)
        return container
    }
    
    private fun loadCurrentSettings() {
        // Load current settings from EPUB reader
        val settings = epubReader.getSettingsMap()
        currentSettings.putAll(settings)
    }
    
    private fun applySettings() {
        // Apply settings to EPUB reader
        onSettingsChanged(currentSettings.toMap())
    }
    
    private fun dpToPx(dp: Int): Int {
        return (dp * context.resources.displayMetrics.density).toInt()
    }
}