import Foundation
import UIKit

/// EPUB reader settings manager
/// Handles font size, font family, theme, line height, and margin preferences
class EpubSettings {
    
    // MARK: - Properties
    
    private(set) var fontSize: Int
    private(set) var fontFamily: FontFamily
    private(set) var theme: Theme
    private(set) var lineHeight: Double
    private(set) var margin: Double
    
    // MARK: - Enums
    
    enum FontFamily: String, CaseIterable {
        case serif = "serif"
        case sansSerif = "sans-serif"
        case monospace = "monospace"
        
        var systemFont: UIFont {
            let size: CGFloat = 16.0
            switch self {
            case .serif:
                return UIFont(name: "Georgia", size: size) ?? UIFont.systemFont(ofSize: size)
            case .sansSerif:
                return UIFont.systemFont(ofSize: size)
            case .monospace:
                return UIFont.monospacedSystemFont(ofSize: size, weight: .regular)
            }
        }
        
        var cssName: String {
            switch self {
            case .serif:
                return "Georgia, 'Times New Roman', serif"
            case .sansSerif:
                return "-apple-system, BlinkMacSystemFont, 'Helvetica Neue', sans-serif"
            case .monospace:
                return "'Courier New', Courier, monospace"
            }
        }
    }
    
    enum Theme: String, CaseIterable {
        case light = "light"
        case sepia = "sepia"
        case dark = "dark"
        
        var backgroundColor: UIColor {
            switch self {
            case .light:
                return UIColor.white
            case .sepia:
                return UIColor(red: 0.98, green: 0.96, blue: 0.90, alpha: 1.0)
            case .dark:
                return UIColor(red: 0.12, green: 0.12, blue: 0.12, alpha: 1.0)
            }
        }
        
        var textColor: UIColor {
            switch self {
            case .light:
                return UIColor.black
            case .sepia:
                return UIColor(red: 0.20, green: 0.18, blue: 0.15, alpha: 1.0)
            case .dark:
                return UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
            }
        }
        
        var cssBackgroundColor: String {
            switch self {
            case .light:
                return "#FFFFFF"
            case .sepia:
                return "#FAF4E4"
            case .dark:
                return "#1E1E1E"
            }
        }
        
        var cssTextColor: String {
            switch self {
            case .light:
                return "#000000"
            case .sepia:
                return "#332E26"
            case .dark:
                return "#D9D9D9"
            }
        }
    }
    
    // MARK: - Constants
    
    struct Constants {
        static let minFontSize = 12
        static let maxFontSize = 32
        static let defaultFontSize = 16
        
        static let minLineHeight = 1.0
        static let maxLineHeight = 2.5
        static let defaultLineHeight = 1.5
        
        static let minMargin = 0.5
        static let maxMargin = 2.0
        static let defaultMargin = 1.0
    }
    
    // MARK: - Initialization
    
    init() {
        self.fontSize = Constants.defaultFontSize
        self.fontFamily = .serif
        self.theme = .light
        self.lineHeight = Constants.defaultLineHeight
        self.margin = Constants.defaultMargin
    }
    
    init(preferences: ReaderPreferences) {
        // Font size with validation
        if let size = preferences.fontSize {
            self.fontSize = min(max(size, Constants.minFontSize), Constants.maxFontSize)
        } else {
            self.fontSize = Constants.defaultFontSize
        }
        
        // Font family
        if let family = preferences.fontFamily,
           let fontFamily = FontFamily(rawValue: family) {
            self.fontFamily = fontFamily
        } else {
            self.fontFamily = .serif
        }
        
        // Theme
        if let themeStr = preferences.theme,
           let theme = Theme(rawValue: themeStr) {
            self.theme = theme
        } else {
            self.theme = .light
        }
        
        // Line height with validation
        if let height = preferences.lineHeight {
            self.lineHeight = min(max(height, Constants.minLineHeight), Constants.maxLineHeight)
        } else {
            self.lineHeight = Constants.defaultLineHeight
        }
        
        // Margin with validation
        if let marginValue = preferences.margin {
            self.margin = min(max(marginValue, Constants.minMargin), Constants.maxMargin)
        } else {
            self.margin = Constants.defaultMargin
        }
    }
    
    // MARK: - Update Methods
    
    /// Update font size
    /// - Parameter size: Font size in points (12-32)
    /// - Returns: True if the value was updated
    @discardableResult
    func updateFontSize(_ size: Int) -> Bool {
        let validatedSize = min(max(size, Constants.minFontSize), Constants.maxFontSize)
        guard validatedSize != fontSize else { return false }
        fontSize = validatedSize
        return true
    }
    
    /// Update font family
    /// - Parameter family: Font family enum value
    /// - Returns: True if the value was updated
    @discardableResult
    func updateFontFamily(_ family: FontFamily) -> Bool {
        guard family != fontFamily else { return false }
        fontFamily = family
        return true
    }
    
    /// Update font family from string
    /// - Parameter familyString: Font family string ("serif", "sans-serif", "monospace")
    /// - Returns: True if the value was updated
    @discardableResult
    func updateFontFamily(fromString familyString: String) -> Bool {
        guard let family = FontFamily(rawValue: familyString) else { return false }
        return updateFontFamily(family)
    }
    
    /// Update theme
    /// - Parameter newTheme: Theme enum value
    /// - Returns: True if the value was updated
    @discardableResult
    func updateTheme(_ newTheme: Theme) -> Bool {
        guard newTheme != theme else { return false }
        theme = newTheme
        return true
    }
    
    /// Update theme from string
    /// - Parameter themeString: Theme string ("light", "sepia", "dark")
    /// - Returns: True if the value was updated
    @discardableResult
    func updateTheme(fromString themeString: String) -> Bool {
        guard let newTheme = Theme(rawValue: themeString) else { return false }
        return updateTheme(newTheme)
    }
    
    /// Update line height
    /// - Parameter height: Line height multiplier (1.0-2.5)
    /// - Returns: True if the value was updated
    @discardableResult
    func updateLineHeight(_ height: Double) -> Bool {
        let validatedHeight = min(max(height, Constants.minLineHeight), Constants.maxLineHeight)
        guard validatedHeight != lineHeight else { return false }
        lineHeight = validatedHeight
        return true
    }
    
    /// Update margin
    /// - Parameter marginValue: Margin multiplier (0.5-2.0)
    /// - Returns: True if the value was updated
    @discardableResult
    func updateMargin(_ marginValue: Double) -> Bool {
        let validatedMargin = min(max(marginValue, Constants.minMargin), Constants.maxMargin)
        guard validatedMargin != margin else { return false }
        margin = validatedMargin
        return true
    }
    
    /// Update multiple preferences at once
    /// - Parameter preferences: ReaderPreferences object
    /// - Returns: True if any value was updated
    @discardableResult
    func updatePreferences(_ preferences: ReaderPreferences) -> Bool {
        var hasChanges = false
        
        if let size = preferences.fontSize {
            hasChanges = updateFontSize(size) || hasChanges
        }
        
        if let family = preferences.fontFamily {
            hasChanges = updateFontFamily(fromString: family) || hasChanges
        }
        
        if let themeStr = preferences.theme {
            hasChanges = updateTheme(fromString: themeStr) || hasChanges
        }
        
        if let height = preferences.lineHeight {
            hasChanges = updateLineHeight(height) || hasChanges
        }
        
        if let marginValue = preferences.margin {
            hasChanges = updateMargin(marginValue) || hasChanges
        }
        
        return hasChanges
    }
    
    // MARK: - CSS Generation
    
    /// Generate CSS string for applying settings to EPUB content
    /// - Returns: CSS string with all current settings
    func generateCSS() -> String {
        let marginPx = Int(margin * 20) // Convert margin multiplier to pixels
        
        return """
        body {
            font-size: \(fontSize)px !important;
            font-family: \(fontFamily.cssName) !important;
            line-height: \(lineHeight) !important;
            background-color: \(theme.cssBackgroundColor) !important;
            color: \(theme.cssTextColor) !important;
            margin: \(marginPx)px !important;
            padding: \(marginPx)px !important;
        }
        
        p, div, span {
            font-size: inherit !important;
            font-family: inherit !important;
            line-height: inherit !important;
            color: inherit !important;
        }
        
        h1, h2, h3, h4, h5, h6 {
            font-family: inherit !important;
            color: inherit !important;
        }
        
        a {
            color: \(theme == .dark ? "#6BA4FF" : "#0066CC") !important;
        }
        """
    }
    
    /// Generate JavaScript code to inject CSS into EPUB
    /// - Returns: JavaScript string for CSS injection
    func generateCSSInjectionScript() -> String {
        let css = generateCSS()
        let escapedCSS = css.replacingOccurrences(of: "\n", with: " ")
            .replacingOccurrences(of: "'", with: "\\'")
        
        return """
        (function() {
            var style = document.getElementById('knowvas-reader-style');
            if (!style) {
                style = document.createElement('style');
                style.id = 'knowvas-reader-style';
                document.head.appendChild(style);
            }
            style.textContent = '\(escapedCSS)';
        })();
        """
    }
    
    // MARK: - Dictionary Conversion
    
    /// Convert settings to dictionary for serialization
    /// - Returns: Dictionary representation of settings
    func toDictionary() -> [String: Any] {
        return [
            "font_size": fontSize,
            "font_family": fontFamily.rawValue,
            "theme": theme.rawValue,
            "line_height": lineHeight,
            "margin": margin
        ]
    }
    
    // MARK: - Description
    
    var description: String {
        return """
        EpubSettings(
            fontSize: \(fontSize)px,
            fontFamily: \(fontFamily.rawValue),
            theme: \(theme.rawValue),
            lineHeight: \(lineHeight),
            margin: \(margin)
        )
        """
    }
}
