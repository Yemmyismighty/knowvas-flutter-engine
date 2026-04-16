package com.knowvas.reader.ui

import android.animation.Animator
import android.animation.AnimatorListenerAdapter
import android.animation.ObjectAnimator
import android.graphics.Color
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.view.MenuItem
import android.view.View
import android.view.ViewGroup
import android.widget.*
import androidx.appcompat.app.AppCompatActivity
import androidx.core.content.ContextCompat
import androidx.fragment.app.commit
import org.readium.r2.navigator.epub.EpubNavigatorFragment
import org.readium.r2.shared.publication.Publication
import com.knowvas.app.R

/**
 * Activity that displays EPUB content using Readium Navigator with enhanced navigation shell
 */
class ReaderActivity : AppCompatActivity() {
    
    private lateinit var rootContainer: RelativeLayout
    private lateinit var readerContainer: FrameLayout
    private lateinit var topBar: LinearLayout
    private lateinit var bottomBar: LinearLayout
    private lateinit var titleText: TextView
    private lateinit var logoImage: ImageView
    private lateinit var backButton: ImageButton
    private lateinit var bookmarkButton: ImageButton
    private lateinit var settingsButton: ImageButton
    private lateinit var progressSlider: SeekBar
    private lateinit var pageNumberText: TextView
    
    private var navigatorFragment: EpubNavigatorFragment? = null
    private var sessionId: String? = null
    private var publication: Publication? = null
    private var readerType: String = "epub"
    
    private var controlsVisible = false
    private val hideControlsHandler = Handler(Looper.getMainLooper())
    private val hideControlsRunnable = Runnable { hideControls() }
    
    companion object {
        const val EXTRA_SESSION_ID = "session_id"
        const val EXTRA_READER_TYPE = "reader_type"
    }
    
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        
        android.util.Log.d("ReaderActivity", "onCreate called")
        
        // Use the XML layout with navigation shell
        setContentView(R.layout.activity_epub_reader)
        
        // Hide system action bar - we'll use our custom navigation
        supportActionBar?.hide()
        
        // Initialize views from XML layout
        initializeViews()
        android.util.Log.d("ReaderActivity", "Views initialized")
        
        // Set up tap-to-toggle functionality only for EPUB
        if (readerType == "epub") {
            setupTapToToggle()
            android.util.Log.d("ReaderActivity", "Tap-to-toggle setup complete for EPUB")
        } else {
            android.util.Log.d("ReaderActivity", "Skipping tap-to-toggle setup for $readerType")
        }
        
        // Get session ID and reader type
        sessionId = intent.getStringExtra(EXTRA_SESSION_ID)
        readerType = intent.getStringExtra(EXTRA_READER_TYPE) ?: "epub"
        
        if (sessionId == null) {
            android.util.Log.e("ReaderActivity", "No session ID provided")
            showError("Failed to load content")
            finish()
            return
        }
        
        // Create reader based on type
        if (savedInstanceState == null) {
            when (readerType) {
                "pdf" -> createPdfReader()
                "epub" -> createEpubReader()
                else -> {
                    android.util.Log.e("ReaderActivity", "Unknown reader type: $readerType")
                    showError("Unsupported content type")
                    finish()
                }
            }
        }
        
        // Initially show controls only for EPUB so users know they exist
        if (readerType == "epub") {
            android.util.Log.d("ReaderActivity", "Showing initial controls for EPUB")
            showControls()
        } else {
            // Hide navigation bars for PDF content
            topBar.visibility = View.GONE
            bottomBar.visibility = View.GONE
            android.util.Log.d("ReaderActivity", "Navigation bars hidden for $readerType")
        }
    }
    
    /**
     * Initialize views from XML layout and set up navigation shell
     */
    private fun initializeViews() {
        // Get views from XML layout
        readerContainer = findViewById(R.id.reader_container)
        topBar = findViewById(R.id.top_bar)
        bottomBar = findViewById(R.id.bottom_bar)
        titleText = findViewById(R.id.title_text)
        logoImage = findViewById(R.id.logo_image)
        backButton = findViewById(R.id.back_button)
        bookmarkButton = findViewById(R.id.bookmark_button)
        settingsButton = findViewById(R.id.settings_button)
        pageNumberText = findViewById(R.id.page_number_text)
        progressSlider = findViewById(R.id.progress_slider)
        
        // Set up click listeners
        backButton.setOnClickListener { finish() }
        bookmarkButton.setOnClickListener { toggleBookmark() }
        settingsButton.setOnClickListener { showSettings() }
        
        // Set up progress slider
        progressSlider.setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
            override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                if (fromUser) {
                    navigateToProgress(progress / 100f)
                }
            }
            override fun onStartTrackingTouch(seekBar: SeekBar?) {}
            override fun onStopTrackingTouch(seekBar: SeekBar?) {}
        })
        
        // Apply Knowvas branding to the existing layout
        applyBranding()
    }
    
    /**
     * Apply Knowvas branding to the XML layout
     */
    private fun applyBranding() {
        // Update colors to match Knowvas brand
        topBar.setBackgroundColor(Color.parseColor("#1A1A1A"))
        bottomBar.setBackgroundColor(Color.parseColor("#1A1A1A"))
        
        // Update text colors
        titleText.setTextColor(Color.WHITE)
        pageNumberText.setTextColor(Color.WHITE)
        
        // Update button colors
        backButton.setColorFilter(Color.WHITE)
        bookmarkButton.setColorFilter(Color.WHITE)
        settingsButton.setColorFilter(Color.WHITE)
        
        // Apply Knowvas brand color to logo
        logoImage.setColorFilter(Color.parseColor("#FF6B35"))
        
        // Update progress slider colors
        progressSlider.progressTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#FF6B35"))
        progressSlider.thumbTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#FF6B35"))
        
        android.util.Log.d("ReaderActivity", "Branding applied successfully")
    }
    
    /**
     * Create the top navigation bar with Knowvas branding
     */
    private fun createTopBar() {
        topBar = LinearLayout(this).apply {
            id = View.generateViewId()
            layoutParams = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT,
                dpToPx(64)
            ).apply {
                addRule(RelativeLayout.ALIGN_PARENT_TOP)
            }
            orientation = LinearLayout.HORIZONTAL
            gravity = android.view.Gravity.CENTER_VERTICAL
            setBackgroundColor(Color.parseColor("#1A1A1A"))
            elevation = dpToPx(8).toFloat()
            setPadding(dpToPx(16), dpToPx(8), dpToPx(16), dpToPx(8))
        }
        
        // Back button
        backButton = ImageButton(this).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(40), dpToPx(40))
            setBackgroundResource(android.R.drawable.btn_default)
            setImageResource(android.R.drawable.ic_menu_close_clear_cancel)
            setColorFilter(Color.WHITE)
            contentDescription = "Back"
            setOnClickListener { finish() }
        }
        
        // Knowvas logo (placeholder - you can replace with actual logo)
        logoImage = ImageView(this).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(32), dpToPx(32)).apply {
                marginStart = dpToPx(12)
            }
            setImageResource(android.R.drawable.ic_menu_gallery) // Placeholder
            setColorFilter(Color.parseColor("#FF6B35")) // Knowvas brand color
            contentDescription = "Knowvas"
        }
        
        // Book title
        titleText = TextView(this).apply {
            layoutParams = LinearLayout.LayoutParams(0, LinearLayout.LayoutParams.WRAP_CONTENT, 1f).apply {
                marginStart = dpToPx(12)
                marginEnd = dpToPx(12)
            }
            text = "Loading..."
            textSize = 18f
            setTextColor(Color.WHITE)
            typeface = android.graphics.Typeface.DEFAULT_BOLD
            maxLines = 1
            ellipsize = android.text.TextUtils.TruncateAt.END
        }
        
        // Bookmark button
        bookmarkButton = ImageButton(this).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(40), dpToPx(40)).apply {
                marginEnd = dpToPx(8)
            }
            setBackgroundResource(android.R.drawable.btn_default)
            setImageResource(android.R.drawable.btn_star_big_off)
            setColorFilter(Color.WHITE)
            contentDescription = "Bookmark"
            setOnClickListener { toggleBookmark() }
        }
        
        // Settings button
        settingsButton = ImageButton(this).apply {
            layoutParams = LinearLayout.LayoutParams(dpToPx(40), dpToPx(40))
            setBackgroundResource(android.R.drawable.btn_default)
            setImageResource(android.R.drawable.ic_menu_preferences)
            setColorFilter(Color.WHITE)
            contentDescription = "Settings"
            setOnClickListener { showSettings() }
        }
        
        // Add all views to top bar
        topBar.addView(backButton)
        topBar.addView(logoImage)
        topBar.addView(titleText)
        topBar.addView(bookmarkButton)
        topBar.addView(settingsButton)
    }
    
    /**
     * Create the bottom navigation bar with progress controls
     */
    private fun createBottomBar() {
        bottomBar = LinearLayout(this).apply {
            id = View.generateViewId()
            layoutParams = RelativeLayout.LayoutParams(
                RelativeLayout.LayoutParams.MATCH_PARENT,
                RelativeLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                addRule(RelativeLayout.ALIGN_PARENT_BOTTOM)
            }
            orientation = LinearLayout.VERTICAL
            setBackgroundColor(Color.parseColor("#1A1A1A"))
            elevation = dpToPx(8).toFloat()
            setPadding(dpToPx(16), dpToPx(16), dpToPx(16), dpToPx(16))
        }
        
        // Page number display
        pageNumberText = TextView(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.WRAP_CONTENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            ).apply {
                gravity = android.view.Gravity.CENTER
                bottomMargin = dpToPx(8)
            }
            text = "0 / 0"
            textSize = 14f
            setTextColor(Color.WHITE)
            gravity = android.view.Gravity.CENTER
        }
        
        // Progress slider
        progressSlider = SeekBar(this).apply {
            layoutParams = LinearLayout.LayoutParams(
                LinearLayout.LayoutParams.MATCH_PARENT,
                LinearLayout.LayoutParams.WRAP_CONTENT
            )
            max = 100
            progress = 0
            progressTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#FF6B35"))
            thumbTintList = android.content.res.ColorStateList.valueOf(Color.parseColor("#FF6B35"))
            setOnSeekBarChangeListener(object : SeekBar.OnSeekBarChangeListener {
                override fun onProgressChanged(seekBar: SeekBar?, progress: Int, fromUser: Boolean) {
                    if (fromUser) {
                        // Navigate to the selected position
                        navigateToProgress(progress / 100f)
                    }
                }
                override fun onStartTrackingTouch(seekBar: SeekBar?) {}
                override fun onStopTrackingTouch(seekBar: SeekBar?) {}
            })
        }
        
        // Add views to bottom bar
        bottomBar.addView(pageNumberText)
        bottomBar.addView(progressSlider)
    }
    
    /**
     * Set up tap-to-toggle functionality for the reader container
     */
    private fun setupTapToToggle() {
        // Use dispatchTouchEvent override instead of trying to cast root layout
        // This will be handled in the overridden dispatchTouchEvent method
        
        // Set up basic touch listener on reader container as backup
        readerContainer.setOnTouchListener { _, event ->
            when (event.action) {
                android.view.MotionEvent.ACTION_UP -> {
                    android.util.Log.d("ReaderActivity", "Reader container tapped - toggling controls")
                    toggleControls()
                    false // Don't consume, let EPUB handle it
                }
                else -> false
            }
        }
        
        // Ensure navigation bars stay on top
        topBar.bringToFront()
        bottomBar.bringToFront()
        
        android.util.Log.d("ReaderActivity", "Tap-to-toggle configured with dispatchTouchEvent override")
    }
    
    /**
     * Check if a point (x, y) is within a view's bounds
     */
    private fun isPointInView(view: View, x: Float, y: Float): Boolean {
        if (view.visibility != View.VISIBLE) return false
        
        val location = IntArray(2)
        view.getLocationOnScreen(location)
        val viewX = location[0]
        val viewY = location[1]
        
        return (x >= viewX && x <= viewX + view.width &&
                y >= viewY && y <= viewY + view.height)
    }
    
    /**
     * Toggle controls visibility with smooth animation
     */
    private fun toggleControls() {
        android.util.Log.d("ReaderActivity", "toggleControls called, current state: $controlsVisible")
        if (controlsVisible) {
            hideControls()
        } else {
            showControls()
        }
    }
    
    /**
     * Show navigation controls with animation
     */
    private fun showControls() {
        android.util.Log.d("ReaderActivity", "showControls called, current state: $controlsVisible")
        if (controlsVisible) return
        
        controlsVisible = true
        
        // Ensure navigation bars are on top
        topBar.bringToFront()
        bottomBar.bringToFront()
        
        android.util.Log.d("ReaderActivity", "Showing top bar (height: ${topBar.height})")
        // Animate top bar sliding down
        topBar.visibility = View.VISIBLE
        topBar.translationY = -topBar.height.toFloat()
        ObjectAnimator.ofFloat(topBar, "translationY", 0f).apply {
            duration = 300
            start()
        }
        
        android.util.Log.d("ReaderActivity", "Showing bottom bar (height: ${bottomBar.height})")
        // Animate bottom bar sliding up
        bottomBar.visibility = View.VISIBLE
        bottomBar.translationY = bottomBar.height.toFloat()
        ObjectAnimator.ofFloat(bottomBar, "translationY", 0f).apply {
            duration = 300
            start()
        }
        
        // Auto-hide after 6 seconds (increased from 4 seconds)
        scheduleAutoHide()
        android.util.Log.d("ReaderActivity", "Controls shown and auto-hide scheduled (6 seconds)")
    }
    
    /**
     * Hide navigation controls with animation
     */
    private fun hideControls(animate: Boolean = true) {
        if (!controlsVisible && animate) return
        
        controlsVisible = false
        cancelAutoHide()
        
        if (!animate) {
            topBar.visibility = View.GONE
            bottomBar.visibility = View.GONE
            return
        }
        
        // Animate top bar sliding up
        ObjectAnimator.ofFloat(topBar, "translationY", -topBar.height.toFloat()).apply {
            duration = 300
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    topBar.visibility = View.GONE
                }
            })
            start()
        }
        
        // Animate bottom bar sliding down
        ObjectAnimator.ofFloat(bottomBar, "translationY", bottomBar.height.toFloat()).apply {
            duration = 300
            addListener(object : AnimatorListenerAdapter() {
                override fun onAnimationEnd(animation: Animator) {
                    bottomBar.visibility = View.GONE
                }
            })
            start()
        }
    }
    
    /**
     * Schedule auto-hide of controls after 4 seconds
     */
    private fun scheduleAutoHide() {
        cancelAutoHide()
        hideControlsHandler.postDelayed(hideControlsRunnable, 6000) // Increased to 6 seconds
    }
    
    /**
     * Cancel scheduled auto-hide
     */
    private fun cancelAutoHide() {
        hideControlsHandler.removeCallbacks(hideControlsRunnable)
    }
    
    /**
     * Convert dp to pixels
     */
    private fun dpToPx(dp: Int): Int {
        return (dp * resources.displayMetrics.density).toInt()
    }
    
    /**
     * Toggle bookmark for current page
     */
    private fun toggleBookmark() {
        // Get current EPUB reader
        val epubReader = com.knowvas.reader.ReaderManager.getReader(sessionId!!) as? com.knowvas.reader.epub.EpubReader
        if (epubReader != null) {
            val isBookmarked = epubReader.toggleBookmark()
            
            // Update bookmark button appearance
            if (isBookmarked) {
                bookmarkButton.setImageResource(android.R.drawable.btn_star_big_on)
                showToast("Bookmark added")
            } else {
                bookmarkButton.setImageResource(android.R.drawable.btn_star_big_off)
                showToast("Bookmark removed")
            }
        }
        
        // Reset auto-hide timer
        if (controlsVisible) {
            scheduleAutoHide()
        }
    }
    
    /**
     * Show settings dialog with Readium options
     */
    private fun showSettings() {
        // Get current EPUB reader
        val epubReader = com.knowvas.reader.ReaderManager.getReader(sessionId!!) as? com.knowvas.reader.epub.EpubReader
        if (epubReader == null) return
        
        // Create settings dialog
        val settingsDialog = EpubSettingsDialog(this, epubReader) { settings ->
            // Apply settings when changed
            epubReader.setPreferences(settings)
            showToast("Settings applied")
        }
        
        settingsDialog.show()
        
        // Reset auto-hide timer
        if (controlsVisible) {
            scheduleAutoHide()
        }
    }
    
    /**
     * Navigate to specific progress position (0.0 to 1.0)
     */
    private fun navigateToProgress(progress: Float) {
        val epubReader = com.knowvas.reader.ReaderManager.getReader(sessionId!!) as? com.knowvas.reader.epub.EpubReader
        epubReader?.setProgress(progress.toDouble())
        
        // Update page number display
        updatePageDisplay()
        
        // Reset auto-hide timer
        if (controlsVisible) {
            scheduleAutoHide()
        }
    }
    
    /**
     * Update page number and progress display
     */
    private fun updatePageDisplay() {
        val epubReader = com.knowvas.reader.ReaderManager.getReader(sessionId!!) as? com.knowvas.reader.epub.EpubReader
        if (epubReader != null) {
            val currentPage = epubReader.getCurrentPage() + 1 // 1-based for display
            val totalPages = epubReader.getTotalPages()
            val progress = epubReader.getProgress()
            
            pageNumberText.text = "$currentPage / $totalPages"
            progressSlider.progress = (progress * 100).toInt()
            
            // Update bookmark button state
            val hasBookmark = epubReader.hasBookmark()
            bookmarkButton.setImageResource(
                if (hasBookmark) android.R.drawable.btn_star_big_on
                else android.R.drawable.btn_star_big_off
            )
        }
    }
    
    /**
     * Show toast message
     */
    private fun showToast(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()
    }
    
    private fun createPdfReader() {
        try {
            android.util.Log.i("ReaderActivity", "Creating PDF reader for session: $sessionId")
            
            // Get PDF reader from manager
            val pdfReader = com.knowvas.reader.ReaderManager.getReader(sessionId!!) as? com.knowvas.reader.pdf.PdfReader
            if (pdfReader == null) {
                android.util.Log.e("ReaderActivity", "No PDF reader found for session: $sessionId")
                showError("Failed to load PDF. Please try again.")
                finish()
                return
            }
            
            // Create PDF reader fragment
            val pdfFragment = com.knowvas.reader.pdf.PdfReaderFragment.newInstance(pdfReader)
            
            // Add fragment to container
            supportFragmentManager.commit {
                replace(readerContainer.id, pdfFragment)
            }
            
            android.util.Log.i("ReaderActivity", "PDF reader created successfully")
            
        } catch (e: Exception) {
            android.util.Log.e("ReaderActivity", "Failed to create PDF reader", e)
            showError("Failed to open PDF: ${e.message}")
            finish()
        }
    }
    
    private fun createEpubReader() {
        // Get publication
        publication = com.knowvas.reader.ReaderManager.getPublication(sessionId!!)
        if (publication == null) {
            android.util.Log.e("ReaderActivity", "No publication found for session: $sessionId")
            showError("Failed to load book. Please try again.")
            finish()
            return
        }
        
        // Update title with book information
        updateBookTitle()
        
        // Create navigator if this is first creation
        createNavigator(publication!!)
        
        // Start updating page display periodically
        startPageDisplayUpdates()
    }
    
    /**
     * Update the book title and author in the navigation bar
     */
    private fun updateBookTitle() {
        publication?.let { pub ->
            val title = pub.metadata.title ?: "Unknown Title"
            val author = pub.metadata.authors.firstOrNull()?.name ?: ""
            
            titleText.text = if (author.isNotEmpty()) {
                "$title - $author"
            } else {
                title
            }
        }
    }
    
    /**
     * Set up tap detection on the navigator fragment view
     */
    private fun setupNavigatorTapDetection() {
        navigatorFragment?.view?.let { fragmentView ->
            fragmentView.setOnClickListener {
                android.util.Log.d("ReaderActivity", "Navigator fragment tapped")
                toggleControls()
            }
            fragmentView.isClickable = true
            fragmentView.isFocusable = true
            android.util.Log.d("ReaderActivity", "Tap detection set up on navigator fragment")
        }
    }

    /**
     * Start periodic updates of page display
     */
    private fun startPageDisplayUpdates() {
        val updateHandler = Handler(Looper.getMainLooper())
        val updateRunnable = object : Runnable {
            override fun run() {
                if (!isDestroyed && !isFinishing) {
                    updatePageDisplay()
                    updateHandler.postDelayed(this, 1000) // Update every second
                }
            }
        }
        updateHandler.post(updateRunnable)
    }
    
    private fun createNavigator(publication: Publication) {
        try {
            android.util.Log.i("ReaderActivity", "Creating navigator for: ${publication.metadata.title}")
            android.util.Log.d("ReaderActivity", "Reader container ID: ${readerContainer.id}")
            
            // Create EPUB navigator fragment
            navigatorFragment = EpubNavigatorFragment.createFactory(
                publication = publication,
                initialLocator = null
            ).let { factory ->
                supportFragmentManager.fragmentFactory = factory
                factory.instantiate(classLoader, EpubNavigatorFragment::class.java.name) as EpubNavigatorFragment
            }
            
            android.util.Log.d("ReaderActivity", "Navigator fragment created: $navigatorFragment")
            
            // Add fragment to container
            supportFragmentManager.commit {
                replace(readerContainer.id, navigatorFragment!!)
            }
            
            android.util.Log.i("ReaderActivity", "Navigator fragment added to container")
            
            // Force show controls after fragment is added and ensure proper layering
            readerContainer.post {
                android.util.Log.d("ReaderActivity", "Forcing controls to show after fragment added")
                
                // Ensure navigation bars are on top of the EPUB content
                topBar.bringToFront()
                bottomBar.bringToFront()
                
                // Show controls
                showControls()
                
                // Set up additional tap detection on the navigator fragment
                setupNavigatorTapDetection()
            }
            
        } catch (e: Exception) {
            android.util.Log.e("ReaderActivity", "Failed to create navigator", e)
            showError("Failed to open reader: ${e.message}")
            finish()
        }
    }
    
    private fun showError(message: String) {
        Toast.makeText(this, message, Toast.LENGTH_LONG).show()
    }
    
    override fun dispatchTouchEvent(event: android.view.MotionEvent): Boolean {
        // Only intercept touch events for EPUB content
        if (readerType == "epub" && event.action == android.view.MotionEvent.ACTION_UP) {
            // Check if the tap is on the navigation bars
            val isOnTopBar = topBar.visibility == View.VISIBLE && isPointInView(topBar, event.rawX, event.rawY)
            val isOnBottomBar = bottomBar.visibility == View.VISIBLE && isPointInView(bottomBar, event.rawX, event.rawY)
            
            if (!isOnTopBar && !isOnBottomBar) {
                // Tap is on content area, toggle controls
                android.util.Log.d("ReaderActivity", "EPUB content area tapped - toggling controls")
                toggleControls()
            }
        }
        
        // Always pass the event to the normal touch handling
        return super.dispatchTouchEvent(event)
    }

    override fun onBackPressed() {
        // Only use back button to toggle navigation for EPUB content
        if (readerType == "epub") {
            if (controlsVisible) {
                hideControls()
            } else {
                showControls()
            }
        } else {
            // For PDF content, use normal back button behavior
            super.onBackPressed()
        }
    }

    override fun onOptionsItemSelected(item: MenuItem): Boolean {
        return when (item.itemId) {
            android.R.id.home -> {
                finish()
                true
            }
            else -> super.onOptionsItemSelected(item)
        }
    }
    
    override fun onDestroy() {
        super.onDestroy()
        
        // Cancel any pending auto-hide
        cancelAutoHide()
        
        // Clean up publication from manager
        sessionId?.let {
            com.knowvas.reader.ReaderManager.removePublication(it)
        }
        
        navigatorFragment = null
        publication = null
    }
}
