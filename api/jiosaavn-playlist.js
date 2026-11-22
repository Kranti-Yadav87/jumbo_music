module.exports = async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const id = String(req.query.id || '').trim();

  if (!/^\d{1,20}$/.test(id)) {
    return res.status(400).json({ error: 'Invalid playlist ID' });
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);

  try {
    const upstream = new URL(
      'https://saavn.bycomsolutions.com/api/playlists'
    );
    upstream.searchParams.set('id', id);

    const response = await fetch(upstream, {
      signal: controller.signal,
      headers: { Accept: 'application/json' }
    });

    if (!response.ok) {
      return res.status(502).json({ error: 'Playlist provider unavailable' });
    }

    const data = await response.json();

    if (!data || !data.success || !Array.isArray(data.data?.songs)) {
      return res.status(502).json({ error: 'Invalid playlist response' });
    }

    res.setHeader('Cache-Control', 'public, s-maxage=120, stale-while-revalidate=300');
    return res.status(200).json(data);
  } catch (_) {
    return res.status(502).json({ error: 'Playlist temporarily unavailable' });
  } finally {
    clearTimeout(timeout);
  }
};
