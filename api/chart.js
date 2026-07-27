// api/chart.js
// U-CHART-OGIMG1-20260727: serves /chart/:symbol (rewritten here by
// vercel.json) as a thin server-side wrapper around the existing static
// chart.html. Injects a per-trade og:title / og:description / og:image
// before sending the HTML down, so Telegram's link-preview scraper (which
// reads meta tags from the raw HTML response -- no JS execution) renders
// an actual thumbnail instead of the generic og-join.jpg fallback.
//
// The chart page itself (UI, candles, price lines, client-side script) is
// unchanged -- this only rewrites the three <meta property="og:..."> tags.
// chart.html stays the single source of truth; read from disk each cold
// start and cached in module scope for warm invocations.
const fs = require('fs');
const path = require('path');

let TEMPLATE = null;
function loadTemplate() {
  if (TEMPLATE === null) {
    TEMPLATE = fs.readFileSync(path.join(__dirname, '..', 'chart.html'), 'utf8');
  }
  return TEMPLATE;
}

function escapeHtml(s) {
  return String(s)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

module.exports = async (req, res) => {
  res.setHeader('Content-Type', 'text/html; charset=utf-8');
  res.setHeader('Cache-Control', 's-maxage=15, stale-while-revalidate=30');

  const { symbol = '', entry, sl, tp, dir } = req.query || {};
  const safeSymbol = /^[A-Za-z0-9]{1,20}$/.test(String(symbol)) ? String(symbol) : '';

  let html = loadTemplate();

  if (safeSymbol) {
    const dirUpper = String(dir || '').toUpperCase();
    const dirLabel = dirUpper === 'LONG' || dirUpper === 'SHORT' ? dirUpper : '';
    const title = dirLabel
      ? `${safeSymbol} ${dirLabel} \u2014 Clawmimoto`
      : `${safeSymbol} \u2014 Clawmimoto`;
    const description = 'Live annotated chart \u2014 Entry, SL, TP straight from the Clawmimoto engine.';

    const ogParams = new URLSearchParams();
    ogParams.set('symbol', safeSymbol);
    if (dirLabel) ogParams.set('dir', dirLabel);
    if (entry) ogParams.set('entry', String(entry));
    if (sl) ogParams.set('sl', String(sl));
    if (tp) ogParams.set('tp', String(tp));
    const ogImageUrl = `https://clawtrader-landing.vercel.app/api/og-chart?${ogParams.toString()}`;

    html = html
      .replace(
        /<meta property="og:title" content="[^"]*">/,
        `<meta property="og:title" content="${escapeHtml(title)}">`,
      )
      .replace(
        /<meta property="og:description" content="[^"]*">/,
        `<meta property="og:description" content="${escapeHtml(description)}">`,
      )
      .replace(
        /<meta property="og:image" content="[^"]*">/,
        `<meta property="og:image" content="${escapeHtml(ogImageUrl)}">`,
      );
  }

  res.status(200).send(html);
};
