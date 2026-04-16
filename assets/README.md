# Knowvas Assets Directory

This directory contains all static assets for the Knowvas Flutter application, including images, icons, and other branding materials.

## Directory Structure

```
assets/
├── images/          # App logos, splash screens, and images
│   ├── logo_light.png
│   ├── logo_dark.png
│   ├── logo_icon.png
│   └── splash_logo.png
└── icons/           # Custom icons and icon assets
    └── (custom icons)
```

## Required Assets

### Logo Files

Add the following logo files to `assets/images/`:

1. **logo_light.png** (Recommended: 512x512px)
   - Logo for light backgrounds
   - Used in light theme app bar and branding
   - Should have good contrast on white/light backgrounds

2. **logo_dark.png** (Recommended: 512x512px)
   - Logo for dark backgrounds
   - Used in dark theme app bar and branding
   - Should have good contrast on dark backgrounds

3. **logo_icon.png** (Recommended: 1024x1024px)
   - Square app icon/logo mark
   - Used for app icon, favicon, and small displays
   - Should work well at small sizes

4. **splash_logo.png** (Recommended: 512x512px)
   - Logo for splash screen
   - Displayed during app initialization
   - Should be recognizable and load quickly

### Asset Guidelines

#### Image Specifications
- **Format**: PNG with transparency (preferred) or JPG
- **Resolution**: Provide @2x and @3x versions for different screen densities
- **Color Space**: sRGB
- **Optimization**: Compress images to reduce app size

#### Naming Convention
- Use lowercase with underscores: `logo_light.png`
- Include density suffix for multiple resolutions: `logo_light@2x.png`, `logo_light@3x.png`
- Be descriptive: `icon_bookmark_filled.png`

#### File Size
- Keep individual images under 500KB
- Optimize using tools like:
  - [TinyPNG](https://tinypng.com/)
  - [ImageOptim](https://imageoptim.com/)
  - [Squoosh](https://squoosh.app/)

## Adding New Assets

### 1. Add Asset Files

Place your asset files in the appropriate directory:
- Images → `assets/images/`
- Icons → `assets/icons/`

### 2. Update pubspec.yaml

Assets are already configured in `pubspec.yaml`:

```yaml
flutter:
  assets:
    - assets/images/
    - assets/icons/
```

### 3. Reference in Code

Update `lib/core/constants/app_branding.dart` with new asset paths:

```dart
static const String myNewAsset = 'assets/images/my_new_asset.png';
```

### 4. Use in Widgets

```dart
Image.asset(
  AppBranding.myNewAsset,
  width: 100,
  height: 100,
)
```

## Platform-Specific Icons

### Android App Icon

Add app icons to `android/app/src/main/res/`:
- `mipmap-mdpi/ic_launcher.png` (48x48px)
- `mipmap-hdpi/ic_launcher.png` (72x72px)
- `mipmap-xhdpi/ic_launcher.png` (96x96px)
- `mipmap-xxhdpi/ic_launcher.png` (144x144px)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192px)

Use [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/) to generate all sizes.

### iOS App Icon

Add app icons to `ios/Runner/Assets.xcassets/AppIcon.appiconset/`:
- Multiple sizes from 20x20 to 1024x1024
- Follow Apple's [App Icon Guidelines](https://developer.apple.com/design/human-interface-guidelines/app-icons)

Use Xcode or [App Icon Generator](https://appicon.co/) to generate all required sizes.

## Splash Screen Configuration

### Android

Configure splash screen in `android/app/src/main/res/drawable/launch_background.xml`:

```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@color/splash_background"/>
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash_logo"/>
    </item>
</layer-list>
```

### iOS

Configure launch screen in `ios/Runner/Base.lproj/LaunchScreen.storyboard` using Xcode.

## Brand Colors

The Knowvas brand uses the following primary color:

- **Primary Purple**: #8576FF (RGB: 133, 118, 255)

Ensure all branding assets use this color consistently.

## Accessibility

When creating assets:
- Ensure sufficient contrast for visibility
- Provide alternative text descriptions
- Test with screen readers
- Support dark mode variants

## License and Attribution

All assets in this directory should:
- Be owned by Knowvas or properly licensed
- Include attribution if required
- Not violate any copyrights or trademarks

## Tools and Resources

### Design Tools
- [Figma](https://www.figma.com/) - UI/UX design
- [Adobe Illustrator](https://www.adobe.com/products/illustrator.html) - Vector graphics
- [Sketch](https://www.sketch.com/) - UI design

### Icon Resources
- [Material Icons](https://fonts.google.com/icons) - Google's icon library
- [Heroicons](https://heroicons.com/) - Beautiful hand-crafted SVG icons
- [Feather Icons](https://feathericons.com/) - Simply beautiful open source icons

### Image Optimization
- [TinyPNG](https://tinypng.com/) - PNG/JPG compression
- [Squoosh](https://squoosh.app/) - Image compression
- [ImageOptim](https://imageoptim.com/) - Mac image optimizer

### Icon Generation
- [App Icon Generator](https://appicon.co/) - Generate all icon sizes
- [Android Asset Studio](https://romannurik.github.io/AndroidAssetStudio/) - Android icons
- [Make App Icon](https://makeappicon.com/) - iOS and Android icons

## Questions?

For questions about assets or branding, contact:
- Design Team: design@knowvas.com
- Development Team: dev@knowvas.com
