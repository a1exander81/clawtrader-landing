// api/og-chart.js
// U-CHART-OGIMG1-20260727: renders a shareable preview image for a single
// trade (symbol, direction, entry/SL/TP) via @vercel/og's ImageResponse.
// Consumed by api/chart.js as the og:image target so Telegram's
// link-preview scraper renders an actual thumbnail instead of the generic
// og-join.jpg fallback.
//
// Edge runtime only -- ImageResponse's PNG rendering path requires it.
// Uses the plain-object element form (no JSX/React import needed) since
// this repo has no build/transpile step configured beyond what Vercel's
// Edge Function bundler provides for import/export syntax itself.
import { ImageResponse } from '@vercel/og';

export const config = { runtime: 'edge' };

const GREEN = '#2BD576';
const RED = '#FF4757';
const ORANGE = '#FF5500';
const BG = '#0B0B0D';
const TEXT = '#F2F0EC';
const MUTED = 'rgba(242,240,236,0.55)';

function el(type, props, children) {
  return { type, props: { ...props, children } };
}

function level(label, value, color) {
  return el('div', { style: { display: 'flex', flexDirection: 'column' } }, [
    el('span', { style: { fontSize: 20, color: MUTED, letterSpacing: 2 } }, label),
    el('span', { style: { fontSize: 36, color, marginTop: 8 } }, value),
  ]);
}

export default async function handler(request) {
  const { searchParams } = new URL(request.url);
  const symbol = (searchParams.get('symbol') || '').slice(0, 20);
  const dir = (searchParams.get('dir') || '').toUpperCase();
  const entry = searchParams.get('entry');
  const sl = searchParams.get('sl');
  const tp = searchParams.get('tp');

  const dirColor = dir === 'LONG' ? GREEN : dir === 'SHORT' ? RED : MUTED;
  const hasLevels = Boolean(entry && sl && tp);

  const headerChildren = [el('span', {}, symbol || 'Setup')];
  if (dir === 'LONG' || dir === 'SHORT') {
    headerChildren.push(
      el(
        'span',
        {
          style: {
            marginLeft: 28,
            fontSize: 28,
            color: dirColor,
            border: '2px solid ' + dirColor,
            borderRadius: 999,
            padding: '8px 24px',
          },
        },
        dir,
      ),
    );
  }

  const bodyChildren = hasLevels
    ? [
        el('div', { style: { display: 'flex', marginTop: 56, gap: 32 } }, [
          level('ENTRY', entry, TEXT),
          level('TAKE PROFIT', tp, GREEN),
          level('STOP LOSS', sl, RED),
        ]),
      ]
    : [
        el(
          'div',
          { style: { display: 'flex', marginTop: 56, fontSize: 30, color: MUTED } },
          'Live annotated chart from the Clawmimoto engine',
        ),
      ];

  const root = el(
    'div',
    {
      style: {
        width: '1200px',
        height: '630px',
        display: 'flex',
        flexDirection: 'column',
        background: BG,
        color: TEXT,
        padding: '64px',
        fontFamily: 'sans-serif',
      },
    },
    [
      el('div', { style: { display: 'flex', alignItems: 'center', fontSize: 40, letterSpacing: 2 } }, [
        el('span', {}, 'CLAW'),
        el('span', { style: { color: ORANGE } }, 'TRADER'),
      ]),
      el('div', { style: { display: 'flex', alignItems: 'baseline', marginTop: 48 } }, headerChildren),
      ...bodyChildren,
      el(
        'div',
        { style: { display: 'flex', marginTop: 'auto', fontSize: 22, color: MUTED } },
        'MOCK ACCOUNT \u00b7 SIMULATED FILLS \u00b7 clawtrader-landing.vercel.app',
      ),
    ],
  );

  return new ImageResponse(root, { width: 1200, height: 630 });
}
