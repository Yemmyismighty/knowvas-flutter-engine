/// Content sanitizer for preventing XSS attacks in EPUB and other HTML content
/// 
/// This sanitizer removes potentially dangerous HTML elements and attributes
/// that could be used for XSS attacks or malicious code execution.
class ContentSanitizer {
  ContentSanitizer._();

  /// Sanitize HTML content to prevent XSS attacks
  /// 
  /// Removes:
  /// - Script tags and their content
  /// - Event handler attributes (onclick, onload, etc.)
  /// - JavaScript protocol in URLs
  /// - Iframe tags
  /// - Object and embed tags
  /// - Form elements
  /// - Meta refresh tags
  /// 
  /// Example:
  /// ```dart
  /// final safe = ContentSanitizer.sanitizeHTML(unsafeHtml);
  /// ```
  static String sanitizeHTML(String html) {
    if (html.isEmpty) return html;

    var sanitized = html;

    // Remove script tags and their content (case-insensitive, multiline)
    sanitized = sanitized.replaceAll(
      RegExp(
        r'<script[^>]*>.*?</script>',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
      '',
    );

    // Remove noscript tags
    sanitized = sanitized.replaceAll(
      RegExp(
        r'<noscript[^>]*>.*?</noscript>',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
      '',
    );

    // Remove iframe tags
    sanitized = sanitized.replaceAll(
      RegExp(
        r'<iframe[^>]*>.*?</iframe>',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
      '',
    );

    // Remove object tags
    sanitized = sanitized.replaceAll(
      RegExp(
        r'<object[^>]*>.*?</object>',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
      '',
    );

    // Remove embed tags
    sanitized = sanitized.replaceAll(
      RegExp(
        r'<embed[^>]*>',
        caseSensitive: false,
      ),
      '',
    );

    // Remove form elements
    sanitized = sanitized.replaceAll(
      RegExp(
        r'<form[^>]*>.*?</form>',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
      '',
    );

    // Remove meta refresh tags
    sanitized = sanitized.replaceAll(
      RegExp(
        r'<meta[^>]*http-equiv=["\']?refresh["\']?[^>]*>',
        caseSensitive: false,
      ),
      '',
    );

    // Remove all event handler attributes (onclick, onload, onerror, etc.)
    sanitized = sanitized.replaceAll(
      RegExp(
        r'\s+on\w+\s*=\s*["\'][^"\']*["\']',
        caseSensitive: false,
      ),
      '',
    );

    // Remove event handlers without quotes
    sanitized = sanitized.replaceAll(
      RegExp(
        r'\s+on\w+\s*=\s*[^\s>]+',
        caseSensitive: false,
      ),
      '',
    );

    // Remove javascript: protocol from URLs
    sanitized = sanitized.replaceAll(
      RegExp(
        r'javascript:',
        caseSensitive: false,
      ),
      '',
    );

    // Remove data: protocol from URLs (can be used for XSS)
    sanitized = sanitized.replaceAll(
      RegExp(
        r'data:text/html',
        caseSensitive: false,
      ),
      '',
    );

    // Remove vbscript: protocol
    sanitized = sanitized.replaceAll(
      RegExp(
        r'vbscript:',
        caseSensitive: false,
      ),
      '',
    );

    // Remove style tags with expression() or behavior (IE-specific XSS)
    sanitized = sanitized.replaceAll(
      RegExp(
        r'<style[^>]*>.*?(expression|behavior)\s*\([^)]*\).*?</style>',
        caseSensitive: false,
        multiLine: true,
        dotAll: true,
      ),
      '',
    );

    // Remove style attributes with expression() or behavior
    sanitized = sanitized.replaceAll(
      RegExp(
        r'style\s*=\s*["\'][^"\']*?(expression|behavior)\s*\([^)]*\)[^"\']*?["\']',
        caseSensitive: false,
      ),
      '',
    );

    // Remove base tags (can be used to hijack relative URLs)
    sanitized = sanitized.replaceAll(
      RegExp(
        r'<base[^>]*>',
        caseSensitive: false,
      ),
      '',
    );

    // Remove link tags with javascript or data protocols
    sanitized = sanitized.replaceAll(
      RegExp(
        r'<link[^>]*href\s*=\s*["\']?(javascript:|data:)[^"\']*["\']?[^>]*>',
        caseSensitive: false,
      ),
      '',
    );

    return sanitized;
  }

  /// Sanitize CSS content to prevent CSS-based attacks
  /// 
  /// Removes:
  /// - expression() functions (IE-specific)
  /// - behavior properties (IE-specific)
  /// - @import rules with javascript: or data: protocols
  /// - url() with javascript: or data: protocols
  static String sanitizeCSS(String css) {
    if (css.isEmpty) return css;

    var sanitized = css;

    // Remove expression() functions
    sanitized = sanitized.replaceAll(
      RegExp(
        r'expression\s*\([^)]*\)',
        caseSensitive: false,
      ),
      '',
    );

    // Remove behavior properties
    sanitized = sanitized.replaceAll(
      RegExp(
        r'behavior\s*:\s*url\([^)]*\)',
        caseSensitive: false,
      ),
      '',
    );

    // Remove @import with javascript: or data: protocols
    sanitized = sanitized.replaceAll(
      RegExp(
        r'@import\s+["\']?(javascript:|data:)[^"\']*["\']?',
        caseSensitive: false,
      ),
      '',
    );

    // Remove url() with javascript: or data: protocols
    sanitized = sanitized.replaceAll(
      RegExp(
        r'url\s*\(\s*["\']?(javascript:|data:text/html)[^"\']*["\']?\s*\)',
        caseSensitive: false,
      ),
      '',
    );

    return sanitized;
  }

  /// Sanitize URL to prevent protocol-based attacks
  /// 
  /// Returns null if URL uses dangerous protocol
  /// Allowed protocols: http, https, mailto, tel, sms
  static String? sanitizeURL(String url) {
    if (url.isEmpty) return url;

    final trimmed = url.trim().toLowerCase();

    // Check for dangerous protocols
    final dangerousProtocols = [
      'javascript:',
      'data:',
      'vbscript:',
      'file:',
      'about:',
    ];

    for (final protocol in dangerousProtocols) {
      if (trimmed.startsWith(protocol)) {
        return null; // Reject dangerous URLs
      }
    }

    // Allow safe protocols
    final safeProtocols = [
      'http://',
      'https://',
      'mailto:',
      'tel:',
      'sms:',
    ];

    // If URL has a protocol, ensure it's safe
    if (trimmed.contains(':')) {
      final hasSafeProtocol = safeProtocols.any(trimmed.startsWith);
      if (!hasSafeProtocol) {
        return null; // Reject unknown protocols
      }
    }

    return url;
  }

  /// Sanitize text content by escaping HTML entities
  /// 
  /// Converts special characters to HTML entities to prevent
  /// them from being interpreted as HTML tags.
  /// 
  /// Example:
  /// ```dart
  /// final safe = ContentSanitizer.escapeHTML('<script>alert("XSS")</script>');
  /// // Returns: &lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;
  /// ```
  static String escapeHTML(String text) {
    return text
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&#x27;')
        .replaceAll('/', '&#x2F;');
  }

  /// Unescape HTML entities back to their original characters
  /// 
  /// Converts HTML entities back to special characters.
  /// Use with caution - only on trusted content.
  static String unescapeHTML(String text) {
    return text
        .replaceAll('&amp;', '&')
        .replaceAll('&lt;', '<')
        .replaceAll('&gt;', '>')
        .replaceAll('&quot;', '"')
        .replaceAll('&#x27;', "'")
        .replaceAll('&#x2F;', '/');
  }

  /// Validate and sanitize file path to prevent path traversal attacks
  /// 
  /// Returns null if path contains dangerous patterns like:
  /// - Parent directory references (..)
  /// - Absolute paths
  /// - Special characters
  static String? sanitizeFilePath(String path) {
    if (path.isEmpty) return null;

    // Reject paths with parent directory references
    if (path.contains('..')) {
      return null;
    }

    // Reject absolute paths
    if (path.startsWith('/') || path.contains(':\\')) {
      return null;
    }

    // Reject paths with null bytes
    if (path.contains('\x00')) {
      return null;
    }

    // Reject paths with special characters that could be dangerous
    final dangerousChars = RegExp(r'[<>:"|?*]');
    if (dangerousChars.hasMatch(path)) {
      return null;
    }

    return path;
  }
}
