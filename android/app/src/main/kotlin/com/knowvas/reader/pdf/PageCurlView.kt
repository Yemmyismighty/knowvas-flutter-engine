package com.knowvas.reader.pdf

import android.content.Context
import android.graphics.Bitmap
import android.graphics.PointF
import android.opengl.GLSurfaceView
import android.util.AttributeSet
import android.util.Log
import android.view.MotionEvent
import javax.microedition.khronos.egl.EGLConfig
import javax.microedition.khronos.opengles.GL10
import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.sqrt
import kotlin.math.PI

/**
 * OpenGL-based page curl view for realistic page-flip animations
 * 
 * Features:
 * - Realistic 3D page curl effect
 * - Touch-based curl control
 * - Smooth 60 FPS animations
 * - Hardware accelerated rendering
 * - Supports forward and backward page turns
 * 
 * Based on the paper "Turning Pages of 3D Electronic Books" by Hong et al.
 * and inspired by android-page-curl library
 */
class PageCurlView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null
) : GLSurfaceView(context, attrs) {

    // Renderer for OpenGL
    private val curlRenderer: CurlRenderer
    
    // Touch handler for curl interaction
    private var touchHandler: TouchHandler? = null
    
    // Animation controller for page turn and snap-back animations
    // Requirements: 6.2, 6.3, 7.2
    private val animationController = AnimationController()
    
    // Current and next page bitmaps
    private var currentPageBitmap: Bitmap? = null
    private var nextPageBitmap: Bitmap? = null
    
    // Curl state
    private var isCurling = false
    
    // Current curl parameters
    private var currentCurlParams: CurlParameters = CurlParameters.FLAT
    
    // PdfReader integration (Task 14: Requirement 9.1, 9.2, 9.3)
    private var pdfReader: PdfReader? = null
    
    // Callbacks
    var onPageTurnComplete: ((direction: TouchHandler.Direction) -> Unit)? = null
    var onCurlStarted: (() -> Unit)? = null
    var onCurlEnded: (() -> Unit)? = null
    
    init {
        // Configure EGL settings for OpenGL ES 2.0
        // Requirements: 1.1, 1.2
        
        // Set OpenGL ES 2.0 context (required for shader support)
        setEGLContextClientVersion(2)
        
        // Configure EGL for optimal rendering
        // 8-bit color channels, 16-bit depth buffer, no stencil
        setEGLConfigChooser(8, 8, 8, 8, 16, 0)
        
        // Preserve EGL context on pause (better for performance)
        preserveEGLContextOnPause = true
        
        // Create renderer
        curlRenderer = CurlRenderer(context)
        setRenderer(curlRenderer)
        
        // Render only when dirty (for better performance and battery life)
        renderMode = RENDERMODE_WHEN_DIRTY
        
        android.util.Log.d("PageCurlView", "Initialized with OpenGL ES 2.0 context")
    }
    
    /**
     * Connect to PdfReader for bitmap loading
     * 
     * Task 14: Requirement 9.1 - Receive page bitmaps from PDF Reader
     * 
     * @param reader The PdfReader instance to connect to
     */
    fun connectToPdfReader(reader: PdfReader) {
        pdfReader = reader
        
        // Load initial pages
        loadPagesFromReader()
        
        android.util.Log.d("PageCurlView", "Connected to PdfReader")
    }
    
    /**
     * Disconnect from PdfReader
     * 
     * Task 14: Requirement 9.5 - Proper resource cleanup
     */
    fun disconnectFromPdfReader() {
        pdfReader = null
        android.util.Log.d("PageCurlView", "Disconnected from PdfReader")
    }
    
    /**
     * Load current and adjacent pages from PdfReader
     * 
     * Task 14: Requirement 9.1, 9.3 - Load bitmaps and update textures
     */
    private fun loadPagesFromReader() {
        val reader = pdfReader ?: return
        
        // Load current page
        val currentBitmap = reader.renderCurrentPage()
        if (currentBitmap != null) {
            setCurrentPage(currentBitmap)
        }
        
        // Load next page (for forward curl)
        val currentPageIndex = reader.getCurrentPage()
        if (currentPageIndex < reader.getTotalPages() - 1) {
            val nextBitmap = reader.renderPage(currentPageIndex + 1)
            if (nextBitmap != null) {
                setNextPage(nextBitmap)
            }
        }
        
        // Load previous page (for backward curl)
        if (currentPageIndex > 0) {
            val previousBitmap = reader.renderPage(currentPageIndex - 1)
            if (previousBitmap != null) {
                setPreviousPage(previousBitmap)
            }
        }
        
        android.util.Log.d("PageCurlView", "Loaded pages from PdfReader: current=$currentPageIndex")
    }
    
    /**
     * Set the current page bitmap
     */
    fun setCurrentPage(bitmap: Bitmap) {
        currentPageBitmap = bitmap
        curlRenderer.setCurrentPageTexture(bitmap)
        requestRender()
    }
    
    /**
     * Set the next page bitmap (for forward curl)
     */
    fun setNextPage(bitmap: Bitmap) {
        nextPageBitmap = bitmap
        curlRenderer.setNextPageTexture(bitmap)
    }
    
    /**
     * Set the previous page bitmap (for backward curl)
     */
    fun setPreviousPage(bitmap: Bitmap) {
        curlRenderer.setPreviousPageTexture(bitmap)
    }
    
    /**
     * Trigger automatic page turn animation
     * 
     * Can be called programmatically to turn pages without touch interaction.
     * 
     * Requirements: 6.1, 6.4
     * 
     * @param direction Direction of page turn (FORWARD or BACKWARD)
     * @param animate Whether to animate the page turn (default true)
     */
    fun turnPage(direction: TouchHandler.Direction, animate: Boolean = true) {
        // Don't start new animation if one is already running
        if (animationController.isAnimating()) {
            android.util.Log.w("PageCurlView", "turnPage: Animation already in progress")
            return
        }
        
        if (animate) {
            // Start animated page turn
            startPageTurnAnimation(direction)
        } else {
            // Instant page turn without animation
            resetCurl()
            onPageTurnComplete?.invoke(direction)
        }
    }
    
    /**
     * Reset curl to flat state
     * 
     * Cancels any ongoing animation and resets curl parameters.
     * 
     * Requirements: 6.5, 7.3, 7.5
     */
    fun resetCurl() {
        isCurling = false
        currentCurlParams = CurlParameters.FLAT
        
        // Cancel any ongoing animation
        animationController.cancelAnimation()
        
        // Reset curl on GL thread
        queueEvent {
            curlRenderer.resetCurl()
            requestRender()
        }
    }
    
    /**
     * Enable or disable visual effects (shadows and lighting)
     * 
     * Requirements: 8.5 - Add configuration to enable/disable effects
     * 
     * @param enabled True to enable effects, false to disable
     */
    fun setVisualEffectsEnabled(enabled: Boolean) {
        queueEvent {
            curlRenderer.setVisualEffectsEnabled(enabled)
        }
    }
    
    /**
     * Check if visual effects are enabled
     */
    fun areVisualEffectsEnabled(): Boolean {
        return curlRenderer.areVisualEffectsEnabled()
    }
    
    /**
     * Check if curl is currently active
     * 
     * Task 14: Requirement 9.4 - Non-interference with PDF features
     * 
     * This allows other components (like zoom/pan handlers) to check
     * if curl is active and avoid interfering with it.
     * 
     * @return true if curl is active, false otherwise
     */
    fun isCurlActive(): Boolean {
        return isCurling || animationController.isAnimating()
    }
    
    /**
     * Check if curl is enabled
     * 
     * Task 14: Requirement 9.4 - Non-interference with PDF features
     * 
     * When curl is disabled, the view should not intercept touch events,
     * allowing zoom/pan to work normally.
     * 
     * @return true if curl is enabled, false otherwise
     */
    private var curlEnabled = true
    
    fun setCurlEnabled(enabled: Boolean) {
        curlEnabled = enabled
        android.util.Log.d("PageCurlView", "Curl ${if (enabled) "enabled" else "disabled"}")
    }
    
    fun isCurlEnabled(): Boolean {
        return curlEnabled
    }
    
    /**
     * Get performance metrics
     * 
     * Task 15: Requirement 12.3 - Performance metrics logging
     * 
     * Returns a map containing current performance metrics including:
     * - FPS (frames per second)
     * - Average frame time (milliseconds)
     * - GPU memory usage (MB)
     * - Mesh resolution
     * - Vertex buffer update count
     * 
     * @return Map of performance metrics
     */
    fun getPerformanceMetrics(): Map<String, Any> {
        return curlRenderer.getPerformanceMetrics()
    }
    
    /**
     * Clean up OpenGL resources
     * Should be called when the view is destroyed
     * 
     * Task 14: Requirement 9.5 - Proper resource cleanup
     */
    fun cleanup() {
        // Disconnect from PdfReader
        disconnectFromPdfReader()
        
        // Clean up OpenGL resources
        queueEvent {
            curlRenderer.cleanup()
        }
        
        // Recycle bitmaps
        currentPageBitmap?.let { bitmap ->
            if (!bitmap.isRecycled) {
                bitmap.recycle()
            }
        }
        currentPageBitmap = null
        
        nextPageBitmap?.let { bitmap ->
            if (!bitmap.isRecycled) {
                bitmap.recycle()
            }
        }
        nextPageBitmap = null
        
        android.util.Log.d("PageCurlView", "Cleanup complete")
    }
    
    override fun onSizeChanged(w: Int, h: Int, oldw: Int, oldh: Int) {
        super.onSizeChanged(w, h, oldw, oldh)
        
        // Create or update touch handler with new dimensions
        touchHandler = TouchHandler(
            pageWidth = w.toFloat(),
            pageHeight = h.toFloat(),
            edgeThreshold = 0.2f
        )
        
        android.util.Log.d("PageCurlView", "Size changed: ${w}x${h}, TouchHandler initialized")
    }
    
    override fun onTouchEvent(event: MotionEvent): Boolean {
        // Task 14: Requirement 9.4 - Non-interference with PDF features
        // If curl is disabled, don't handle touch events (allow zoom/pan to work)
        if (!curlEnabled) {
            return super.onTouchEvent(event)
        }
        
        // Requirements: 7.4 - Ignore touch events during animation
        if (animationController.isAnimating()) {
            return true
        }
        
        // Ensure touch handler is initialized
        val handler = touchHandler ?: return super.onTouchEvent(event)
        
        when (event.action) {
            MotionEvent.ACTION_DOWN -> {
                val result = handler.handleTouchDown(event.x, event.y)
                handleTouchResult(result)
                // Task 14: Requirement 9.4 - Only consume touch if curl started
                // This allows zoom/pan to work when touch is not near edges
                return result !is TouchHandler.TouchResult.Ignored
            }
            MotionEvent.ACTION_MOVE -> {
                val result = handler.handleTouchMove(event.x, event.y)
                handleTouchResult(result)
                return handler.isTouchActive()
            }
            MotionEvent.ACTION_UP, MotionEvent.ACTION_CANCEL -> {
                val result = handler.handleTouchUp(event.x, event.y)
                handleTouchResult(result)
                return handler.isTouchActive()
            }
        }
        return super.onTouchEvent(event)
    }
    
    /**
     * Handle the result from TouchHandler
     * 
     * Processes the touch result and updates the view accordingly
     * Requirements: 5.3, 5.4 - Real-time curl updates at 30+ FPS
     */
    private fun handleTouchResult(result: TouchHandler.TouchResult) {
        when (result) {
            is TouchHandler.TouchResult.Ignored -> {
                // Do nothing
            }
            is TouchHandler.TouchResult.CurlStarted -> {
                isCurling = true
                onCurlStarted?.invoke()
                android.util.Log.d("PageCurlView", "Curl started: ${result.direction}")
            }
            is TouchHandler.TouchResult.CurlUpdated -> {
                // Update curl parameters and render
                // Requirements: 5.3 - Update mesh vertices in real-time during drag
                currentCurlParams = result.params
                
                // Queue the curl update on the GL thread for thread safety
                // This ensures mesh updates happen on the rendering thread
                queueEvent {
                    curlRenderer.updateCurl(
                        result.params.position,
                        result.params.direction,
                        result.params.radius
                    )
                }
                
                // Request render to display the updated mesh
                // Requirements: 5.4 - Optimize for smooth 30+ FPS during interaction
                requestRender()
            }
            is TouchHandler.TouchResult.PageTurnTriggered -> {
                isCurling = false
                onCurlEnded?.invoke()
                startPageTurnAnimation(result.direction)
            }
            is TouchHandler.TouchResult.SnapBackTriggered -> {
                isCurling = false
                onCurlEnded?.invoke()
                startSnapBackAnimation()
            }
        }
    }
    
    /**
     * Start page turn completion animation
     * 
     * Animates the curl from its current state to full completion,
     * then notifies the callback and resets the curl state.
     * 
     * Requirements: 6.1, 6.2, 6.3, 6.4, 6.5
     * Task 14: Requirement 9.2, 9.3 - Notify PdfReader and update textures
     * 
     * @param direction Direction of page turn (FORWARD or BACKWARD)
     */
    private fun startPageTurnAnimation(direction: TouchHandler.Direction) {
        android.util.Log.d("PageCurlView", "Starting page turn animation: direction=$direction")
        
        // Reset touch handler
        touchHandler?.reset()
        
        // Store the starting curl parameters
        val startParams = currentCurlParams
        
        // Requirements: 6.2, 6.3 - Use AnimationController with ease-out interpolation
        animationController.startPageTurnAnimation(
            startParams = startParams,
            direction = direction,
            duration = 400L, // 400ms is within the 300-500ms requirement
            onUpdate = { interpolatedParams ->
                // Update curl on GL thread
                // Requirements: 6.2 - Animate curl to full completion
                queueEvent {
                    curlRenderer.updateCurl(
                        interpolatedParams.position,
                        interpolatedParams.direction,
                        interpolatedParams.radius
                    )
                    requestRender()
                }
            },
            onComplete = {
                // Requirements: 6.4 - Notify callback when page turn completes
                // Requirements: 6.5 - Reset curl state after completion
                // Task 14: Requirement 9.2 - Notify PDF Reader to change page
                android.util.Log.d("PageCurlView", "Page turn animation complete")
                
                // Reset curl to flat state
                queueEvent {
                    curlRenderer.resetCurl()
                    requestRender()
                }
                
                // Reset local state
                currentCurlParams = CurlParameters.FLAT
                isCurling = false
                
                // Task 14: Requirement 9.2 - Update PdfReader page index
                pdfReader?.let { reader ->
                    val success = when (direction) {
                        TouchHandler.Direction.FORWARD -> reader.nextPage()
                        TouchHandler.Direction.BACKWARD -> reader.previousPage()
                    }
                    
                    if (success) {
                        // Task 14: Requirement 9.3 - Update textures for new pages
                        loadPagesFromReader()
                    }
                }
                
                // Notify callback
                onPageTurnComplete?.invoke(direction)
            }
        )
    }
    
    /**
     * Start snap-back animation
     * 
     * Animates the curl back to flat position with elastic easing.
     * 
     * Requirements: 7.1, 7.2, 7.3, 7.5
     * 
     * @param startParams Starting curl parameters
     */
    private fun startSnapBackAnimation() {
        android.util.Log.d("PageCurlView", "Starting snap-back animation")
        
        // Reset touch handler
        touchHandler?.reset()
        
        // Store the starting curl parameters
        val startParams = currentCurlParams
        
        // Requirements: 7.2 - Use AnimationController with elastic easing
        animationController.startSnapBackAnimation(
            startParams = startParams,
            duration = 250L, // 250ms is within the 200-300ms requirement
            onUpdate = { interpolatedParams ->
                // Update curl on GL thread
                queueEvent {
                    curlRenderer.updateCurl(
                        interpolatedParams.position,
                        interpolatedParams.direction,
                        interpolatedParams.radius
                    )
                    requestRender()
                }
            },
            onComplete = {
                // Requirements: 7.3, 7.5 - Reset curl state after snap-back
                android.util.Log.d("PageCurlView", "Snap-back animation complete")
                
                // Reset curl to flat state
                queueEvent {
                    curlRenderer.resetCurl()
                    requestRender()
                }
                
                // Reset local state
                currentCurlParams = CurlParameters.FLAT
                isCurling = false
            }
        )
    }
    
    /**
     * OpenGL renderer for page curl effect
     */
    private class CurlRenderer(private val context: Context) : Renderer {
        
        companion object {
            private const val TAG = "CurlRenderer"
        }
        
        // Performance monitoring (Task 15: Requirements 10.1-10.5, 12.3)
        private val performanceMonitor = PerformanceMonitor()
        
        // Texture manager for loading and managing textures
        private val textureManager = TextureManager()
        
        // Mesh generator for creating deformable grids
        // Start with adaptive resolution based on device tier
        private var meshGenerator: MeshGenerator
        
        // Visual effects for shadows and lighting
        // Requirements: 8.1, 8.2, 8.3, 8.4, 8.5
        private val visualEffects = VisualEffects()
        
        // Page meshes
        private var currentPageMesh: PageMesh? = null
        private var nextPageMesh: PageMesh? = null
        
        // Textures
        private var currentPageTexture: Int = 0
        private var nextPageTexture: Int = 0
        private var previousPageTexture: Int = 0
        
        // Curl parameters
        private var curlPosition = PointF()
        private var curlDirection = PointF()
        private var curlRadius = 0f
        
        // Previous curl parameters for change detection (Requirement: 10.4)
        private var previousCurlRadius = 0f
        private var previousCurlPosition = PointF()
        
        // Adaptive mesh resolution tracking
        private var needsMeshRegeneration = false
        
        // Surface dimensions
        private var surfaceWidth: Int = 0
        private var surfaceHeight: Int = 0
        
        // OpenGL initialization state
        private var isInitialized = false
        
        init {
            // Detect device tier and set appropriate mesh resolution
            // Requirements: 10.1, 10.2, 10.5
            val deviceTier = performanceMonitor.detectDeviceTier()
            performanceMonitor.setDeviceTier(deviceTier)
            
            // Start with appropriate mesh resolution based on device tier
            val initialResolution = when (deviceTier) {
                PerformanceMonitor.DeviceTier.HIGH_END -> PerformanceMonitor.MeshResolution.HIGH
                PerformanceMonitor.DeviceTier.MID_RANGE -> PerformanceMonitor.MeshResolution.MEDIUM
                PerformanceMonitor.DeviceTier.LOW_END -> PerformanceMonitor.MeshResolution.LOW
            }
            
            meshGenerator = MeshGenerator(
                gridWidth = initialResolution.width,
                gridHeight = initialResolution.height
            )
            
            Log.d(TAG, "CurlRenderer initialized with device tier: $deviceTier, mesh resolution: $initialResolution")
        }
        
        override fun onSurfaceCreated(gl: GL10?, config: EGLConfig?) {
            android.util.Log.d(TAG, "onSurfaceCreated: Initializing OpenGL ES 2.0 context")
            
            try {
                // Set clear color (white background)
                gl?.glClearColor(1.0f, 1.0f, 1.0f, 1.0f)
                checkGLError(gl, "glClearColor")
                
                // Enable depth testing for proper 3D rendering
                gl?.glEnable(GL10.GL_DEPTH_TEST)
                checkGLError(gl, "glEnable(GL_DEPTH_TEST)")
                
                gl?.glDepthFunc(GL10.GL_LEQUAL)
                checkGLError(gl, "glDepthFunc")
                
                // Enable textures for page rendering
                gl?.glEnable(GL10.GL_TEXTURE_2D)
                checkGLError(gl, "glEnable(GL_TEXTURE_2D)")
                
                // Enable blending for transparency and smooth edges
                gl?.glEnable(GL10.GL_BLEND)
                checkGLError(gl, "glEnable(GL_BLEND)")
                
                gl?.glBlendFunc(GL10.GL_SRC_ALPHA, GL10.GL_ONE_MINUS_SRC_ALPHA)
                checkGLError(gl, "glBlendFunc")
                
                // Set texture environment mode
                gl?.glTexEnvf(GL10.GL_TEXTURE_ENV, GL10.GL_TEXTURE_ENV_MODE, GL10.GL_MODULATE.toFloat())
                checkGLError(gl, "glTexEnvf")
                
                // Enable smooth shading
                gl?.glShadeModel(GL10.GL_SMOOTH)
                checkGLError(gl, "glShadeModel")
                
                // Set hints for best quality
                gl?.glHint(GL10.GL_PERSPECTIVE_CORRECTION_HINT, GL10.GL_NICEST)
                checkGLError(gl, "glHint(PERSPECTIVE_CORRECTION)")
                
                gl?.glHint(GL10.GL_LINE_SMOOTH_HINT, GL10.GL_NICEST)
                checkGLError(gl, "glHint(LINE_SMOOTH)")
                
                // Create page meshes using MeshGenerator
                // Requirements: 3.1, 3.2, 3.4
                currentPageMesh = meshGenerator.generateMesh()
                nextPageMesh = meshGenerator.generateMesh()
                
                android.util.Log.d(TAG, "Generated meshes: ${currentPageMesh?.vertexCount} vertices, ${currentPageMesh?.triangleCount} triangles")
                
                isInitialized = true
                android.util.Log.d(TAG, "onSurfaceCreated: OpenGL initialization complete")
                
            } catch (e: Exception) {
                android.util.Log.e(TAG, "onSurfaceCreated: Error initializing OpenGL", e)
                isInitialized = false
            }
        }
        
        override fun onSurfaceChanged(gl: GL10?, width: Int, height: Int) {
            android.util.Log.d(TAG, "onSurfaceChanged: width=$width, height=$height")
            
            if (!isInitialized) {
                android.util.Log.e(TAG, "onSurfaceChanged: OpenGL not initialized, skipping")
                return
            }
            
            try {
                // Store surface dimensions
                surfaceWidth = width
                surfaceHeight = height
                
                // Set viewport to match surface dimensions
                gl?.glViewport(0, 0, width, height)
                checkGLError(gl, "glViewport")
                
                // Set up projection matrix
                gl?.glMatrixMode(GL10.GL_PROJECTION)
                checkGLError(gl, "glMatrixMode(PROJECTION)")
                
                gl?.glLoadIdentity()
                checkGLError(gl, "glLoadIdentity")
                
                // Calculate aspect ratio to maintain correct proportions
                val ratio = width.toFloat() / height.toFloat()
                
                // Set up orthographic projection for 2D rendering
                // This maintains aspect ratio and prevents distortion
                gl?.glOrthof(-ratio, ratio, -1f, 1f, -10f, 10f)
                checkGLError(gl, "glOrthof")
                
                // Switch to model view matrix for rendering
                gl?.glMatrixMode(GL10.GL_MODELVIEW)
                checkGLError(gl, "glMatrixMode(MODELVIEW)")
                
                gl?.glLoadIdentity()
                checkGLError(gl, "glLoadIdentity")
                
                android.util.Log.d(TAG, "onSurfaceChanged: Projection matrix configured with aspect ratio=$ratio")
                
            } catch (e: Exception) {
                android.util.Log.e(TAG, "onSurfaceChanged: Error configuring surface", e)
            }
        }
        
        override fun onDrawFrame(gl: GL10?) {
            if (!isInitialized) {
                return
            }
            
            // Task 15: Requirement 10.1, 10.2, 12.3 - Track frame timing for performance monitoring
            performanceMonitor.startFrame()
            
            try {
                // Clear color and depth buffers
                gl?.glClear(GL10.GL_COLOR_BUFFER_BIT or GL10.GL_DEPTH_BUFFER_BIT)
                checkGLError(gl, "glClear")
                
                // Reset model view matrix
                gl?.glLoadIdentity()
                checkGLError(gl, "glLoadIdentity")
                
                // Render shadow beneath curl if curl is active
                // Requirements: 8.1, 8.2 - Render shadow beneath curl with intensity based on curl angle
                if (curlRadius > 0) {
                    val curlParams = CurlParameters(
                        position = PointF(curlPosition.x, curlPosition.y),
                        direction = PointF(curlDirection.x, curlDirection.y),
                        radius = curlRadius,
                        angle = (curlRadius / 500f * kotlin.math.PI).toFloat().coerceIn(0f, kotlin.math.PI.toFloat())
                    )
                    
                    // Render shadow first (behind the page)
                    visualEffects.renderShadow(
                        gl,
                        curlParams,
                        surfaceWidth.toFloat(),
                        surfaceHeight.toFloat()
                    )
                }
                
                // Draw current page (already curled by updateCurl if needed)
                // Requirements: 5.3, 5.4 - Render mesh with real-time curl updates
                currentPageMesh?.let { mesh ->
                    MeshRenderer.draw(gl, mesh, currentPageTexture)
                }
                
                // Draw next page (visible through curl)
                if (curlRadius > 0) {
                    nextPageMesh?.let { mesh ->
                        MeshRenderer.draw(gl, mesh, nextPageTexture)
                    }
                }
                
                // Check for any OpenGL errors after rendering
                checkGLError(gl, "onDrawFrame")
                
            } catch (e: Exception) {
                android.util.Log.e(TAG, "onDrawFrame: Error rendering frame", e)
            } finally {
                // Task 15: Requirement 10.1, 10.2, 10.5 - End frame timing and check for adaptive mesh resolution
                performanceMonitor.endFrame()
                
                // Task 15: Requirement 10.5 - Check if mesh resolution needs to be adapted
                checkAndAdaptMeshResolution()
            }
        }
        
        /**
         * Check performance and adapt mesh resolution if needed
         * 
         * Task 15: Requirement 10.5 - Implement adaptive mesh resolution
         * 
         * This method checks the current FPS and adapts the mesh resolution
         * to maintain target frame rates. If FPS drops below target, mesh
         * resolution is reduced. If FPS is consistently high, resolution
         * is increased.
         */
        private fun checkAndAdaptMeshResolution() {
            val currentResolution = performanceMonitor.getCurrentMeshResolution()
            val newResolution = performanceMonitor.getCurrentMeshResolution()
            
            // Check if resolution changed
            if (currentResolution != newResolution || needsMeshRegeneration) {
                Log.i(TAG, "Adapting mesh resolution from $currentResolution to $newResolution")
                
                // Create new mesh generator with updated resolution
                meshGenerator = MeshGenerator(
                    gridWidth = newResolution.width,
                    gridHeight = newResolution.height
                )
                
                // Regenerate meshes with new resolution
                currentPageMesh = meshGenerator.generateMesh()
                nextPageMesh = meshGenerator.generateMesh()
                
                // Reapply current curl if active
                if (curlRadius > 0) {
                    val curlParams = CurlParameters(
                        position = PointF(curlPosition.x, curlPosition.y),
                        direction = PointF(curlDirection.x, curlDirection.y),
                        radius = curlRadius,
                        angle = (curlRadius / 500f * kotlin.math.PI).toFloat().coerceIn(0f, kotlin.math.PI.toFloat())
                    )
                    currentPageMesh?.let { mesh ->
                        meshGenerator.updateMeshWithCurl(mesh, curlParams)
                    }
                }
                
                needsMeshRegeneration = false
                Log.d(TAG, "Mesh regenerated with resolution: ${newResolution.width}x${newResolution.height}")
            }
        }
        
        /**
         * Check for OpenGL errors and log them
         * Requirements: 1.4, 1.5
         */
        private fun checkGLError(gl: GL10?, operation: String) {
            var error: Int
            while (gl?.glGetError().also { error = it ?: GL10.GL_NO_ERROR } != GL10.GL_NO_ERROR) {
                val errorString = when (error) {
                    GL10.GL_INVALID_ENUM -> "GL_INVALID_ENUM"
                    GL10.GL_INVALID_VALUE -> "GL_INVALID_VALUE"
                    GL10.GL_INVALID_OPERATION -> "GL_INVALID_OPERATION"
                    GL10.GL_STACK_OVERFLOW -> "GL_STACK_OVERFLOW"
                    GL10.GL_STACK_UNDERFLOW -> "GL_STACK_UNDERFLOW"
                    GL10.GL_OUT_OF_MEMORY -> "GL_OUT_OF_MEMORY"
                    else -> "UNKNOWN_ERROR"
                }
                android.util.Log.e(TAG, "OpenGL Error after $operation: $errorString (0x${Integer.toHexString(error)})")
            }
        }
        
        fun setCurrentPageTexture(bitmap: Bitmap) {
            // Delete old texture if it exists
            if (currentPageTexture != 0) {
                // Track GPU memory deallocation
                // Task 15: Requirement 10.3 - Track GPU memory usage
                textureManager.getTextureInfo(currentPageTexture)?.let { info ->
                    performanceMonitor.trackGpuMemoryDeallocation(info.memoryBytes)
                }
                textureManager.deleteTexture(currentPageTexture)
                currentPageTexture = 0
            }
            
            // Load new texture
            currentPageTexture = textureManager.loadTexture(bitmap)
            
            if (currentPageTexture == 0) {
                android.util.Log.e(TAG, "setCurrentPageTexture: Failed to load texture")
            } else {
                // Track GPU memory allocation
                // Task 15: Requirement 10.3 - Track GPU memory usage
                textureManager.getTextureInfo(currentPageTexture)?.let { info ->
                    performanceMonitor.trackGpuMemoryAllocation(info.memoryBytes)
                }
                android.util.Log.d(TAG, "setCurrentPageTexture: Loaded texture $currentPageTexture " +
                        "(GPU memory: ${"%.2f".format(performanceMonitor.getGpuMemoryUsageMB())}MB)")
            }
        }
        
        fun setNextPageTexture(bitmap: Bitmap) {
            // Delete old texture if it exists
            if (nextPageTexture != 0) {
                // Track GPU memory deallocation
                // Task 15: Requirement 10.3 - Track GPU memory usage
                textureManager.getTextureInfo(nextPageTexture)?.let { info ->
                    performanceMonitor.trackGpuMemoryDeallocation(info.memoryBytes)
                }
                textureManager.deleteTexture(nextPageTexture)
                nextPageTexture = 0
            }
            
            // Load new texture
            nextPageTexture = textureManager.loadTexture(bitmap)
            
            if (nextPageTexture == 0) {
                android.util.Log.e(TAG, "setNextPageTexture: Failed to load texture")
            } else {
                // Track GPU memory allocation
                // Task 15: Requirement 10.3 - Track GPU memory usage
                textureManager.getTextureInfo(nextPageTexture)?.let { info ->
                    performanceMonitor.trackGpuMemoryAllocation(info.memoryBytes)
                }
                android.util.Log.d(TAG, "setNextPageTexture: Loaded texture $nextPageTexture " +
                        "(GPU memory: ${"%.2f".format(performanceMonitor.getGpuMemoryUsageMB())}MB)")
            }
        }
        
        fun setPreviousPageTexture(bitmap: Bitmap) {
            // Delete old texture if it exists
            if (previousPageTexture != 0) {
                // Track GPU memory deallocation
                // Task 15: Requirement 10.3 - Track GPU memory usage
                textureManager.getTextureInfo(previousPageTexture)?.let { info ->
                    performanceMonitor.trackGpuMemoryDeallocation(info.memoryBytes)
                }
                textureManager.deleteTexture(previousPageTexture)
                previousPageTexture = 0
            }
            
            // Load new texture
            previousPageTexture = textureManager.loadTexture(bitmap)
            
            if (previousPageTexture == 0) {
                android.util.Log.e(TAG, "setPreviousPageTexture: Failed to load texture")
            } else {
                // Track GPU memory allocation
                // Task 15: Requirement 10.3 - Track GPU memory usage
                textureManager.getTextureInfo(previousPageTexture)?.let { info ->
                    performanceMonitor.trackGpuMemoryAllocation(info.memoryBytes)
                }
                android.util.Log.d(TAG, "setPreviousPageTexture: Loaded texture $previousPageTexture " +
                        "(GPU memory: ${"%.2f".format(performanceMonitor.getGpuMemoryUsageMB())}MB)")
            }
        }
        
        /**
         * Clean up all OpenGL resources
         */
        fun cleanup() {
            android.util.Log.d(TAG, "cleanup: Releasing all textures")
            textureManager.deleteAllTextures()
            currentPageTexture = 0
            nextPageTexture = 0
            previousPageTexture = 0
        }
        
        fun updateCurl(position: PointF, direction: PointF, radius: Float) {
            // Task 15: Requirement 10.4 - Minimize vertex buffer updates
            // Only update if curl parameters have changed significantly
            val positionChanged = kotlin.math.abs(position.x - previousCurlPosition.x) > 0.01f ||
                                 kotlin.math.abs(position.y - previousCurlPosition.y) > 0.01f
            val radiusChanged = kotlin.math.abs(radius - previousCurlRadius) > 0.01f
            
            if (!positionChanged && !radiusChanged) {
                // No significant change, skip update to minimize vertex buffer updates
                return
            }
            
            // Check if we should throttle updates for performance
            // Task 15: Requirement 10.4 - Minimize vertex buffer updates
            if (!performanceMonitor.shouldUpdateVertexBuffer()) {
                // Too soon since last update, skip to maintain frame rate
                return
            }
            
            curlPosition.set(position)
            curlDirection.set(direction)
            curlRadius = radius
            
            // Store previous values for change detection
            previousCurlPosition.set(position)
            previousCurlRadius = radius
            
            // Immediately update mesh with new curl parameters
            // Requirements: 5.3, 5.4 - Real-time mesh updates during drag
            if (curlRadius > 0 && currentPageMesh != null) {
                val curlParams = CurlParameters(
                    position = PointF(curlPosition.x, curlPosition.y),
                    direction = PointF(curlDirection.x, curlDirection.y),
                    radius = curlRadius,
                    angle = (curlRadius / 500f * kotlin.math.PI).toFloat().coerceIn(0f, kotlin.math.PI.toFloat())
                )
                
                // Apply curl to mesh
                meshGenerator.updateMeshWithCurl(currentPageMesh!!, curlParams)
                
                // Apply gradient shading for 3D effect
                // Requirements: 8.3 - Add gradient shading for 3D effect
                visualEffects.applyGradientShading(currentPageMesh!!, curlParams)
                
                // Track vertex buffer update
                // Task 15: Requirement 10.4 - Track vertex buffer updates
                performanceMonitor.recordVertexBufferUpdate()
                
                android.util.Log.d(TAG, "updateCurl: Applied curl to mesh - radius=$curlRadius")
            }
        }
        
        fun resetCurl() {
            curlRadius = 0f
            
            // Reset mesh to flat state
            // Requirements: 6.5, 7.3, 7.5 - Reset curl state
            currentPageMesh?.let { mesh ->
                meshGenerator.updateMeshWithCurl(mesh, CurlParameters.FLAT)
                android.util.Log.d(TAG, "resetCurl: Mesh reset to flat state")
            }
        }
        
        /**
         * Enable or disable visual effects
         * 
         * Requirements: 8.5 - Add configuration to enable/disable effects
         * 
         * @param enabled True to enable effects, false to disable
         */
        fun setVisualEffectsEnabled(enabled: Boolean) {
            visualEffects.setEffectsEnabled(enabled)
        }
        
        /**
         * Check if visual effects are enabled
         */
        fun areVisualEffectsEnabled(): Boolean {
            return visualEffects.areEffectsEnabled()
        }
        
        /**
         * Get performance metrics
         * 
         * Task 15: Requirement 12.3 - Performance metrics logging
         * 
         * @return Map of performance metrics
         */
        fun getPerformanceMetrics(): Map<String, Any> {
            return performanceMonitor.getPerformanceReport()
        }
    }
    
    /**
     * Mesh rendering helper
     * 
     * Provides methods to render PageMesh objects with OpenGL
     * 
     * Requirements: 3.3, 3.5
     */
    private object MeshRenderer {
        private const val TAG = "MeshRenderer"
        
        // Curl mathematics for vertex deformation
        private val curlMath = CurlMathematics()
        
        // Mesh generator for applying curl transformations
        private val meshGenerator = MeshGenerator()
        
        /**
         * Apply curl deformation to mesh vertices
         * 
         * Uses CurlMathematics to apply cylindrical curl transformation
         * to all vertices in the mesh.
         * 
         * Requirements: 4.1, 4.2, 4.3, 4.4
         */
        fun applyCurl(mesh: PageMesh, position: PointF, direction: PointF, radius: Float) {
            // Create curl parameters
            val curlParams = CurlParameters(
                position = position,
                direction = direction,
                radius = radius,
                angle = (radius / 500f * PI).toFloat().coerceIn(0f, PI.toFloat())
            )
            
            // Apply curl transformation to mesh
            meshGenerator.updateMeshWithCurl(mesh, curlParams)
        }
        
        /**
         * Draw the mesh with texture
         * 
         * Requirements: 3.3, 3.5
         * 
         * This method renders the mesh using OpenGL ES 1.x fixed-function pipeline.
         * It uses glDrawElements for efficient indexed rendering.
         */
        fun draw(gl: GL10?, mesh: PageMesh, textureId: Int) {
            if (gl == null) {
                android.util.Log.e(TAG, "draw: GL context is null")
                return
            }
            
            if (textureId == 0) {
                android.util.Log.w(TAG, "draw: Invalid texture ID 0, skipping render")
                return
            }
            
            try {
                // Enable vertex and texture coordinate arrays
                gl.glEnableClientState(GL10.GL_VERTEX_ARRAY)
                gl.glEnableClientState(GL10.GL_TEXTURE_COORD_ARRAY)
                
                // Bind the texture
                gl.glBindTexture(GL10.GL_TEXTURE_2D, textureId)
                
                // Get buffers from mesh
                val vertexBuffer = mesh.getVertexBuffer()
                val texCoordBuffer = mesh.getTexCoordBuffer()
                val indexBuffer = mesh.getIndexBuffer()
                
                // Set vertex pointer
                vertexBuffer.position(0)
                gl.glVertexPointer(3, GL10.GL_FLOAT, 0, vertexBuffer)
                
                // Set texture coordinate pointer
                texCoordBuffer.position(0)
                gl.glTexCoordPointer(2, GL10.GL_FLOAT, 0, texCoordBuffer)
                
                // Draw the mesh using indexed rendering
                // This is more efficient than glDrawArrays for complex meshes
                indexBuffer.position(0)
                gl.glDrawElements(
                    GL10.GL_TRIANGLES,      // Draw triangles
                    mesh.indices.size,       // Number of indices
                    GL10.GL_UNSIGNED_SHORT,  // Index type
                    indexBuffer              // Index buffer
                )
                
                // Disable client state
                gl.glDisableClientState(GL10.GL_VERTEX_ARRAY)
                gl.glDisableClientState(GL10.GL_TEXTURE_COORD_ARRAY)
                
            } catch (e: Exception) {
                android.util.Log.e(TAG, "draw: Error rendering mesh", e)
            }
        }
    }
}
