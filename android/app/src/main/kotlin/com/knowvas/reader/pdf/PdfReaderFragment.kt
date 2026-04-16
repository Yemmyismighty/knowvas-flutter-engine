package com.knowvas.reader.pdf

import android.graphics.Color
import android.os.Bundle
import android.view.GestureDetector
import android.view.Gravity
import android.view.LayoutInflater
import android.view.MotionEvent
import android.view.View
import android.view.ViewGroup
import android.widget.*
import androidx.core.content.ContextCompat
import androidx.fragment.app.Fragment
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import com.knowvas.app.R

/**
 * PDF Reader Fragment with controls
 * 
 * Requirements:
 * - 6.7: Tap-to-toggle controls and page transition options
 * - 6.8: Bookmark functionality
 * - 6.9: Text selection support (if PDF contains selectable text)
 */
class PdfReaderFragment : Fragment() {

    // PDF Reader instance
    private var pdfReader: PdfReader? = null
    
    // UI Components
    private lateinit var rootLayout: FrameLayout
    private lateinit var pdfPageView: PdfPageView
    private var pageCurlView: PageCurlView? = null  // Task 14: Optional curl view
    private lateinit var progressBar: ProgressBar
    
    // View mode
    private var useCurlAnimation = false  // Task 14: Toggle between simple and curl views
    
    // Control bars
    private lateinit var topBar: LinearLayout
    private lateinit var bottomBar: LinearLayout
    
    // Top bar components
    private lateinit var titleText: TextView
    private lateinit var bookmarkButton: ImageButton
    private lateinit var settingsButton: ImageButton
    private lateinit var closeButton: ImageButton
    
    // Bottom bar components
    private lateinit var pageNumberText: TextView
    private lateinit var progressSlider: SeekBar
    private lateinit var previousButton: ImageButton
    private lateinit var nextButton: ImageButton
    
    // State
    private var controlsVisible = true
    private var currentTheme = Theme.LIGHT
    private var pageTransitionMode = PageTransitionMode.SWIPE
    private val bookmarks = mutableSetOf<Int>()
    
    // Gesture detector for tap-to-toggle
    private lateinit var gestureDetector: GestureDetector
    
    // Auto-hide controls
    private val coroutineScope = CoroutineScope(Dispatchers.Main + Job())
    private var autoHideJob: Job? = null
    
    enum class Theme {
        LIGHT, DARK
    }
    
    enum class PageTransitionMode {
        SWIPE, CONTINUOUS_SCROLL, PAGE_CURL  // Task 14: Add page curl mode
    }
    
    companion object {
        private const val AUTO_HIDE_DELAY_MS = 3000L
        
        fun newInstance(pdfReader: PdfReader): PdfReaderFragment {
            return PdfReaderFragment().apply {
                this.pdfReader = pdfReader
            }
        }
    }
    
    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        // Create root layout
        rootLayout = FrameLayout(requireContext()).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT
            )
        }
        
        // Create PDF page view (simple view without curl)
        pdfPageView = PdfPageView(requireContext()).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                FrameLayout.LayoutParams.MATCH_PARENT
            )
            
            // Set zoom change callback
            onZoomChanged = { zoom ->
                android.util.Log.d("PdfReaderFragment", "Zoom changed to ${zoom}x")
            }
            
            // Set double-tap callback
            onDoubleTap = {
                android.util.Log.d("PdfReaderFragment", "Double-tap detected")
            }
        }
        
        // Task 14: Create page curl view (optional, created when needed)
        // This will be created when user switches to curl mode
        
        // Create progress bar
        progressBar = ProgressBar(requireContext()).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.WRAP_CONTENT,
                FrameLayout.LayoutParams.WRAP_CONTENT,
                Gravity.CENTER
            )
            visibility = View.GONE
        }
        
        // Create control bars
        createTopBar()
        createBottomBar()
        
        // Add views to root layout
        rootLayout.addView(pdfPageView)
        rootLayout.addView(progressBar)
        rootLayout.addView(topBar)
        rootLayout.addView(bottomBar)
        
        // Setup gesture detector for tap-to-toggle
        setupGestureDetector()
        
        // Apply initial theme
        applyTheme(currentTheme)
        
        // Load first page if PDF is ready
        android.util.Log.d("PdfReaderFragment", "onCreateView: Checking if PdfReader is available")
        pdfReader?.let { reader ->
            android.util.Log.d("PdfReaderFragment", "onCreateView: PdfReader available, loading first page")
            loadCurrentPage()
            updatePageInfo()
        } ?: run {
            android.util.Log.w("PdfReaderFragment", "onCreateView: PdfReader is NULL, cannot load page")
        }
        
        return rootLayout
    }
    
    /**
     * Create top control bar
     * Requirement 6.7: Toolbar with navigation and settings
     */
    private fun createTopBar() {
        topBar = LinearLayout(requireContext()).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                dpToPx(64),
                Gravity.TOP
            )
            orientation = LinearLayout.HORIZONTAL
            setPadding(dpToPx(16), dpToPx(8), dpToPx(16), dpToPx(8))
            elevation = dpToPx(8).toFloat()
            // Brand color background with transparency
            setBackgroundColor(Color.parseColor("#F8F7FF"))
        }
        
        // Close button with proper icon
        closeButton = createIconButton(android.R.drawable.ic_menu_close_clear_cancel) {
            // Close reader
            activity?.onBackPressed()
        }.apply {
            contentDescription = "Close"
        }
        
        // Title
        titleText = TextView(requireContext()).apply {
            layoutParams = LinearLayout.LayoutParams(
                0,
                LinearLayout.LayoutParams.WRAP_CONTENT,
                1f
            )
            text = "PDF Document"
            textSize = 18f
            setTextColor(Color.parseColor("#2D1D75"))
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
            setPadding(dpToPx(16), 0, dpToPx(16), 0)
            gravity = Gravity.CENTER_VERTICAL
        }
        
        // Bookmark button with proper icon
        bookmarkButton = createIconButton(android.R.drawable.btn_star_big_off) {
            toggleBookmark()
        }.apply {
            contentDescription = "Bookmark"
        }
        
        // Settings button with proper icon
        settingsButton = createIconButton(android.R.drawable.ic_menu_preferences) {
            showSettingsMenu()
        }.apply {
            contentDescription = "Settings"
        }
        
        topBar.addView(closeButton)
        topBar.addView(titleText)
        topBar.addView(bookmarkButton)
        topBar.addView(settingsButton)
    }
    
    /**
     * Create bottom control bar
     * Requirement 6.7: Progress slider and page navigation
     */
    private fun createBottomBar() {
        bottomBar = LinearLayout(requireContext()).apply {
            layoutParams = FrameLayout.LayoutParams(
                FrameLayout.LayoutParams.MATCH_PARENT,
                dpToPx(96),
                Gravity.BOTTOM
            )
            orientation = LinearLayout.VERTICAL
            setPadding(dpToPx(16), dpToPx(12), dpToPx(16), dpToPx(16))
            elevation = dpToPx(8).toFloat()
            // Brand color background with transparency
            setBackgroundColor(Color.parseColor("#F8F7FF"))
        }
        
        // Page number text
        pageNumberText = TextView(requireContext()).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            text = "Page 1 of 1"
            textSize = 14f
            setTextColor(Color.parseColor("#2D1D75"))
            typeface = android.graphics.Typeface.create("sans-serif-medium", android.graphics.Typeface.NORMAL)
            gravity = Gravity.CENTER
            setPadding(0, 0, 0, dpToPx(8))
        }
        
        // Progress slider with brand colors
        progressSlider = SeekBar(requireContext()).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            max = 100
            progress = 0
            
            // Style the progress bar with brand colors
            progressDrawable?.setColorFilter(
                Color.parseColor("#8576FF"),
                android.graphics.PorterDuff.Mode.SRC_IN
            )
            thumb?.setColorFilter(
                Color.parseColor("#8576FF"),
                android.graphics.PorterDuff.Mode.SRC_IN
            )
            
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    if (fromUser) {
                        val targetProgress = progress / 100.0
                        pdfReader?.setProgress(targetProgress)
                        loadCurrentPage()
                        updatePageInfo()
                    }
                }
                
                override fun onStartTrackingTouch(seekBar: SeekBar?) {
                    cancelAutoHide()
                }
                
                override fun onStopTrackingTouch(seekBar: SeekBar?) {
                    scheduleAutoHide()
                }
            })
        }
        
        // Navigation buttons container
        val navContainer = LinearLayout(requireContext()).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            orientation = LinearLayout.HORIZONTAL
            gravity = Gravity.CENTER
            setPadding(0, dpToPx(8), 0, 0)
        }
        
        // Previous button with proper icon
        previousButton = createIconButton(android.R.drawable.ic_media_previous) {
            navigateToPreviousPage()
        }.apply {
            contentDescription = "Previous page"
        }
        
        // Next button with proper icon
        nextButton = createIconButton(android.R.drawable.ic_media_next) {
            navigateToNextPage()
        }.apply {
            contentDescription = "Next page"
        }
        
        navContainer.addView(previousButton)
        navContainer.addView(nextButton)
        
        bottomBar.addView(pageNumberText)
        bottomBar.addView(progressSlider)
        bottomBar.addView(navContainer)
    }
    
    /**
     * Create an icon button with proper styling
     */
    private fun createIconButton(iconResource: Int, onClick: () -> Unit): ImageButton {
        return ImageButton(requireContext()).apply {
            layoutParams = LinearLayout.LayoutParams(
                dpToPx(48),
                dpToPx(48)
            ).apply {
                setMargins(dpToPx(4), dpToPx(4), dpToPx(4), dpToPx(4))
            }
            
            // Set the icon
            setImageResource(iconResource)
            
            // Style the button with brand colors
            setColorFilter(Color.parseColor("#8576FF"))
            
            // Rounded background with ripple effect
            background = createRippleDrawable()
            
            // Remove default padding
            setPadding(dpToPx(12), dpToPx(12), dpToPx(12), dpToPx(12))
            
            // Scale type for proper icon display
            scaleType = ImageView.ScaleType.FIT_CENTER
            
            setOnClickListener { onClick() }
        }
    }
    
    /**
     * Create a ripple drawable for button background
     */
    private fun createRippleDrawable(): android.graphics.drawable.Drawable {
        val shape = android.graphics.drawable.GradientDrawable().apply {
            shape = android.graphics.drawable.GradientDrawable.RECTANGLE
            cornerRadius = dpToPx(12).toFloat()
            setColor(Color.parseColor("#E9E7FF")) // Light brand color
        }
        
        return android.graphics.drawable.RippleDrawable(
            android.content.res.ColorStateList.valueOf(Color.parseColor("#8576FF")),
            shape,
            null
        )
    }
    
    /**
     * Setup gesture detector for tap-to-toggle controls
     * Requirement 6.7: Tap-to-toggle controls
     */
    private fun setupGestureDetector() {
        gestureDetector = GestureDetector(requireContext(), object : GestureDetector.SimpleOnGestureListener() {
            override fun onSingleTapConfirmed(e: MotionEvent): Boolean {
                // Only toggle if tap is in the center area (not on controls)
                val isInTopBar = e.y < dpToPx(64)
                val isInBottomBar = e.y > rootLayout.height - dpToPx(96)
                
                if (!isInTopBar && !isInBottomBar) {
                    // Toggle controls visibility on single tap in content area
                    toggleControls()
                    return true
                }
                return false
            }
            
            override fun onDown(e: MotionEvent): Boolean {
                return true
            }
        })
        
        // Apply gesture detector to the PDF page view only, not the whole layout
        pdfPageView.setOnTouchListener { _, event ->
            val handled = gestureDetector.onTouchEvent(event)
            if (!handled) {
                // Let the page view handle zoom/pan
                pdfPageView.onTouchEvent(event)
            }
            true
        }
    }
    
    /**
     * Toggle controls visibility
     * Requirement 6.7: Tap-to-toggle controls
     */
    private fun toggleControls() {
        controlsVisible = !controlsVisible
        
        topBar.visibility = if (controlsVisible) View.VISIBLE else View.GONE
        bottomBar.visibility = if (controlsVisible) View.VISIBLE else View.GONE
        
        if (controlsVisible) {
            scheduleAutoHide()
        } else {
            cancelAutoHide()
        }
        
        android.util.Log.d("PdfReaderFragment", "Controls ${if (controlsVisible) "shown" else "hidden"}")
    }
    
    /**
     * Schedule auto-hide of controls
     */
    private fun scheduleAutoHide() {
        cancelAutoHide()
        autoHideJob = coroutineScope.launch {
            delay(AUTO_HIDE_DELAY_MS)
            if (controlsVisible) {
                toggleControls()
            }
        }
    }
    
    /**
     * Cancel auto-hide of controls
     */
    private fun cancelAutoHide() {
        autoHideJob?.cancel()
        autoHideJob = null
    }
    
    /**
     * Navigate to previous page
     */
    private fun navigateToPreviousPage() {
        pdfReader?.let { reader ->
            if (reader.previousPage()) {
                loadCurrentPage()
                updatePageInfo()
                scheduleAutoHide()
            }
        }
    }
    
    /**
     * Navigate to next page
     */
    private fun navigateToNextPage() {
        pdfReader?.let { reader ->
            if (reader.nextPage()) {
                loadCurrentPage()
                updatePageInfo()
                scheduleAutoHide()
            }
        }
    }
    
    /**
     * Load current page into view
     * Task 14: Handle both simple and curl views
     */
    private fun loadCurrentPage() {
        android.util.Log.d("PdfReaderFragment", "loadCurrentPage: Starting to load page")
        
        pdfReader?.let { reader ->
            android.util.Log.d("PdfReaderFragment", "loadCurrentPage: PdfReader is available, current page = ${reader.getCurrentPage()}")
            progressBar.visibility = View.VISIBLE
            
            coroutineScope.launch(Dispatchers.IO) {
                android.util.Log.d("PdfReaderFragment", "loadCurrentPage: Rendering page on IO thread")
                val bitmap = reader.renderCurrentPage()
                
                android.util.Log.d("PdfReaderFragment", "loadCurrentPage: Bitmap rendered, size = ${bitmap?.width}x${bitmap?.height}, null = ${bitmap == null}")
                
                launch(Dispatchers.Main) {
                    progressBar.visibility = View.GONE
                    
                    if (bitmap == null) {
                        android.util.Log.e("PdfReaderFragment", "loadCurrentPage: Bitmap is null! Cannot display page")
                        Toast.makeText(requireContext(), "Failed to load PDF page", Toast.LENGTH_SHORT).show()
                        return@launch
                    }
                    
                    // Task 14: Update the appropriate view based on mode
                    if (useCurlAnimation && pageCurlView != null) {
                        android.util.Log.d("PdfReaderFragment", "loadCurrentPage: Setting bitmap to PageCurlView")
                        // Curl view loads pages automatically from PdfReader
                        // Just trigger a reload
                        pageCurlView?.setCurrentPage(bitmap)
                    } else {
                        android.util.Log.d("PdfReaderFragment", "loadCurrentPage: Setting bitmap to PdfPageView")
                        // Simple view
                        pdfPageView.setPageBitmap(bitmap)
                    }
                    
                    updateBookmarkButton()
                    android.util.Log.d("PdfReaderFragment", "loadCurrentPage: Page loaded successfully")
                }
            }
        } ?: run {
            android.util.Log.e("PdfReaderFragment", "loadCurrentPage: PdfReader is NULL!")
            Toast.makeText(requireContext(), "PDF Reader not initialized", Toast.LENGTH_SHORT).show()
        }
    }
    
    /**
     * Update page information display
     */
    private fun updatePageInfo() {
        pdfReader?.let { reader ->
            val currentPage = reader.getCurrentPage() + 1
            val totalPages = reader.getTotalPages()
            
            pageNumberText.text = "Page $currentPage of $totalPages"
            
            val progress = (reader.getProgress() * 100).toInt()
            progressSlider.progress = progress
            
            // Update navigation buttons
            previousButton.isEnabled = currentPage > 1
            nextButton.isEnabled = currentPage < totalPages
        }
    }
    
    /**
     * Toggle bookmark for current page
     * Requirement 6.8: Bookmark functionality
     */
    private fun toggleBookmark() {
        pdfReader?.let { reader ->
            val currentPage = reader.getCurrentPage()
            
            if (bookmarks.contains(currentPage)) {
                bookmarks.remove(currentPage)
                Toast.makeText(requireContext(), "Bookmark removed", Toast.LENGTH_SHORT).show()
            } else {
                bookmarks.add(currentPage)
                Toast.makeText(requireContext(), "Bookmark added", Toast.LENGTH_SHORT).show()
                
                // Emit bookmark event
                reader.emitEvent(mapOf(
                    "type" to "engagement",
                    "session_id" to reader.sessionId,
                    "event" to "bookmark",
                    "page_number" to currentPage,
                    "timestamp" to System.currentTimeMillis()
                ))
            }
            
            updateBookmarkButton()
        }
    }
    
    /**
     * Update bookmark button appearance
     */
    private fun updateBookmarkButton() {
        pdfReader?.let { reader ->
            val currentPage = reader.getCurrentPage()
            val isBookmarked = bookmarks.contains(currentPage)
            
            // Update button appearance based on bookmark state
            // In a real implementation, you would change the icon or color
            bookmarkButton.alpha = if (isBookmarked) 1.0f else 0.5f
        }
    }
    
    /**
     * Show settings menu
     * Requirement 6.7: Settings for page transition and theme
     * Task 14: Add page curl option
     */
    private fun showSettingsMenu() {
        val popup = PopupMenu(requireContext(), settingsButton)
        
        // Theme options
        popup.menu.add(0, 1, 0, "Light Theme")
        popup.menu.add(0, 2, 0, "Dark Theme")
        popup.menu.add(0, 3, 0, "---")
        
        // Page transition options
        popup.menu.add(0, 4, 0, "Swipe Mode")
        popup.menu.add(0, 5, 0, "Continuous Scroll")
        popup.menu.add(0, 6, 0, "Page Curl (3D)")  // Task 14: Add curl option
        
        popup.setOnMenuItemClickListener { item ->
            when (item.itemId) {
                1 -> {
                    applyTheme(Theme.LIGHT)
                    true
                }
                2 -> {
                    applyTheme(Theme.DARK)
                    true
                }
                4 -> {
                    setPageTransitionMode(PageTransitionMode.SWIPE)
                    true
                }
                5 -> {
                    setPageTransitionMode(PageTransitionMode.CONTINUOUS_SCROLL)
                    true
                }
                6 -> {
                    setPageTransitionMode(PageTransitionMode.PAGE_CURL)  // Task 14
                    true
                }
                else -> false
            }
        }
        
        popup.show()
    }
    
    /**
     * Apply theme to reader
     * Requirement 6.7: Theme support (light, dark)
     */
    private fun applyTheme(theme: Theme) {
        currentTheme = theme
        
        when (theme) {
            Theme.LIGHT -> {
                rootLayout.setBackgroundColor(Color.WHITE)
                topBar.setBackgroundColor(Color.parseColor("#F8F7FF")) // Light brand color
                bottomBar.setBackgroundColor(Color.parseColor("#F8F7FF"))
                titleText.setTextColor(Color.parseColor("#2D1D75")) // Dark brand color
                pageNumberText.setTextColor(Color.parseColor("#2D1D75"))
                
                // Update button colors
                updateButtonColors(Color.parseColor("#8576FF"))
                
                // Update progress bar colors
                progressSlider.progressDrawable?.setColorFilter(
                    Color.parseColor("#8576FF"),
                    android.graphics.PorterDuff.Mode.SRC_IN
                )
                progressSlider.thumb?.setColorFilter(
                    Color.parseColor("#8576FF"),
                    android.graphics.PorterDuff.Mode.SRC_IN
                )
            }
            Theme.DARK -> {
                rootLayout.setBackgroundColor(Color.parseColor("#121212"))
                topBar.setBackgroundColor(Color.parseColor("#1E1E1E"))
                bottomBar.setBackgroundColor(Color.parseColor("#1E1E1E"))
                titleText.setTextColor(Color.WHITE)
                pageNumberText.setTextColor(Color.WHITE)
                
                // Update button colors for dark theme
                updateButtonColors(Color.parseColor("#9485FF"))
                
                // Update progress bar colors
                progressSlider.progressDrawable?.setColorFilter(
                    Color.parseColor("#9485FF"),
                    android.graphics.PorterDuff.Mode.SRC_IN
                )
                progressSlider.thumb?.setColorFilter(
                    Color.parseColor("#9485FF"),
                    android.graphics.PorterDuff.Mode.SRC_IN
                )
            }
        }
        
        android.util.Log.d("PdfReaderFragment", "Applied theme: $theme")
    }
    
    /**
     * Update button colors for current theme
     */
    private fun updateButtonColors(color: Int) {
        closeButton.setColorFilter(color)
        bookmarkButton.setColorFilter(color)
        settingsButton.setColorFilter(color)
        previousButton.setColorFilter(color)
        nextButton.setColorFilter(color)
    }
    
    /**
     * Set page transition mode
     * Requirement 6.7: Page transition options (swipe, continuous scroll)
     * Task 14: Add page curl mode
     */
    private fun setPageTransitionMode(mode: PageTransitionMode) {
        pageTransitionMode = mode
        
        when (mode) {
            PageTransitionMode.SWIPE -> {
                Toast.makeText(requireContext(), "Swipe mode enabled", Toast.LENGTH_SHORT).show()
                switchToSimpleView()
            }
            PageTransitionMode.CONTINUOUS_SCROLL -> {
                Toast.makeText(requireContext(), "Continuous scroll enabled", Toast.LENGTH_SHORT).show()
                switchToSimpleView()
            }
            PageTransitionMode.PAGE_CURL -> {
                Toast.makeText(requireContext(), "Page curl (3D) enabled", Toast.LENGTH_SHORT).show()
                switchToCurlView()
            }
        }
        
        android.util.Log.d("PdfReaderFragment", "Page transition mode: $mode")
    }
    
    /**
     * Switch to simple page view (without curl)
     * Task 14: Requirement 9.4 - Non-interference with PDF features
     */
    private fun switchToSimpleView() {
        useCurlAnimation = false
        
        // Hide curl view if it exists
        pageCurlView?.let { curlView ->
            curlView.visibility = View.GONE
            curlView.setCurlEnabled(false)
        }
        
        // Show simple page view
        pdfPageView.visibility = View.VISIBLE
        
        // Reload current page
        loadCurrentPage()
        
        android.util.Log.d("PdfReaderFragment", "Switched to simple view")
    }
    
    /**
     * Switch to page curl view (with 3D curl animation)
     * Task 14: Requirement 9.1, 9.2, 9.3 - Connect to PdfReader
     */
    private fun switchToCurlView() {
        useCurlAnimation = true
        
        // Create curl view if it doesn't exist
        if (pageCurlView == null) {
            pageCurlView = PageCurlView(requireContext()).apply {
                layoutParams = FrameLayout.LayoutParams(
                    FrameLayout.LayoutParams.MATCH_PARENT,
                    FrameLayout.LayoutParams.MATCH_PARENT
                )
                
                // Task 14: Requirement 9.2 - Set up page turn callback
                onPageTurnComplete = { direction ->
                    android.util.Log.d("PdfReaderFragment", "Page turn complete: $direction")
                    updatePageInfo()
                    scheduleAutoHide()
                }
                
                onCurlStarted = {
                    android.util.Log.d("PdfReaderFragment", "Curl started")
                    cancelAutoHide()
                }
                
                onCurlEnded = {
                    android.util.Log.d("PdfReaderFragment", "Curl ended")
                    scheduleAutoHide()
                }
            }
            
            // Add to root layout (below controls)
            rootLayout.addView(pageCurlView, 0)
        }
        
        // Task 14: Requirement 9.1 - Connect to PdfReader
        pdfReader?.let { reader ->
            pageCurlView?.connectToPdfReader(reader)
        }
        
        // Show curl view
        pageCurlView?.visibility = View.VISIBLE
        pageCurlView?.setCurlEnabled(true)
        
        // Hide simple page view
        pdfPageView.visibility = View.GONE
        
        android.util.Log.d("PdfReaderFragment", "Switched to curl view")
    }
    
    /**
     * Get bookmarks for current document
     */
    fun getBookmarks(): Set<Int> = bookmarks.toSet()
    
    /**
     * Set bookmarks for current document
     */
    fun setBookmarks(bookmarkSet: Set<Int>) {
        bookmarks.clear()
        bookmarks.addAll(bookmarkSet)
        updateBookmarkButton()
    }
    
    /**
     * Convert dp to pixels
     */
    private fun dpToPx(dp: Int): Int {
        val density = resources.displayMetrics.density
        return (dp * density).toInt()
    }
    
    override fun onDestroyView() {
        super.onDestroyView()
        cancelAutoHide()
        
        // Task 14: Requirement 9.5 - Clean up PageCurlView resources
        pageCurlView?.cleanup()
    }
}
