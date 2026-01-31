const QRCode = require('qrcode');

// Version aus Command-Line-Argument oder Fallback
const version = process.argv[2] || 'v1.7.13';
const url = `https://github.com/jerdnaandrej777/mapab-app/releases/tag/${version}`;
const filename = `qr-${version}.png`;

QRCode.toFile(filename, url, {
  width: 512,
  margin: 2,
  color: {
    dark: '#000000',
    light: '#FFFFFF'
  }
}, (err) => {
  if (err) {
    console.error('Fehler beim Generieren des QR-Codes:', err);
    process.exit(1);
  }
  console.log('QR-Code erfolgreich generiert:', filename);
});
