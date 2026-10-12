// Run with Node.js and sharp installed (or available through NODE_PATH).
const fs = require('node:fs');
const path = require('node:path');
const sharp = require('sharp');
const root = path.resolve(__dirname, '../../..');
const res = path.join(root, 'app/android/app/src/main/res');
const assets = path.join(root, 'app/ios/Runner/BakaGames.icon/Assets');
const layers = ['01-Indigo-Stem.svg', '02-Coral-Arc.svg', '03-Golden-Curve.svg'].map(name => {
  const svg = fs.readFileSync(path.join(assets, name), 'utf8');
  return { fill: svg.match(/fill="([^"]+)"/)[1], d: svg.match(/ d="([^"]+)"/)[1] };
});
// Center the source bounds (238,94)-(788,838) in Android's 108dp canvas.
// The complete mark fits inside the central 66dp safe circle.
const scale = 0.07;
const tx = 54 - 513 * scale;
const ty = 54 - 466 * scale;
const write = (name, data) => {
  const target = path.join(res, name);
  fs.mkdirSync(path.dirname(target), { recursive: true });
  fs.writeFileSync(target, data);
};
function vector(mono) {
  return `<?xml version="1.0" encoding="utf-8"?>\n<!-- Generated from the iOS BakaGames vector layers. -->\n<vector xmlns:android="http://schemas.android.com/apk/res/android"\n    android:width="108dp" android:height="108dp"\n    android:viewportWidth="108" android:viewportHeight="108">\n    <group android:scaleX="${scale}" android:scaleY="${scale}"\n        android:translateX="${tx}" android:translateY="${ty}">\n${layers.map(l => `        <path android:fillColor="${mono ? '#000000' : l.fill}" android:pathData="${l.d}" />`).join('\n')}\n    </group>\n</vector>\n`;
}
function svg(mono = false, viewBox = '18 18 72 72') {
  return `<svg xmlns="http://www.w3.org/2000/svg" width="512" height="512" viewBox="${viewBox}"><rect width="108" height="108" fill="${mono ? '#E5DEFF' : '#FFF7E6'}"/><g transform="translate(${tx} ${ty}) scale(${scale})">${layers.map(l => `<path fill="${mono ? '#35285A' : l.fill}" d="${l.d}"/>`).join('')}</g></svg>`;
}
async function main() {
  write('drawable/ic_launcher_foreground.xml', vector(false));
  write('drawable/ic_launcher_monochrome.xml', vector(true));
  write('values/ic_launcher_colors.xml', '<?xml version="1.0" encoding="utf-8"?>\n<resources>\n    <color name="ic_launcher_background">#FFF7E6</color>\n</resources>\n');
  for (const version of [26, 33]) {
    write(`mipmap-anydpi-v${version}/ic_launcher.xml`, `<?xml version="1.0" encoding="utf-8"?>\n<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">\n    <background android:drawable="@color/ic_launcher_background" />\n    <foreground android:drawable="@drawable/ic_launcher_foreground" />\n${version === 33 ? '    <monochrome android:drawable="@drawable/ic_launcher_monochrome" />\n' : ''}</adaptive-icon>\n`);
  }
  for (const [density, size] of Object.entries({mdpi:48, hdpi:72, xhdpi:96, xxhdpi:144, xxxhdpi:192})) {
    await sharp(Buffer.from(svg())).resize(size, size).png().toFile(path.join(res, `mipmap-${density}/ic_launcher.png`));
  }
  fs.writeFileSync(path.join(__dirname, 'preview.svg'), svg());
  // Preview launcher masks; the actual adaptive icon leaves masking to Android.
  const previews = [];
  for (const [index, shape] of ['circle', 'rounded', 'themed'].entries()) {
    const mask = shape === 'rounded' ? '<rect width="240" height="240" rx="52" fill="white"/>' : '<circle cx="120" cy="120" r="120" fill="white"/>';
    const png = await sharp(Buffer.from(svg(shape === 'themed'))).resize(240,240).composite([{input:Buffer.from(`<svg width="240" height="240">${mask}</svg>`), blend:'dest-in'}]).png().toBuffer();
    previews.push({input:png, left:20 + index * 260, top:20});
  }
  await sharp({create:{width:800,height:280,channels:4,background:'#E8E9EE'}}).composite(previews).png().toFile(path.join(__dirname, 'preview.png'));
}
main().catch(error => { console.error(error); process.exitCode = 1; });
