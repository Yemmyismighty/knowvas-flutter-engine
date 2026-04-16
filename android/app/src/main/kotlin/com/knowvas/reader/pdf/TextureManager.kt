package com.knowvas.reader.pdf

import android.graphics.Bitmap
import android.opengl.GLES20
import android.opengl.GLUtils
import android.util.Log
import java.nio.IntBuffer

/**
 * TextureManager handles OpenGL texture lifecycle for page curl rendering
 * 
 * Responsibilities:
 * - Convert Android Bitmaps to OpenGL textures
 * - Configure texture parameters (filtering, wrapping)
 * - Track GPU memory usage
 * - Manage texture lifecycle (creation, binding, deletion)
 * 
 * Requirements: 2.1, 2.2, 2.3
 */
class TextureManager {
    
    companion object {
        private const val TAG = "TextureManager"
        private const val BYTES_PER_PIXEL = 4 // RGBA
    }
    
    // Track all loaded textures for memory management
    private val loadedTextures = mutableMapOf<Int, TextureInfo>()
    
    // Track total GPU memory usage
    private var totalMemoryBytes: Long = 0
    
    /**
     * Load a bitmap as an OpenGL texture
     * 
     * Requirements: 2.1
     * 
     * @param bitmap The bitmap to convert to a texture
     * @return The OpenGL texture ID, or 0 if loading failed
     */
    fun loadTexture(bitmap: Bitmap): Int {
        Log.d(TAG, "loadTexture: Loading bitmap ${bitmap.width}x${bitmap.height}")
        
        try {
            // Generate a new texture ID
            val textureIds = IntArray(1)
            GLES20.glGenTextures(1, textureIds, 0)
            checkGLError("glGenTextures")
            
            val textureId = textureIds[0]
            
            if (textureId == 0) {
                Log.e(TAG, "loadTexture: Failed to generate texture ID")
                return 0
            }
            
            // Bind the texture
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
            checkGLError("glBindTexture")
            
            // Configure texture parameters
            // Requirements: 2.2
            configureTextureParameters()
            
            // Upload bitmap data to GPU
            GLUtils.texImage2D(GLES20.GL_TEXTURE_2D, 0, bitmap, 0)
            checkGLError("texImage2D")
            
            // Calculate memory usage
            val memoryBytes = (bitmap.width * bitmap.height * BYTES_PER_PIXEL).toLong()
            
            // Track texture info
            val textureInfo = TextureInfo(
                textureId = textureId,
                width = bitmap.width,
                height = bitmap.height,
                memoryBytes = memoryBytes
            )
            loadedTextures[textureId] = textureInfo
            totalMemoryBytes += memoryBytes
            
            Log.d(TAG, "loadTexture: Successfully loaded texture $textureId " +
                    "(${bitmap.width}x${bitmap.height}, ${memoryBytes / 1024}KB). " +
                    "Total GPU memory: ${totalMemoryBytes / 1024 / 1024}MB")
            
            // Unbind texture
            GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, 0)
            
            return textureId
            
        } catch (e: Exception) {
            Log.e(TAG, "loadTexture: Error loading texture", e)
            return 0
        }
    }
    
    /**
     * Configure texture parameters for optimal rendering
     * 
     * Requirements: 2.2
     * - Linear filtering for smooth scaling
     * - Clamp-to-edge wrapping to prevent artifacts at edges
     */
    private fun configureTextureParameters() {
        // Set minification filter (when texture is scaled down)
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_MIN_FILTER,
            GLES20.GL_LINEAR
        )
        checkGLError("glTexParameteri(MIN_FILTER)")
        
        // Set magnification filter (when texture is scaled up)
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_MAG_FILTER,
            GLES20.GL_LINEAR
        )
        checkGLError("glTexParameteri(MAG_FILTER)")
        
        // Set wrap mode for S coordinate (horizontal)
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_WRAP_S,
            GLES20.GL_CLAMP_TO_EDGE
        )
        checkGLError("glTexParameteri(WRAP_S)")
        
        // Set wrap mode for T coordinate (vertical)
        GLES20.glTexParameteri(
            GLES20.GL_TEXTURE_2D,
            GLES20.GL_TEXTURE_WRAP_T,
            GLES20.GL_CLAMP_TO_EDGE
        )
        checkGLError("glTexParameteri(WRAP_T)")
        
        Log.d(TAG, "configureTextureParameters: Configured linear filtering and clamp-to-edge wrapping")
    }
    
    /**
     * Bind a texture for rendering
     * 
     * @param textureId The texture ID to bind
     */
    fun bindTexture(textureId: Int) {
        if (textureId == 0) {
            Log.w(TAG, "bindTexture: Attempted to bind invalid texture ID 0")
            return
        }
        
        if (!loadedTextures.containsKey(textureId)) {
            Log.w(TAG, "bindTexture: Texture $textureId not found in loaded textures")
        }
        
        GLES20.glBindTexture(GLES20.GL_TEXTURE_2D, textureId)
        checkGLError("glBindTexture")
    }
    
    /**
     * Delete a texture and free GPU memory
     * 
     * Requirements: 2.3
     * 
     * @param textureId The texture ID to delete
     */
    fun deleteTexture(textureId: Int) {
        if (textureId == 0) {
            Log.w(TAG, "deleteTexture: Attempted to delete invalid texture ID 0")
            return
        }
        
        val textureInfo = loadedTextures[textureId]
        if (textureInfo == null) {
            Log.w(TAG, "deleteTexture: Texture $textureId not found in loaded textures")
            return
        }
        
        try {
            // Delete the texture from GPU
            val textureIds = intArrayOf(textureId)
            GLES20.glDeleteTextures(1, textureIds, 0)
            checkGLError("glDeleteTextures")
            
            // Update memory tracking
            totalMemoryBytes -= textureInfo.memoryBytes
            loadedTextures.remove(textureId)
            
            Log.d(TAG, "deleteTexture: Deleted texture $textureId " +
                    "(freed ${textureInfo.memoryBytes / 1024}KB). " +
                    "Total GPU memory: ${totalMemoryBytes / 1024 / 1024}MB")
            
        } catch (e: Exception) {
            Log.e(TAG, "deleteTexture: Error deleting texture $textureId", e)
        }
    }
    
    /**
     * Delete all loaded textures
     * 
     * Requirements: 2.3
     */
    fun deleteAllTextures() {
        Log.d(TAG, "deleteAllTextures: Deleting ${loadedTextures.size} textures")
        
        val textureIds = loadedTextures.keys.toIntArray()
        
        if (textureIds.isNotEmpty()) {
            try {
                GLES20.glDeleteTextures(textureIds.size, textureIds, 0)
                checkGLError("glDeleteTextures")
                
                Log.d(TAG, "deleteAllTextures: Freed ${totalMemoryBytes / 1024 / 1024}MB of GPU memory")
                
                loadedTextures.clear()
                totalMemoryBytes = 0
                
            } catch (e: Exception) {
                Log.e(TAG, "deleteAllTextures: Error deleting textures", e)
            }
        }
    }
    
    /**
     * Get the total GPU memory used by textures
     * 
     * @return Memory usage in bytes
     */
    fun getTotalMemoryBytes(): Long {
        return totalMemoryBytes
    }
    
    /**
     * Get the total GPU memory used by textures in megabytes
     * 
     * @return Memory usage in MB
     */
    fun getTotalMemoryMB(): Float {
        return totalMemoryBytes / 1024f / 1024f
    }
    
    /**
     * Get the number of loaded textures
     * 
     * @return Number of textures currently loaded
     */
    fun getTextureCount(): Int {
        return loadedTextures.size
    }
    
    /**
     * Check if a texture is loaded
     * 
     * @param textureId The texture ID to check
     * @return True if the texture is loaded, false otherwise
     */
    fun isTextureLoaded(textureId: Int): Boolean {
        return loadedTextures.containsKey(textureId)
    }
    
    /**
     * Get information about a loaded texture
     * 
     * @param textureId The texture ID
     * @return TextureInfo or null if not found
     */
    fun getTextureInfo(textureId: Int): TextureInfo? {
        return loadedTextures[textureId]
    }
    
    /**
     * Check for OpenGL errors and log them
     */
    private fun checkGLError(operation: String) {
        var error: Int
        while (GLES20.glGetError().also { error = it } != GLES20.GL_NO_ERROR) {
            val errorString = when (error) {
                GLES20.GL_INVALID_ENUM -> "GL_INVALID_ENUM"
                GLES20.GL_INVALID_VALUE -> "GL_INVALID_VALUE"
                GLES20.GL_INVALID_OPERATION -> "GL_INVALID_OPERATION"
                GLES20.GL_OUT_OF_MEMORY -> "GL_OUT_OF_MEMORY"
                GLES20.GL_INVALID_FRAMEBUFFER_OPERATION -> "GL_INVALID_FRAMEBUFFER_OPERATION"
                else -> "UNKNOWN_ERROR"
            }
            Log.e(TAG, "OpenGL Error after $operation: $errorString (0x${Integer.toHexString(error)})")
        }
    }
    
    /**
     * Data class to track texture information
     */
    data class TextureInfo(
        val textureId: Int,
        val width: Int,
        val height: Int,
        val memoryBytes: Long
    )
}
