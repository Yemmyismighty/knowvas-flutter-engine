import Foundation

/// Example usage and tests for EpubSettings
/// This file demonstrates how to use the EpubSettings class
class EpubSettingsExamples {
    
    /// Example 1: Creating settings with defaults
    static func exampleDefaultSettings() {
        let settings = EpubSettings()
        print("Default settings:")
        print(settings.description)
        print("\nGenerated CSS:")
        print(settings.generateCSS())
    }
    
    /// Example 2: Creating settings from ReaderPreferences
    static func exampleFromPreferences() {
        let prefsDict: [String: Any] = [
            "font_size": 18,
            "font_family": "sans-serif",
            "theme": "dark",
            "line_height": 1.8,
            "margin": 1.5
        ]
        
        let preferences = ReaderPreferences(from: prefsDict)
        let settings = EpubSettings(preferences: preferences)
        
        print("Settings from preferences:")
        print(settings.description)
    }
    
    /// Example 3: Updating individual settings
    static func exampleUpdateSettings() {
        let settings = EpubSettings()
        
        print("Initial settings:")
        print(settings.description)
        
        // Update font size
        settings.updateFontSize(20)
        print("\nAfter updating font size to 20:")
        print("Font size: \(settings.fontSize)")
        
        // Update theme
        settings.updateTheme(.sepia)
        print("\nAfter updating theme to sepia:")
        print("Theme: \(settings.theme.rawValue)")
        print("Background color: \(settings.theme.cssBackgroundColor)")
        print("Text color: \(settings.theme.cssTextColor)")
        
        // Update font family
        settings.updateFontFamily(.monospace)
        print("\nAfter updating font family to monospace:")
        print("Font family: \(settings.fontFamily.rawValue)")
    }
    
    /// Example 4: Validation of settings
    static func exampleValidation() {
        let settings = EpubSettings()
        
        // Try to set font size beyond limits
        print("Attempting to set font size to 50 (max is 32):")
        settings.updateFontSize(50)
        print("Actual font size: \(settings.fontSize)")
        
        print("\nAttempting to set font size to 5 (min is 12):")
        settings.updateFontSize(5)
        print("Actual font size: \(settings.fontSize)")
        
        // Try to set line height beyond limits
        print("\nAttempting to set line height to 3.0 (max is 2.5):")
        settings.updateLineHeight(3.0)
        print("Actual line height: \(settings.lineHeight)")
    }
    
    /// Example 5: Batch update with preferences
    static func exampleBatchUpdate() {
        let settings = EpubSettings()
        
        print("Initial settings:")
        print(settings.description)
        
        let prefsDict: [String: Any] = [
            "font_size": 22,
            "theme": "dark",
            "line_height": 2.0
        ]
        
        let preferences = ReaderPreferences(from: prefsDict)
        let hasChanges = settings.updatePreferences(preferences)
        
        print("\nAfter batch update (hasChanges: \(hasChanges)):")
        print(settings.description)
    }
    
    /// Example 6: CSS generation for different themes
    static func exampleCSSGeneration() {
        let themes: [EpubSettings.Theme] = [.light, .sepia, .dark]
        
        for theme in themes {
            let settings = EpubSettings()
            settings.updateTheme(theme)
            
            print("\n=== \(theme.rawValue.uppercased()) THEME ===")
            print("Background: \(theme.cssBackgroundColor)")
            print("Text: \(theme.cssTextColor)")
            print("\nCSS:")
            print(settings.generateCSS())
        }
    }
    
    /// Example 7: JavaScript injection script
    static func exampleJavaScriptInjection() {
        let settings = EpubSettings()
        settings.updateFontSize(18)
        settings.updateTheme(.sepia)
        
        print("JavaScript injection script:")
        print(settings.generateCSSInjectionScript())
    }
    
    /// Example 8: Dictionary conversion
    static func exampleDictionaryConversion() {
        let settings = EpubSettings()
        settings.updateFontSize(20)
        settings.updateTheme(.dark)
        settings.updateFontFamily(.sansSerif)
        
        let dict = settings.toDictionary()
        print("Settings as dictionary:")
        print(dict)
    }
    
    /// Run all examples
    static func runAllExamples() {
        print("========================================")
        print("EPUB SETTINGS EXAMPLES")
        print("========================================\n")
        
        print("\n--- Example 1: Default Settings ---")
        exampleDefaultSettings()
        
        print("\n\n--- Example 2: From Preferences ---")
        exampleFromPreferences()
        
        print("\n\n--- Example 3: Update Settings ---")
        exampleUpdateSettings()
        
        print("\n\n--- Example 4: Validation ---")
        exampleValidation()
        
        print("\n\n--- Example 5: Batch Update ---")
        exampleBatchUpdate()
        
        print("\n\n--- Example 6: CSS Generation ---")
        exampleCSSGeneration()
        
        print("\n\n--- Example 7: JavaScript Injection ---")
        exampleJavaScriptInjection()
        
        print("\n\n--- Example 8: Dictionary Conversion ---")
        exampleDictionaryConversion()
    }
}
