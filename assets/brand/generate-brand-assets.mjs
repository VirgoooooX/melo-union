import { mkdir, writeFile } from 'node:fs/promises';
import { dirname, join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createRequire } from 'node:module';

const outDir = dirname(fileURLToPath(import.meta.url));
const svgDir = join(outDir, 'svg');
const pngDir = join(outDir, 'png');

const brand = {
  dark: '#1C2736',
  teal: '#0AA69A',
  white: '#FFFFFF',
};

const markDefs = `
  <defs>
    <mask id="crescent-cut-left-main" maskUnits="userSpaceOnUse" x="120" y="40" width="120" height="210">
      <rect x="120" y="40" width="120" height="210" fill="#FFFFFF"/>
      <path fill="#000000" d="M153.8 229.4C143.2 216.5 144.6 197.2 156.2 184.1C167.1 171.9 184.1 167.8 199.6 174.8C181.6 180.1 170 192.3 170 207.2C170 219.5 178.2 228.8 190.4 233.2C176.4 235 163.7 233.6 153.8 229.4Z"/>
    </mask>
    <linearGradient id="main-left" x1="148" y1="51" x2="155" y2="229" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#09988D"/>
      <stop offset="0.48" stop-color="#078B83"/>
      <stop offset="1" stop-color="#009086"/>
    </linearGradient>
    <linearGradient id="main-right" x1="232" y1="51" x2="201" y2="239" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#09968C"/>
      <stop offset="0.52" stop-color="#078980"/>
      <stop offset="1" stop-color="#009187"/>
    </linearGradient>
    <linearGradient id="mid-left" x1="108" y1="84" x2="108" y2="196" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#67C0B9"/>
      <stop offset="1" stop-color="#45A9A1"/>
    </linearGradient>
    <linearGradient id="mid-right" x1="273" y1="84" x2="273" y2="196" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#69C2BA"/>
      <stop offset="1" stop-color="#49AAA3"/>
    </linearGradient>
    <linearGradient id="pale-left" x1="68" y1="111" x2="68" y2="169" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#B8E2DE"/>
      <stop offset="1" stop-color="#A1D4CF"/>
    </linearGradient>
    <linearGradient id="pale-right" x1="313" y1="111" x2="313" y2="169" gradientUnits="userSpaceOnUse">
      <stop offset="0" stop-color="#B8E2DE"/>
      <stop offset="1" stop-color="#A2D5D0"/>
    </linearGradient>
  </defs>`;

const gradientMark = `
  ${markDefs}
  <rect x="58" y="111" width="21" height="58.5" rx="10.5" fill="url(#pale-left)"/>
  <rect x="97" y="84" width="22" height="112" rx="11" fill="url(#mid-left)"/>
  <path d="M149.25 51C156.3 51 162 56.7 162 63.75V178.6C162 187.2 156.4 193.7 151.8 203.6C148.3 211.1 149.3 221.6 155.35 228.55C143 222.3 136.5 209.2 136.5 192.2V63.75C136.5 56.7 142.2 51 149.25 51Z" fill="url(#main-left)" mask="url(#crescent-cut-left-main)"/>
  <path d="M232.75 51C239.8 51 245.5 56.7 245.5 63.75V194.3C245.5 219.35 225.3 239 200.4 239C175.2 239 156.5 225.5 156.5 206.5C156.5 187.8 173.7 174 196.1 174C206.2 174 214.7 177.2 220 183.1V63.75C220 56.7 225.7 51 232.75 51Z" fill="url(#main-right)"/>
  <rect x="262.5" y="84" width="22" height="112" rx="11" fill="url(#mid-right)"/>
  <rect x="302" y="111" width="21" height="58.5" rx="10.5" fill="url(#pale-right)"/>`;

const solidMark = (fill) => `
  <defs>
    <mask id="crescent-solid-cut" maskUnits="userSpaceOnUse" x="120" y="40" width="120" height="210">
      <rect x="120" y="40" width="120" height="210" fill="#FFFFFF"/>
      <path fill="#000000" d="M153.8 229.4C143.2 216.5 144.6 197.2 156.2 184.1C167.1 171.9 184.1 167.8 199.6 174.8C181.6 180.1 170 192.3 170 207.2C170 219.5 178.2 228.8 190.4 233.2C176.4 235 163.7 233.6 153.8 229.4Z"/>
    </mask>
  </defs>
  <rect x="58" y="111" width="21" height="58.5" rx="10.5" fill="${fill}" opacity="0.44"/>
  <rect x="97" y="84" width="22" height="112" rx="11" fill="${fill}" opacity="0.70"/>
  <path d="M149.25 51C156.3 51 162 56.7 162 63.75V178.6C162 187.2 156.4 193.7 151.8 203.6C148.3 211.1 149.3 221.6 155.35 228.55C143 222.3 136.5 209.2 136.5 192.2V63.75C136.5 56.7 142.2 51 149.25 51Z" fill="${fill}" mask="url(#crescent-solid-cut)"/>
  <path d="M232.75 51C239.8 51 245.5 56.7 245.5 63.75V194.3C245.5 219.35 225.3 239 200.4 239C175.2 239 156.5 225.5 156.5 206.5C156.5 187.8 173.7 174 196.1 174C206.2 174 214.7 177.2 220 183.1V63.75C220 56.7 225.7 51 232.75 51Z" fill="${fill}"/>
  <rect x="262.5" y="84" width="22" height="112" rx="11" fill="${fill}" opacity="0.70"/>
  <rect x="302" y="111" width="21" height="58.5" rx="10.5" fill="${fill}" opacity="0.44"/>`;

const svg = (viewBox, title, body) => `<svg xmlns="http://www.w3.org/2000/svg" viewBox="${viewBox}" role="img" aria-labelledby="title">
  <title id="title">${title}</title>${body}
</svg>
`;

const textStyle = 'font-family="Inter, Segoe UI, Arial, sans-serif" font-weight="800" letter-spacing="-5"';

const files = {
  'mark-positive.svg': svg('45 -0.5 291 291', 'MeloUnion mark', gradientMark),
  'mark-reverse.svg': svg('45 -0.5 291 291', 'MeloUnion mark reverse', solidMark(brand.white)),
  'logo-horizontal-positive.svg': svg('72 24 1030 210', 'MeloUnion horizontal logo', `
  <g transform="translate(52 10)">${gradientMark}</g>
  <text x="390" y="162" ${textStyle} font-size="104">
    <tspan fill="${brand.dark}">Melo</tspan><tspan fill="${brand.teal}">Union</tspan>
  </text>`),
  'logo-horizontal-reverse.svg': svg('72 24 1030 210', 'MeloUnion horizontal logo reverse', `
  <g transform="translate(52 10)">${solidMark(brand.white)}</g>
  <text x="390" y="162" ${textStyle} font-size="104" fill="${brand.white}">MeloUnion</text>`),
  'logo-horizontal-mono-navy.svg': svg('72 24 1030 210', 'MeloUnion horizontal logo mono', `
  <g transform="translate(52 10)">${solidMark(brand.dark)}</g>
  <text x="390" y="162" ${textStyle} font-size="104" fill="${brand.dark}">MeloUnion</text>`),
  'logo-stacked-positive.svg': svg('45 18 390 640', 'MeloUnion stacked logo', `
  <g transform="translate(0 28)">${gradientMark}</g>
  <text x="240" y="438" text-anchor="middle" ${textStyle} font-size="82" fill="${brand.dark}">Melo</text>
  <text x="240" y="522" text-anchor="middle" ${textStyle} font-size="82" fill="${brand.teal}">Union</text>`),
  'logo-stacked-reverse.svg': svg('45 18 390 640', 'MeloUnion stacked logo reverse', `
  <g transform="translate(0 28)">${solidMark(brand.white)}</g>
  <text x="240" y="438" text-anchor="middle" ${textStyle} font-size="82" fill="${brand.white}">Melo</text>
  <text x="240" y="522" text-anchor="middle" ${textStyle} font-size="82" fill="${brand.white}">Union</text>`),
};

const pngSizes = {
  'mark-positive': { width: 984, height: 984 },
  'mark-reverse': { width: 984, height: 984 },
  'logo-horizontal-positive': { width: 3152, height: 800 },
  'logo-horizontal-reverse': { width: 3152, height: 800 },
  'logo-horizontal-mono-navy': { width: 3152, height: 800 },
  'logo-stacked-positive': { width: 984, height: 1616 },
  'logo-stacked-reverse': { width: 984, height: 1616 },
};

await mkdir(svgDir, { recursive: true });
await mkdir(pngDir, { recursive: true });

for (const [name, content] of Object.entries(files)) {
  await writeFile(join(svgDir, name), content, 'utf8');
}

const require = createRequire(import.meta.url);
const sharp = require(process.env.SHARP_MODULE_PATH ?? 'sharp');
for (const [baseName, size] of Object.entries(pngSizes)) {
  await sharp(join(svgDir, `${baseName}.svg`), { density: 384 })
    .resize(size.width, size.height, { fit: 'contain', background: { r: 0, g: 0, b: 0, alpha: 0 } })
    .png()
    .toFile(join(pngDir, `${baseName}.png`));
}

