module.exports = async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const requestUrl = new URL(req.url, 'http://localhost');
  const query = String(requestUrl.searchParams.get('q') || '').trim();
  const limit = Math.min(50, Math.max(1, Number(requestUrl.searchParams.get('limit')) || 30));

  if (!query || query.length > 150) {
    return res.status(400).json({ error: 'Invalid search query' });
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);

  try {
    const upstream = new URL(
      'https://saavn.bycomsolutions.com/api/search/songs'
    );
    upstream.searchParams.set('query', query);
    upstream.searchParams.set('limit', String(limit));

    const response = await fetch(upstream, {
      signal: controller.signal,
      headers: { Accept: 'application/json' }
    });

    if (!response.ok) {
      return res.status(502).json({ error: 'Music provider unavailable' });
    }

    const data = await response.json();

    if (!data || !data.success || !Array.isArray(data.data?.results)) {
      return res.status(502).json({ error: 'Invalid music provider response' });
    }

    res.setHeader('Cache-Control', 'public, s-maxage=60, stale-while-revalidate=120');
    return res.status(200).json(data);
  } catch (_) {
    return res.status(502).json({ error: 'Music search temporarily unavailable' });
  } finally {
    clearTimeout(timeout);
  }
};
