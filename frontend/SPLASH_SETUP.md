# Splash Screen Setup Guide

## Overview

The app has two splash screen implementations:

1. **Native Splash Screen** - Shows immediately when app launches (before Flutter loads)
2. **Flutter Splash Screen** - Shows during app initialization (Firebase, etc.)

## Native Splash Screen

### 1. Create Splash Assets

You need to create these image files:

**Logo Image** (`assets/images/splash_logo.png`)
- Size: 512x512 pixels
- Format: PNG with transparency
- Content: Your app logo/icon
- Background: Transparent

**Branding Image** (Optional: `assets/images/splash_branding.png`)
- Size: 1200x300 pixels
- Format: PNG with transparency
- Content: Company name or tagline
- Background: Transparent

### 2. Quick Logo Creation (Using Text)

If you don't have a logo yet, you can use the built-in Flutter splash screen which shows:
- Black background (#000000)
- Animated "L" letter with gradient
- "Loft" text
- "Architects of the Next Era" tagline

### 3. Generate Native Splash Screens

```bash
cd frontend

# Install the package (already in pubspec.yaml)
flutter pub get

# Generate splash screens for all platforms
flutter pub run flutter_native_splash:create

# Or generate for specific platform
flutter pub run flutter_native_splash:create --path=flutter_native_splash.yaml
```

This will automatically:
- Generate Android splash screens (all densities)
- Generate iOS launch screens
- Generate web splash screen
- Update native configuration files

### 4. Verify Installation

**Android**: Check `android/app/src/main/res/drawable*/`
- Should see `splash.png` in multiple folders

**iOS**: Check `ios/Runner/Assets.xcassets/LaunchImage.imageset/`
- Should see launch images

**Web**: Check `web/splash/`
- Should see splash assets

## Flutter Splash Screen

The Flutter splash screen (`lib/core/widgets/splash_screen.dart`) shows while:
- Loading environment variables
- Initializing Firebase
- Checking authentication state
- Loading initial data

### Customization

Edit `lib/core/widgets/splash_screen.dart` to customize:

```dart
// Change colors
backgroundColor: const Color(0xFF000000), // Background
Color(0xFF0066FF), // Primary blue
Color(0xFF00D9A3), // Accent green

// Change logo size
width: 120.w,
height: 120.w,

// Change animation duration
duration: const Duration(milliseconds: 1500),

// Change minimum display time
await Future.delayed(const Duration(seconds: 2));
```

## Design Specifications

### Color Palette
- Background: `#000000` (Black)
- Primary: `#0066FF` (Blue)
- Accent: `#00D9A3` (Green)
- Text: `#FFFFFF` (White)
- Secondary Text: `#999999` (Gray)

### Typography
- App Name: 32sp, Bold, White
- Tagline: 14sp, Regular, Gray
- Letter Spacing: 2 (App Name), 0.5 (Tagline)

### Animation
- Fade In: 0-600ms
- Scale: 0.8 → 1.0 with ease-out-back curve
- Loading Indicator: Circular, Blue, 3px stroke

## Testing

### Test Native Splash
```bash
# Android
flutter run --release

# iOS
flutter run --release

# The native splash should show immediately
```

### Test Flutter Splash
```bash
# Run in debug mode
flutter run

# You'll see:
# 1. Native splash (brief)
# 2. Flutter splash (2 seconds minimum)
# 3. Main app
```

## Troubleshooting

### Native splash not showing

**Android**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter pub run flutter_native_splash:create
flutter run
```

**iOS**:
```bash
cd ios
pod deinstall
pod install
cd ..
flutter clean
flutter pub get
flutter pub run flutter_native_splash:create
flutter run
```

### Flutter splash shows error

Check `main.dart`:
- Ensure `.env` file exists
- Verify Firebase configuration
- Check console for error messages

### Splash shows too long/short

Edit `lib/main.dart`:
```dart
// Change minimum duration
await Future.delayed(const Duration(seconds: 2)); // Adjust this
```

## Production Checklist

- [ ] Created splash logo (512x512)
- [ ] Created branding image (optional)
- [ ] Ran `flutter pub run flutter_native_splash:create`
- [ ] Tested on Android device
- [ ] Tested on iOS device
- [ ] Verified splash matches brand colors
- [ ] Checked splash duration (not too long)
- [ ] Tested error state (disable internet)
- [ ] Verified smooth transition to main app

## Advanced: Custom Native Splash (Android)

If you need more control, edit directly:

**Android**: `android/app/src/main/res/drawable/launch_background.xml`
```xml
<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item android:drawable="@android:color/black" />
    <item>
        <bitmap
            android:gravity="center"
            android:src="@drawable/splash" />
    </item>
</layer-list>
```

**iOS**: `ios/Runner/Base.lproj/LaunchScreen.storyboard`
- Open in Xcode
- Customize using Interface Builder

## Resources

- [flutter_native_splash package](https://pub.dev/packages/flutter_native_splash)
- [Android Splash Screens](https://developer.android.com/develop/ui/views/launch/splash-screen)
- [iOS Launch Screens](https://developer.apple.com/design/human-interface-guidelines/launch-screen)

---

**Quick Start**: If you just want to test, the app will work with the built-in animated splash screen. Add custom images later when you have your brand assets ready.
