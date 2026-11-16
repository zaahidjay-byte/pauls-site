// sitemap.xml, built at build time. /privacy/ is listed only when the notice is live
// (PRIVACY_NOTICE_LIVE in src/config/site.ts).
import { PRIVACY_NOTICE_LIVE } from '../config/site';

const SITE = 'https://paulshomemade.co.za';
const PAGES = ['/', '/events/', '/flavours/', '/story/', '/book/', '/contact/'];

export function GET() {
  const pages = PRIVACY_NOTICE_LIVE ? [...PAGES, '/privacy/'] : PAGES;
  const body =
    '<?xml version="1.0" encoding="UTF-8"?>\n' +
    '<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">\n' +
    pages.map((p) => `  <url><loc>${SITE}${p}</loc></url>\n`).join('') +
    '</urlset>\n';
  return new Response(body, { headers: { 'Content-Type': 'application/xml' } });
}
