# Generate Placeholder Assets

## Quick Placeholder Generation

If you don't have design assets yet, here are quick ways to create placeholder images:

### Option 1: Use Online Tools (Recommended)

**For App Icon & Splash Logo:**

1. **Canva** (Free)
   - Go to https://www.canva.com
   - Create 1024x1024 design
   - Use gradient background (Blue #0066FF to Green #00D9A3)
   - Add white "L" letter (bold, centered)
   - Download as PNG

2. **Figma** (Free)
   - Create 1024x1024 frame
   - Add rectangle with gradient
   - Add text "L" (white, bold, 400pt)
   - Export as PNG

3. **Logo Maker Tools**
   - https://www.logomaker.com
   - https://www.freelogodesign.org
   - https://www.canva.com/create/logos/

### Option 2: Use ImageMagick (Command Line)

```bash
# Install ImageMagick
# macOS: brew install imagemagick
# Ubuntu: sudo apt-get install imagemagick

# Generate app icon (1024x1024)
convert -size 1024x1024 \
  gradient:'#0066FF-#00D9A3' \
  -gravity center \
  -pointsize 400 \
  -fill white \
  -font Arial-Bold \
  -annotate +0+0 'L' \
  frontend/assets/icons/app_icon.png

# Generate splash logo (512x512)
convert -size 512x512 \
  gradient:'#0066FF-#00D9A3' \
  -gravity center \
  -pointsize 200 \
  -fill white \
  -font Arial-Bold \
  -annotate +0+0 'L' \
  frontend/assets/images/splash_logo.png
```

### Option 3: Use Python (PIL/Pillow)

```python
# Install: pip install pillow

from PIL import Image, ImageDraw, ImageFont

# Create app icon
img = Image.new('RGB', (1024, 1024), color='#0066FF')
draw = ImageDraw.Draw(img)

# Add gradient (simplified)
for y in range(1024):
    r = int(0 + (0 - 0) * y / 1024)
    g = int(102 + (217 - 102) * y / 1024)
    b = int(255 + (163 - 255) * y / 1024)
    draw.line([(0, y), (1024, y)], fill=(r, g, b))

# Add text
try:
    font = ImageFont.truetype("Arial Bold.ttf", 400)
except:
    font = ImageFont.load_default()

text = "L"
bbox = draw.textbbox((0, 0), text, font=font)
text_width = bbox[2] - bbox[0]
text_height = bbox[3] - bbox[1]
position = ((1024 - text_width) // 2, (1024 - text_height) // 2)

draw.text(position, text, fill='white', font=font)
img.save('frontend/assets/icons/app_icon.png')

print("Icon generated!")
```

### Option 4: Use Existing Assets (Temporary)

For quick testing, you can use a solid color:

```bash
# Create solid blue icon
convert -size 1024x1024 xc:'#0066FF' \
  frontend/assets/icons/app_icon.png

# Create solid blue splash
convert -size 512x512 xc:'#0066FF' \
  frontend/assets/images/splash_logo.png
```

## Asset Specifications

### App Icon
- **Size**: 1024x1024 pixels
- **Format**: PNG (no transparency for iOS)
- **Content**: Logo or letter "L"
- **Background**: Gradient or solid color
- **Safe Area**: Keep important content in center 80%

### Splash Logo
- **Size**: 512x512 pixels (will be scaled)
- **Format**: PNG with transparency
- **Content**: Logo or letter "L"
- **Background**: Transparent
- **Style**: Should work on black background

### Splash Branding (Optional)
- **Size**: 1200x300 pixels
- **Format**: PNG with transparency
- **Content**: "Architects of the Next Era" text
- **Background**: Transparent
- **Color**: White or gray text

## After Creating Assets

1. **Place files in correct locations**:
   ```
   frontend/
   ├── assets/
   │   ├── icons/
   │   │   └── app_icon.png (1024x1024)
   │   └── images/
   │       ├── splash_logo.png (512x512)
   │       └── splash_branding.png (1200x300, optional)
   ```

2. **Generate native splash screens**:
   ```bash
   cd frontend
   flutter pub run flutter_native_splash:create
   ```

3. **Generate app icons**:
   ```bash
   flutter pub run flutter_launcher_icons
   ```

4. **Test**:
   ```bash
   flutter run --release
   ```

## Professional Assets (Later)

When you're ready for production:

1. **Hire a designer** on:
   - Fiverr ($20-100)
   - Upwork ($50-500)
   - 99designs ($299-1299)

2. **Use AI tools**:
   - Midjourney
   - DALL-E
   - Stable Diffusion

3. **Design yourself** in:
   - Figma (free)
   - Adobe Illustrator
   - Affinity Designer

## Quick Test Without Assets

The app will work without custom assets! It uses:
- Built-in animated splash with gradient "L"
- Default Flutter app icon (temporarily)

You can add professional assets later without changing any code.

---

**Recommendation**: Start with Option 1 (Canva) - takes 5 minutes and looks professional enough for testing.
