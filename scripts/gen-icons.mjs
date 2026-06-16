// Generate favicon set + OG image from the hi-res Logo.png at repo root.
// Run: node scripts/gen-icons.mjs
import sharp from 'sharp';
import pngToIco from 'png-to-ico';
import { writeFile } from 'node:fs/promises';

const SRC = new URL('../Logo.png', import.meta.url).pathname;
const OUT = new URL('../public/', import.meta.url).pathname;

const trimmed = await sharp(SRC, { limitInputPixels: false }).trim().toBuffer();

async function square(size, { background = { r: 0, g: 0, b: 0, alpha: 0 }, pad = 0.08 } = {}) {
  const inner = Math.round(size * (1 - pad * 2));
  return sharp(trimmed)
    .resize(inner, inner, { fit: 'contain', background })
    .extend({
      top: Math.ceil((size - inner) / 2),
      bottom: Math.floor((size - inner) / 2),
      left: Math.ceil((size - inner) / 2),
      right: Math.floor((size - inner) / 2),
      background,
    })
    .png()
    .toBuffer();
}

await writeFile(`${OUT}favicon-16x16.png`, await square(16, { pad: 0 }));
await writeFile(`${OUT}favicon-32x32.png`, await square(32, { pad: 0 }));
const white = { r: 255, g: 255, b: 255, alpha: 1 };
await writeFile(`${OUT}apple-touch-icon.png`, await square(180, { background: white, pad: 0.1 }));
await writeFile(`${OUT}favicon.ico`, await pngToIco([await square(16, { pad: 0 }), await square(32, { pad: 0 }), await square(48, { pad: 0 })]));

// OG image 1200x630, logo contained on white
const og = await sharp(trimmed)
  .resize(1000, 480, { fit: 'contain', background: white })
  .extend({ top: 75, bottom: 75, left: 100, right: 100, background: white })
  .flatten({ background: white })
  .jpeg({ quality: 88 })
  .toBuffer();
await writeFile(`${OUT}og-image.jpg`, og);

console.log('Generated: favicon.ico, favicon-16x16.png, favicon-32x32.png, apple-touch-icon.png, og-image.jpg');
