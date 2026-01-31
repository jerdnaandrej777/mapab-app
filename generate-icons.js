const sharp = require('sharp');
const fs = require('fs');
const path = require('path');

// MapAB Icon SVG - Modernes Design mit App-Farben (ohne Text)
// Farben aus app_theme.dart:
// Primary: #2563EB, Primary Dark: #1D4ED8, Primary Light: #3B82F6
// Secondary: #10B981 (Grün), Accent: #F59E0B (Orange)
const createIconSVG = (size) => `
<svg width="${size}" height="${size}" viewBox="0 0 512 512" xmlns="http://www.w3.org/2000/svg">
  <defs>
    <!-- Haupt-Gradient: Primary Blue -->
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#3B82F6"/>
      <stop offset="50%" style="stop-color:#2563EB"/>
      <stop offset="100%" style="stop-color:#1D4ED8"/>
    </linearGradient>

    <!-- Akzent-Gradient für Pin-Inneres -->
    <linearGradient id="accent" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#10B981"/>
      <stop offset="100%" style="stop-color:#059669"/>
    </linearGradient>

    <!-- Schatten -->
    <filter id="shadow" x="-20%" y="-20%" width="140%" height="140%">
      <feDropShadow dx="0" dy="4" stdDeviation="8" flood-color="#000" flood-opacity="0.25"/>
    </filter>
  </defs>

  <!-- Hintergrund mit abgerundeten Ecken -->
  <rect width="512" height="512" rx="115" fill="url(#bg)"/>

  <!-- Subtile Wellenform im Hintergrund -->
  <path d="M0 370 Q128 340 256 370 Q384 400 512 370 L512 512 L0 512 Z"
        fill="rgba(255,255,255,0.08)"/>
  <path d="M0 400 Q128 370 256 400 Q384 430 512 400 L512 512 L0 512 Z"
        fill="rgba(255,255,255,0.05)"/>

  <!-- Location Pin - zentriert und vergrößert (ohne Text) -->
  <g filter="url(#shadow)">
    <!-- Pin Körper -->
    <path d="M256 69
             C183 69 123 130 123 202
             C123 245 145 289 178 333
             C211 377 256 421 256 421
             C256 421 301 377 334 333
             C367 289 389 245 389 202
             C389 130 329 69 256 69 Z"
          fill="white"/>

    <!-- Innerer Kreis mit Grün-Akzent -->
    <circle cx="256" cy="196" r="55" fill="url(#accent)"/>

    <!-- Kleiner weißer Punkt im Zentrum -->
    <circle cx="256" cy="196" r="17" fill="white" opacity="0.9"/>
  </g>
</svg>
`;

// Android Icon Größen
const androidSizes = {
  'mipmap-mdpi': 48,
  'mipmap-hdpi': 72,
  'mipmap-xhdpi': 96,
  'mipmap-xxhdpi': 144,
  'mipmap-xxxhdpi': 192,
};

// iOS Icon Größen
const iosSizes = {
  'Icon-App-20x20@1x': 20,
  'Icon-App-20x20@2x': 40,
  'Icon-App-20x20@3x': 60,
  'Icon-App-29x29@1x': 29,
  'Icon-App-29x29@2x': 58,
  'Icon-App-29x29@3x': 87,
  'Icon-App-40x40@1x': 40,
  'Icon-App-40x40@2x': 80,
  'Icon-App-40x40@3x': 120,
  'Icon-App-60x60@2x': 120,
  'Icon-App-60x60@3x': 180,
  'Icon-App-76x76@1x': 76,
  'Icon-App-76x76@2x': 152,
  'Icon-App-83.5x83.5@2x': 167,
  'Icon-App-1024x1024@1x': 1024,
};

async function generateIcons() {
  console.log('🎨 Generiere MapAB Icons...\n');

  // Haupt-Icon für Projekt-Root (1024x1024)
  const mainIconSvg = Buffer.from(createIconSVG(1024));
  await sharp(mainIconSvg)
    .resize(1024, 1024)
    .png()
    .toFile('assets/icon/mapab-icon.png');
  console.log('✅ assets/icon/mapab-icon.png (1024x1024)');

  // Android Icons
  console.log('\n📱 Android Icons:');
  for (const [folder, size] of Object.entries(androidSizes)) {
    const outputPath = `android/app/src/main/res/${folder}/ic_launcher.png`;
    const svg = Buffer.from(createIconSVG(size));

    await sharp(svg)
      .resize(size, size)
      .png()
      .toFile(outputPath);

    console.log(`✅ ${outputPath} (${size}x${size})`);
  }

  // Foreground Icons für Adaptive Icons (Android 8+)
  console.log('\n🔲 Android Adaptive Icons:');
  for (const [folder, size] of Object.entries(androidSizes)) {
    const foregroundPath = `android/app/src/main/res/${folder}/ic_launcher_foreground.png`;
    // Adaptive icons brauchen mehr Platz (108dp viewBox, 72dp safe zone)
    const adaptiveSize = Math.round(size * 1.5);
    const svg = Buffer.from(createIconSVG(adaptiveSize));

    await sharp(svg)
      .resize(adaptiveSize, adaptiveSize)
      .extend({
        top: Math.round((adaptiveSize * 0.25) / 2),
        bottom: Math.round((adaptiveSize * 0.25) / 2),
        left: Math.round((adaptiveSize * 0.25) / 2),
        right: Math.round((adaptiveSize * 0.25) / 2),
        background: { r: 0, g: 0, b: 0, alpha: 0 }
      })
      .resize(adaptiveSize, adaptiveSize)
      .png()
      .toFile(foregroundPath);

    console.log(`✅ ${foregroundPath}`);
  }

  // iOS Icons (optional)
  const iosPath = 'ios/Runner/Assets.xcassets/AppIcon.appiconset';
  if (fs.existsSync('ios/Runner')) {
    console.log('\n🍎 iOS Icons:');
    if (!fs.existsSync(iosPath)) {
      fs.mkdirSync(iosPath, { recursive: true });
    }

    for (const [name, size] of Object.entries(iosSizes)) {
      const outputPath = `${iosPath}/${name}.png`;
      const svg = Buffer.from(createIconSVG(size));

      await sharp(svg)
        .resize(size, size)
        .png()
        .toFile(outputPath);

      console.log(`✅ ${outputPath} (${size}x${size})`);
    }
  }

  // Web Favicon
  console.log('\n🌐 Web Icons:');
  const webPath = 'web';
  if (fs.existsSync(webPath)) {
    const sizes = [16, 32, 192, 512];
    for (const size of sizes) {
      const svg = Buffer.from(createIconSVG(size));
      await sharp(svg)
        .resize(size, size)
        .png()
        .toFile(`${webPath}/icons/Icon-${size}.png`);
      console.log(`✅ ${webPath}/icons/Icon-${size}.png`);
    }

    // Favicon
    const svg = Buffer.from(createIconSVG(32));
    await sharp(svg)
      .resize(32, 32)
      .png()
      .toFile(`${webPath}/favicon.png`);
    console.log(`✅ ${webPath}/favicon.png`);
  }

  console.log('\n🎉 Alle Icons wurden erfolgreich generiert!');
}

// Assets-Ordner erstellen falls nicht vorhanden
if (!fs.existsSync('assets/icon')) {
  fs.mkdirSync('assets/icon', { recursive: true });
}

generateIcons().catch(console.error);
