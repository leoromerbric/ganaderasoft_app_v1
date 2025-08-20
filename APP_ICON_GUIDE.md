# App Icon Replacement Guide

This document provides instructions for replacing the app icons across all platforms with the custom GanaderaSoft logo.

## Source Logo
- **File**: `lib/media/ganadera_logo_v1.png`
- **Size**: 119,935 bytes (~117 KB)
- **Format**: PNG

## Required Icon Sizes

### Android (android/app/src/main/res/)
Replace the following files with resized versions of the logo:
- `mipmap-mdpi/ic_launcher.png` (48x48)
- `mipmap-hdpi/ic_launcher.png` (72x72)
- `mipmap-xhdpi/ic_launcher.png` (96x96)
- `mipmap-xxhdpi/ic_launcher.png` (144x144)
- `mipmap-xxxhdpi/ic_launcher.png` (192x192)

### iOS (ios/Runner/Assets.xcassets/AppIcon.appiconset/)
Replace the following files:
- `Icon-App-20x20@1x.png` (20x20)
- `Icon-App-20x20@2x.png` (40x40)
- `Icon-App-20x20@3x.png` (60x60)
- `Icon-App-29x29@1x.png` (29x29)
- `Icon-App-29x29@2x.png` (58x58)
- `Icon-App-29x29@3x.png` (87x87)
- `Icon-App-40x40@1x.png` (40x40)
- `Icon-App-40x40@2x.png` (80x80)
- `Icon-App-40x40@3x.png` (120x120)
- `Icon-App-60x60@2x.png` (120x120)
- `Icon-App-60x60@3x.png` (180x180)
- `Icon-App-76x76@1x.png` (76x76)
- `Icon-App-76x76@2x.png` (152x152)
- `Icon-App-83.5x83.5@2x.png` (167x167)
- `Icon-App-1024x1024@1x.png` (1024x1024)

### macOS (macos/Runner/Assets.xcassets/AppIcon.appiconset/)
Replace the following files:
- `app_icon_16.png` (16x16)
- `app_icon_32.png` (32x32)
- `app_icon_64.png` (64x64)
- `app_icon_128.png` (128x128)
- `app_icon_256.png` (256x256)
- `app_icon_512.png` (512x512)
- `app_icon_1024.png` (1024x1024)

### Web (web/icons/)
Replace the following files:
- `Icon-192.png` (192x192)
- `Icon-512.png` (512x512)
- `Icon-maskable-192.png` (192x192)
- `Icon-maskable-512.png` (512x512)
- `../favicon.png` (32x32)

## Tools for Icon Generation

### Option 1: Online Tools
- [App Icon Generator](https://appicon.co/)
- [Icon Generator](https://icon.kitchen/)
- Upload your logo and download all required sizes

### Option 2: Command Line (ImageMagick)
```bash
# Install ImageMagick
sudo apt-get install imagemagick

# Generate all Android icons
convert lib/media/ganadera_logo_v1.png -resize 48x48 android/app/src/main/res/mipmap-mdpi/ic_launcher.png
convert lib/media/ganadera_logo_v1.png -resize 72x72 android/app/src/main/res/mipmap-hdpi/ic_launcher.png
convert lib/media/ganadera_logo_v1.png -resize 96x96 android/app/src/main/res/mipmap-xhdpi/ic_launcher.png
convert lib/media/ganadera_logo_v1.png -resize 144x144 android/app/src/main/res/mipmap-xxhdpi/ic_launcher.png
convert lib/media/ganadera_logo_v1.png -resize 192x192 android/app/src/main/res/mipmap-xxxhdpi/ic_launcher.png

# Generate web icons
convert lib/media/ganadera_logo_v1.png -resize 192x192 web/icons/Icon-192.png
convert lib/media/ganadera_logo_v1.png -resize 512x512 web/icons/Icon-512.png
convert lib/media/ganadera_logo_v1.png -resize 192x192 web/icons/Icon-maskable-192.png
convert lib/media/ganadera_logo_v1.png -resize 512x512 web/icons/Icon-maskable-512.png
convert lib/media/ganadera_logo_v1.png -resize 32x32 web/favicon.png

# Generate iOS icons (partial list - complete as needed)
convert lib/media/ganadera_logo_v1.png -resize 60x60 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-20x20@3x.png
convert lib/media/ganadera_logo_v1.png -resize 180x180 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-60x60@3x.png
convert lib/media/ganadera_logo_v1.png -resize 1024x1024 ios/Runner/Assets.xcassets/AppIcon.appiconset/Icon-App-1024x1024@1x.png
```

## Notes
- Ensure the logo has appropriate padding and contrast for small sizes
- Test the icons on actual devices to ensure they look good
- Consider creating adaptive icons for Android (requires separate background and foreground layers)
- The logo should work well on both light and dark backgrounds