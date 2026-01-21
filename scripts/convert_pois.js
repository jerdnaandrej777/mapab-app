/**
 * Konvertiert curated-pois.js zu curated_pois.json für Flutter
 *
 * Mapping:
 * - name → name (bleibt gleich für Flutter)
 * - lon → longitude
 * - lat → latitude
 * - category → categoryId
 * - score → score
 */

const fs = require('fs');
const path = require('path');

// Pfade
const inputPath = path.join(__dirname, '../../Mapab/Mobi/js/data/curated-pois.js');
const outputPath = path.join(__dirname, '../assets/data/curated_pois.json');

// JS-Datei lesen
let content = fs.readFileSync(inputPath, 'utf8');

// Export-Statement und Kommentare entfernen
content = content
  .replace(/export const CURATED_POIS = \[/, '[')
  .replace(/\/\/.*$/gm, '') // Zeilen-Kommentare entfernen
  .replace(/\/\*[\s\S]*?\*\//g, '') // Block-Kommentare entfernen
  .replace(/\];?\s*$/, ']') // Schließende Klammer bereinigen
  .trim();

// JSON parsen
let pois;
try {
  pois = JSON.parse(content);
} catch (e) {
  console.error('Fehler beim Parsen:', e.message);
  // Versuche trailing commas zu entfernen
  content = content.replace(/,\s*([\]}])/g, '$1');
  pois = JSON.parse(content);
}

// Für Flutter umwandeln
const flutterPois = pois.map(poi => ({
  id: poi.id,
  name: poi.name,
  latitude: poi.lat,
  longitude: poi.lon,
  categoryId: poi.category,
  score: poi.score,
  tags: poi.tags || [],
  isCurated: true,
  country: poi.country
}));

// JSON schreiben
fs.writeFileSync(outputPath, JSON.stringify(flutterPois, null, 2), 'utf8');

console.log(`✓ ${flutterPois.length} POIs konvertiert`);
console.log(`✓ Geschrieben nach: ${outputPath}`);
