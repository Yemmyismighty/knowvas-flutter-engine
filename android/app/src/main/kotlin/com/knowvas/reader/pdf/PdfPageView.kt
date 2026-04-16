package com.knowvas.reader.pdf

import android.content.Context
import android.graphics.Bitmap
import android.graphics.Canvas
import android.graphics.Matrix
import android.graphics.Paint
import android.util.AttributeSet
import android.view.GestureDetector
import android.view.MotionEvent
import android.view.ScaleGestureDetector
import android.view.View
import kotlin.math.max
import kotlin.math.min

/**
 * Custom view for displaying PDF pages with zoom and pan support
 * 
 * Requirements:
 * - 6.4: Pinch-to-zoom with 100% to 400% zoom limits
 * - 6.5: Pan gestures for zoomed pages
 * - 6.6: Double-tap to toggle zoom levels
 */
class PdfPageView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : View(context, attrs, defStyleAttr) {

    // Zoom constraints (Requirement 6.4)
    companion object {
        private const val MIN_ZOOM = 1.0f  // 100%
        private const val MAX_ZOOM = 4.0f  // 400%
        private const val FIT_TO_WIDTH_ZOOM = 1.5f  // Zoom level for fit-to-width
    }

    // Current page bitmap
    private var pageBitmap: Bitmap? = null
    
    // Transformation matrix for zoom and pan
    private val matrix = Matrix()
    private val paint = Paint(Paint.ANTI_ALIAS_FLAG or Paint.FILTER_BITMAP_FLAG)
    
    // Current zoom level
    private var currentZoom = MIN_ZOOM
    
    // Pan offset
    private var translateX = 0f
    private var translateY = 0f
    
    // Gesture detectors
    private val scaleGestureDetector: ScaleGestureDetector
    private val gestureDetector: GestureDetector
    
    // Zoom state tracking
    private var isZoomed = false
    
    // Callbacks
    var onZoomChanged: ((Float) -> Unit)? = null
    var onDoubleTap: (() -> Unit)? = null
    
    init {
        // Initialize scale gesture detector for pinch-to-zoom (Requirement 6.4)
        scaleGestureDetector = ScaleGestureDetector(context, ScaleListener())
        
        // Initialize gesture detector for double-tap and pan (Requirements 6.5, 6.6)
        gestureDetector = GestureDetector(context, GestureListener())
    }
    
    /**
     * Set the page bitmap to display
     */
    fun setPageBitmap(bitmap: Bitmap?) {
        pageBitmap = bitmap
        
        // Reset zoom and pan when new page is loaded
        resetTransform()
        
        invalidate()
    }
    
    /**
     * Get current zoom level
     */
    fun getZoom(): Float = currentZoom
    
    /**
     * Set zoom level programmatically
     * @param zoom Zoom level between MIN_ZOOM and MAX_ZOOM
     * @param focusX X coordinate of zoom focus point (default: center)
     * @param focusY Y coordinate of zoom focus point (default: center)
     */
    fun setZoom(zoom: Float, focusX: Float = width / 2f, focusY: Float = height / 2f) {
        val newZoom = zoom.coerceIn(MIN_ZOOM, MAX_ZOOM)
        val scaleFactor = newZoom / currentZoom
        
        // Apply zoom with focus point
        matrix.postScale(scaleFactor, scaleFactor, focusX, focusY)
        currentZoom = newZoom
        
        // Constrain pan after zoom
        constrainPan()
        
        // Update zoom state
        isZoomed = currentZoom > MIN_ZOOM
        
        // Notify callback
        onZoomChanged?.invoke(currentZoom)
        
        invalidate()
    }
    
    /**
     * Toggle between fit-to-screen and fit-to-width zoom levels
     * Requirement 6.6: Double-tap to toggle zoom levels
     */
    fun toggleZoom(focusX: Float = width / 2f, focusY: Float = height / 2f) {
        val targetZoom = if (currentZoom <= MIN_ZOOM) {
            FIT_TO_WIDTH_ZOOM
        } else {
            MIN_ZOOM
        }
        
        // Reset transform first
        resetTransform()
        
        // Apply new zoom
        setZoom(targetZoom, focusX, focusY)
        
        android.util.Log.d("PdfPageView", "Toggled zoom to ${currentZoom}x")
    }
    
    /**
     * Reset zoom and pan to default state
     */
    fun resetTransform() {
        matrix.reset()
        currentZoom = MIN_ZOOM
        translateX = 0f
        translateY = 0f
        isZoomed = false
        
        // Center the page
        pageBitmap?.let { bitmap ->
            val scale = min(
                width.toFloat() / bitmap.width,
                height.toFloat() / bitmap.height
            )
            
            val scaledWidth = bitmap.width * scale
            val scaledHeight = bitmap.height * scale
            
            translateX = (width - scaledWidth) / 2f
            translateY = (height - scaledHeight) / 2f
            
            matrix.setScale(scale, scale)
            matrix.postTranslate(translateX, translateY)
        }
        
        invalidate()
    }
    
    /**
     * Constrain pan to keep content within bounds
     */
    private fun constrainPan() {
        pageBitmap?.let { bitmap ->
            val values = FloatArray(9)
            matrix.getValues(values)
            
            val scaleX = values[Matrix.MSCALE_X]
            val scaleY = values[Matrix.MSCALE_Y]
            val transX = values[Matrix.MTRANS_X]
            val transY = values[Matrix.MTRANS_Y]
            
            val scaledWidth = bitmap.width * scaleX
            val scaledHeight = bitmap.height * scaleY
            
            // Calculate bounds
            val minX = min(0f, width - scaledWidth)
            val maxX = max(0f, width - scaledWidth)
            val minY = min(0f, height - scaledHeight)
            val maxY = max(0f, height - scaledHeight)
            
            // Constrain translation
            val newTransX = transX.coerceIn(minX, maxX)
            val newTransY = transY.coerceIn(minY, maxY)
            
            // Update matrix if needed
            if (newTransX != transX || newTransY != transY) {
                matrix.setValues(floatArrayOf(
                    scaleX, values[Matrix.MSKEW_X], newTransX,
                    values[Matrix.MSKEW_Y], scaleY, newTransY,
                    values[Matrix.MPERSP_0], values[Matrix.MPERSP_1], values[Matrix.MPERSP_2]
                ))
            }
        }
    }
    
    override fun onDraw(canvas: Canvas) {
        super.onDraw(canvas)
        
        pageBitmap?.let { bitmap ->
            canvas.drawBitmap(bitmap, matrix, paint)
        }
    }
    
    override fun onTouchEvent(event: MotionEvent): Boolean {
        var handled = scaleGestureDetector.onTouchEvent(event)
        handled = gestureDetector.onTouchEvent(event) || handled
        return handled || super.onTouchEvent(event)
    }
    
    /**
     * Scale gesture listener for pinch-to-zoom
     * Requirement 6.4: Pinch-to-zoom with 100% to 400% zoom limits
     */
    private inner class ScaleListener : ScaleGestureDetector.SimpleOnScaleGestureListener() {
        override fun onScale(detector: ScaleGestureDetector): Boolean {
            val scaleFactor = detector.scaleFactor
            val newZoom = (currentZoom * scaleFactor).coerceIn(MIN_ZOOM, MAX_ZOOM)
            
            // Only apply if zoom actually changes
            if (newZoom != currentZoom) {
                val actualScaleFactor = newZoom / currentZoom
                
                // Apply scale with focus point
                matrix.postScale(
                    actualScaleFactor,
                    actualScaleFactor,
                    detector.focusX,
                    detector.focusY
                )
                
                currentZoom = newZoom
                
                // Constrain pan after zoom
                constrainPan()
                
                // Update zoom state
                isZoomed = currentZoom > MIN_ZOOM
                
                // Notify callback
                onZoomChanged?.invoke(currentZoom)
                
                invalidate()
                
                android.util.Log.d("PdfPageView", "Zoom: ${currentZoom}x")
            }
            
            return true
        }
    }
    
    /**
     * Gesture listener for pan and double-tap
     * Requirements 6.5, 6.6: Pan gestures and double-tap zoom toggle
     */
    private inner class GestureListener : GestureDetector.SimpleOnGestureListener() {
        
        /**
         * Handle scroll/pan gestures
         * Requirement 6.5: Pan gestures for zoomed pages
         */
        override fun onScroll(
            e1: MotionEvent?,
            e2: MotionEvent,
            distanceX: Float,
            distanceY: Float
        ): Boolean {
            // Only allow pan when zoomed
            if (isZoomed) {
                matrix.postTranslate(-distanceX, -distanceY)
                constrainPan()
                invalidate()
                return true
            }
            return false
        }
        
        /**
         * Handle double-tap to toggle zoom
         * Requirement 6.6: Double-tap to toggle zoom levels
         */
        override fun onDoubleTap(e: MotionEvent): Boolean {
            toggleZoom(e.x, e.y)
            onDoubleTap?.invoke()
            return true
        }
        
        /**
         * Required to enable double-tap detection
         */
        override fun onDown(e: MotionEvent): Boolean {
            return true
        }
    }
}
