import Flutter
import UIKit

/// Main plugin class that handles communication between Flutter and native iOS reader modules
public class ReaderPlugin: NSObject, FlutterPlugin {
    private let readerManager = ReaderManager()
    private var eventSink: FlutterEventSink?
    
    /// Register the plugin with Flutter
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(
            name: "com.knowvas.reader/channel",
            binaryMessenger: registrar.messenger()
        )
        let eventChannel = FlutterEventChannel(
            name: "com.knowvas.reader/events",
            binaryMessenger: registrar.messenger()
        )
        
        let instance = ReaderPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        eventChannel.setStreamHandler(instance)
    }
    
    /// Handle method calls from Flutter
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        switch call.method {
        case "openReader":
            handleOpenReader(call: call, result: result)
            
        case "closeReader":
            handleCloseReader(call: call, result: result)
            
        case "setReaderPrefs":
            handleSetReaderPrefs(call: call, result: result)
            
        case "loadAudio":
            handleLoadAudio(call: call, result: result)
            
        case "controlAudio":
            handleControlAudio(call: call, result: result)
            
        case "addBookmark":
            handleAddBookmark(call: call, result: result)
            
        case "removeBookmark":
            handleRemoveBookmark(call: call, result: result)
            
        case "getBookmarks":
            handleGetBookmarks(call: call, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    // MARK: - Method Handlers
    
    private func handleOpenReader(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Invalid arguments for openReader",
                details: nil
            ))
            return
        }
        
        readerManager.openReader(args: args, eventSink: eventSink) { response in
            result(response)
        }
    }
    
    private func handleCloseReader(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any],
              let sessionId = args["session_id"] as? String else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Invalid arguments for closeReader",
                details: nil
            ))
            return
        }
        
        readerManager.closeReader(sessionId: sessionId) { response in
            result(response)
        }
    }
    
    private func handleSetReaderPrefs(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Invalid arguments for setReaderPrefs",
                details: nil
            ))
            return
        }
        
        readerManager.setPreferences(args: args) { response in
            result(response)
        }
    }
    
    private func handleLoadAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Invalid arguments for loadAudio",
                details: nil
            ))
            return
        }
        
        readerManager.loadAudio(args: args) { response in
            result(response)
        }
    }
    
    private func handleControlAudio(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Invalid arguments for controlAudio",
                details: nil
            ))
            return
        }
        
        readerManager.controlAudio(args: args) { response in
            result(response)
        }
    }
    
    private func handleAddBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Invalid arguments for addBookmark",
                details: nil
            ))
            return
        }
        
        readerManager.addBookmark(args: args) { response in
            result(response)
        }
    }
    
    private func handleRemoveBookmark(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Invalid arguments for removeBookmark",
                details: nil
            ))
            return
        }
        
        readerManager.removeBookmark(args: args) { response in
            result(response)
        }
    }
    
    private func handleGetBookmarks(call: FlutterMethodCall, result: @escaping FlutterResult) {
        guard let args = call.arguments as? [String: Any] else {
            result(FlutterError(
                code: "INVALID_ARGS",
                message: "Invalid arguments for getBookmarks",
                details: nil
            ))
            return
        }
        
        readerManager.getBookmarks(args: args) { response in
            result(response)
        }
    }
}

// MARK: - FlutterStreamHandler

extension ReaderPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        self.eventSink = nil
        return nil
    }
}
