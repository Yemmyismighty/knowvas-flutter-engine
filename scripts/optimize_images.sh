#!/bin/bash

# Image Optimization Script for Knowvas Flutter Client
# This script optimizes all images in the assets directory

set -e

echo "🖼️  Starting image optimization..."

# Check if required tools are installed
command -v pngquant >/dev/null 2>&1 || { echo "❌ pngquant is not installed. Install with: brew install pngquant"; exit 1; }
command -v jpegoptim >/dev/null 2>&1 || { echo "❌ jpegoptim is not installed. Install with: brew install jpegoptim"; exit 1; }

# Directories to optimize
ASSETS_DIR="assets/images"
ICONS_DIR="assets/icons"

# Create backup directory
BACKUP_DIR="assets_backup_$(date +%Y%m%d_%H%M%S)"
echo "📦 Creating backup in $BACKUP_DIR..."
mkdir -p "$BACKUP_DIR"
cp -r "$ASSETS_DIR" "$BACKUP_DIR/" 2>/dev/null || true
cp -r "$ICONS_DIR" "$BACKUP_DIR/" 2>/dev/null || true

# Optimize PNG images
echo "🔧 Optimizing PNG images..."
find "$ASSETS_DIR" -name "*.png" -type f -exec pngquant --quality=65-80 --ext .png --force {} \; 2>/dev/null || true
find "$ICONS_DIR" -name "*.png" -type f -exec pngquant --quality=65-80 --ext .png --force {} \; 2>/dev/null || true

# Optimize JPEG images
echo "🔧 Optimizing JPEG images..."
find "$ASSETS_DIR" -name "*.jpg" -type f -exec jpegoptim --max=85 --strip-all {} \; 2>/dev/null || true
find "$ASSETS_DIR" -name "*.jpeg" -type f -exec jpegoptim --max=85 --strip-all {} \; 2>/dev/null || true

# Calculate size reduction
ORIGINAL_SIZE=$(du -sh "$BACKUP_DIR" | cut -f1)
OPTIMIZED_SIZE=$(du -sh assets | cut -f1)

echo "✅ Image optimization complete!"
echo "📊 Original size: $ORIGINAL_SIZE"
echo "📊 Optimized size: $OPTIMIZED_SIZE"
echo "💾 Backup saved in: $BACKUP_DIR"
echo ""
echo "To convert images to WebP format (recommended), run:"
echo "  find assets -name '*.png' -exec cwebp -q 80 {} -o {}.webp \;"
