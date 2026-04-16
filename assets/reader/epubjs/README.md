# EPUB.js Asset

## Download Instructions

1. Go to: https://github.com/futurepress/epub.js/releases
2. Download the latest release (v0.3.93 or newer)
3. Extract `epub.min.js` from the release
4. Place it in this directory: `assets/reader/epubjs/epub.min.js`

## File Structure

```
assets/reader/epubjs/
├── README.md (this file)
└── epub.min.js (download from GitHub)
```

## Alternative: CDN (for testing only)

For testing purposes, you can temporarily use the CDN version by updating reader.html:

```html
<script src="https://cdn.jsdelivr.net/npm/epubjs/dist/epub.min.js"></script>
```

But for production and offline reading, you MUST download and bundle the local file.

## File Size

- epub.min.js: ~200KB

## Verification

After downloading, verify the file exists:

```bash
ls -la assets/reader/epubjs/epub.min.js
```

Or on Windows:

```cmd
dir assets\reader\epubjs\epub.min.js
```

