package com.knowvas.reader

import android.content.Context
import android.content.Intent
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel

/**
 * Simplified ReaderPlugin - handles communication between Flutter and native reader
 */
class ReaderPlugin : FlutterPlugin, MethodChannel.MethodCallHandler, EventChannel.StreamHandler {
    private lateinit var methodChannel: MethodChannel
    private lateinit var eventChannel: EventChannel
    private var eventSink: EventChannel.EventSink? = null
    private var context: Context? = null

    companion object {
        private const val METHOD_CHANNEL_NAME = "com.knowvas.reader/channel"
        private const val EVENT_CHANNEL_NAME = "com.knowvas.reader/events"
    }

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        
        methodChannel = MethodChannel(binding.binaryMessenger, METHOD_CHANNEL_NAME)
        methodChannel.setMethodCallHandler(this)
        
        eventChannel = EventChannel(binding.binaryMessenger, EVENT_CHANNEL_NAME)
        eventChannel.setStreamHandler(this)
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        methodChannel.setMethodCallHandler(null)
        eventChannel.setStreamHandler(null)
        context = null
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            "openReader" -> handleOpenReader(call, result)
            "closeReader" -> handleCloseReader(call, result)
            "setReaderPrefs" -> handleSetReaderPrefs(call, result)
            else -> result.notImplemented()
        }
    }

    private fun handleOpenReader(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        if (args == null) {
            result.error("INVALID_ARGS", "Invalid arguments", null)
            return
        }

        val contentId = args["content_id"] as? Int
        val type = args["type"] as? String
        var fileUrl = args["file_url"] as? String
        val token = args["token"] as? String
        val sessionId = args["session_id"] as? String

        if (contentId == null || type == null || fileUrl == null || sessionId == null) {
            result.error("INVALID_ARGS", "Missing required arguments", null)
            return
        }

        // Handle asset paths - copy from assets to cache directory
        if (fileUrl.startsWith("assets/")) {
            try {
                fileUrl = copyAssetToCache(fileUrl)
                android.util.Log.d("ReaderPlugin", "Copied asset to: $fileUrl")
            } catch (e: Exception) {
                android.util.Log.e("ReaderPlugin", "Failed to copy asset", e)
                result.error("ASSET_COPY_FAILED", "Failed to copy asset: ${e.message}", null)
                return
            }
        }

        when (type) {
            "epub" -> {
                // Create EpubReader and open the file
                val epubReader = com.knowvas.reader.epub.EpubReader(
                    context = context!!,
                    eventSink = eventSink,
                    sessionId = sessionId
                )
                
                epubReader.open(fileUrl, token ?: "") { success, error ->
                    if (success) {
                        // Store the EPUB reader instance in ReaderManager
                        com.knowvas.reader.ReaderManager.addReader(sessionId, epubReader)
                        
                        // Launch ReaderActivity
                        try {
                            val intent = Intent(context, com.knowvas.reader.ui.ReaderActivity::class.java)
                            intent.putExtra(com.knowvas.reader.ui.ReaderActivity.EXTRA_SESSION_ID, sessionId)
                            intent.putExtra(com.knowvas.reader.ui.ReaderActivity.EXTRA_READER_TYPE, "epub")
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            context?.startActivity(intent)
                            
                            result.success(mapOf("status" to "ok"))
                        } catch (e: Exception) {
                            android.util.Log.e("ReaderPlugin", "Failed to launch ReaderActivity", e)
                            result.error("LAUNCH_FAILED", "Failed to launch reader: ${e.message}", null)
                        }
                    } else {
                        result.error("OPEN_FAILED", error ?: "Failed to open EPUB", null)
                    }
                }
            }
            "pdf" -> {
                // Create PdfReader and open the file
                android.util.Log.d("ReaderPlugin", "Opening PDF: $fileUrl")
                val pdfReader = com.knowvas.reader.pdf.PdfReader(
                    context = context!!,
                    eventSink = eventSink,
                    sessionId = sessionId
                )
                
                pdfReader.open(fileUrl, token ?: "") { success, error ->
                    if (success) {
                        android.util.Log.i("ReaderPlugin", "PDF opened successfully")
                        
                        // Store the reader instance
                        com.knowvas.reader.ReaderManager.addReader(sessionId, pdfReader)
                        
                        // Launch PDF ReaderActivity
                        try {
                            val intent = Intent(context, com.knowvas.reader.ui.ReaderActivity::class.java)
                            intent.putExtra(com.knowvas.reader.ui.ReaderActivity.EXTRA_SESSION_ID, sessionId)
                            intent.putExtra(com.knowvas.reader.ui.ReaderActivity.EXTRA_READER_TYPE, "pdf")
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            context?.startActivity(intent)
                            
                            result.success(mapOf("status" to "ok"))
                        } catch (e: Exception) {
                            android.util.Log.e("ReaderPlugin", "Failed to launch PDF ReaderActivity", e)
                            result.error("LAUNCH_FAILED", "Failed to launch PDF reader: ${e.message}", null)
                        }
                    } else {
                        android.util.Log.e("ReaderPlugin", "Failed to open PDF: $error")
                        result.error("OPEN_FAILED", error ?: "Failed to open PDF", null)
                    }
                }
            }
            else -> {
                result.error("UNSUPPORTED_TYPE", "Reader type not supported: $type", null)
            }
        }
    }

    private fun handleCloseReader(call: MethodCall, result: MethodChannel.Result) {
        val args = call.arguments as? Map<*, *>
        val sessionId = args?.get("session_id") as? String
        
        if (sessionId != null) {
            com.knowvas.reader.ReaderManager.removePublication(sessionId)
        }
        
        result.success(null)
    }

    private fun handleSetReaderPrefs(call: MethodCall, result: MethodChannel.Result) {
        // TODO: Implement preferences
        result.success(null)
    }

    override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
        eventSink = events
    }

    override fun onCancel(arguments: Any?) {
        eventSink = null
    }

    /**
     * Copy an asset file to the cache directory so it can be accessed as a regular file
     * @param assetPath Path to the asset (e.g., "assets/sample.pdf")
     * @return Absolute path to the copied file in cache directory
     */
    private fun copyAssetToCache(assetPath: String): String {
        val ctx = context ?: throw IllegalStateException("Context is null")
        
        // Remove "assets/" prefix if present
        val assetName = assetPath.removePrefix("assets/")
        
        // Get the file name
        val fileName = assetName.substringAfterLast('/')
        
        // Create cache file
        val cacheFile = java.io.File(ctx.cacheDir, fileName)
        
        // Copy asset to cache if not already there or if outdated
        if (!cacheFile.exists() || cacheFile.length() == 0L) {
            android.util.Log.d("ReaderPlugin", "Copying asset '$assetName' to cache")
            
            ctx.assets.open(assetName).use { input ->
                cacheFile.outputStream().use { output ->
                    input.copyTo(output)
                }
            }
            
            android.util.Log.d("ReaderPlugin", "Asset copied successfully: ${cacheFile.absolutePath} (${cacheFile.length()} bytes)")
        } else {
            android.util.Log.d("ReaderPlugin", "Using cached asset: ${cacheFile.absolutePath}")
        }
        
        return cacheFile.absolutePath
    }
}
