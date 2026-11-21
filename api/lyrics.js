module.exports = async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const provider = String(req.query.provider || '');
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 8000);

  try {
    let upstream;

    if (provider === 'lrclib') {
      const endpoint = String(req.query.endpoint || '');
      if (!['get', 'search'].includes(endpoint)) {
        return res.status(400).json({ error: 'Invalid lyrics endpoint' });
      }

      const allowed = endpoint === 'get'
        ? ['track_name', 'artist_name', 'duration']
        : ['q'];

      upstream = new URL(`https://lrclib.net/api/${endpoint}`);

      for (const key of allowed) {
        const value = req.query[key];
        if (typeof value === 'string' && value.length > 0) {
          if (value.length > 200) {
            return res.status(400).json({ error: 'Invalid lyrics query' });
          }
          upstream.searchParams.set(key, value);
        }
      }

      if (endpoint === 'get' && !upstream.searchParams.has('track_name')) {
        return res.status(400).json({ error: 'Track name is required' });
      }
      if (endpoint === 'search' && !upstream.searchParams.has('q')) {
        return res.status(400).json({ error: 'Search query is required' });
      }
    } else if (provider === 'jiosaavn') {
      const call = String(req.query.call || '');
      if (!['lyrics.getLyrics', 'search.getResults'].includes(call)) {
        return res.status(400).json({ error: 'Invalid music provider action' });
      }

      upstream = new URL('https://www.jiosaavn.com/api.php');
      upstream.searchParams.set('__call', call);
      upstream.searchParams.set('ctx', 'web6dot0');
      upstream.searchParams.set('api_version', '4');
      upstream.searchParams.set('_format', 'json');
      upstream.searchParams.set('_marker', '0');

      if (call === 'lyrics.getLyrics') {
        const id = String(req.query.lyrics_id || '');
        if (!id || id.length > 100) {
          return res.status(400).json({ error: 'Invalid lyrics ID' });
        }
        upstream.searchParams.set('lyrics_id', id);
      } else {
        const query = String(req.query.q || '').trim();
        if (!query || query.length > 200) {
          return res.status(400).json({ error: 'Invalid search query' });
        }
        upstream.searchParams.set('q', query);
      }
    } else {
      return res.status(400).json({ error: 'Unsupported lyrics provider' });
    }

    const response = await fetch(upstream, {
      signal: controller.signal,
      headers: {
        Accept: 'application/json',
        'User-Agent': 'JumboMusic/2.0.0',
      },
    });

    const body = await response.text();

    if (!response.ok) {
      return res.status(response.status).send(body);
    }

    try {
      JSON.parse(body);
    } catch (_) {
      return res.status(502).json({ error: 'Invalid lyrics provider response' });
    }

    res.setHeader(
      'Cache-Control',
      provider === 'lrclib'
        ? 'public, s-maxage=60, stale-while-revalidate=120'
        : 'public, s-maxage=120, stale-while-revalidate=240'
    );
    res.setHeader('Content-Type', 'application/json; charset=utf-8');
    return res.status(200).send(body);
  } catch (_) {
    return res.status(502).json({ error: 'Lyrics provider temporarily unavailable' });
  } finally {
    clearTimeout(timeout);
  }
};
