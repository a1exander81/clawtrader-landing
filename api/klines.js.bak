// U-CHART-STAGE1-20260726: server-side proxy for Bybit v5 kline data.
// Browser calls to api.bybit.com are CORS-blocked; this route fetches
// server-side (Vercel Node runtime) and re-serves with CORS open.
//
// GET /api/klines?symbol=BTCUSDT&interval=15&limit=200
//   interval: Bybit kline interval string (1,3,5,15,30,60,120,240,360,720,D,W,M)
//   limit: number of candles, max 1000 (Bybit cap)
//
// Response: { symbol, interval, candles: [{ time, open, high, low, close }] }
// candles are ascending by time (unix seconds) — Lightweight Charts requires this.

module.exports = async (req, res) => {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Cache-Control', 's-maxage=15, stale-while-revalidate=30');

  const { symbol, interval = '15', limit = '200' } = req.query || {};

  if (!symbol || !/^[A-Z0-9]{3,20}$/.test(symbol)) {
    res.status(400).json({ error: 'invalid_symbol' });
    return;
  }
  if (!/^(1|3|5|15|30|60|120|240|360|720|D|W|M)$/.test(String(interval))) {
    res.status(400).json({ error: 'invalid_interval' });
    return;
  }
  const safeLimit = Math.min(Math.max(parseInt(limit, 10) || 200, 1), 1000);

  const url = `https://api.bybit.com/v5/market/kline?category=linear&symbol=${encodeURIComponent(symbol)}&interval=${encodeURIComponent(interval)}&limit=${safeLimit}`;

  try {
    const r = await fetch(url);
    const data = await r.json();

    if (data.retCode !== 0 || !data.result || !Array.isArray(data.result.list)) {
      res.status(502).json({ error: 'bybit_error', detail: data.retMsg || 'no data' });
      return;
    }

    // Bybit returns newest-first rows: [start_ms, open, high, low, close, volume, turnover]
    const candles = data.result.list
      .map((k) => ({
        time: Math.floor(Number(k[0]) / 1000),
        open: Number(k[1]),
        high: Number(k[2]),
        low: Number(k[3]),
        close: Number(k[4]),
      }))
      .sort((a, b) => a.time - b.time);

    res.status(200).json({ symbol, interval: String(interval), candles });
  } catch (e) {
    res.status(502).json({ error: 'fetch_failed', detail: String(e && e.message ? e.message : e) });
  }
};
