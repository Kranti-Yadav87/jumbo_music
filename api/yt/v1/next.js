module.exports = async function handler(req, res) {
  if (req.method !== 'POST') {
    res.setHeader('Allow', 'POST');
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const body = req.body;

  if (!body || typeof body !== 'object' || Array.isArray(body)) {
    return res.status(400).json({ error: 'Invalid request body' });
  }

  const videoId = String(body.videoId || '').trim();

  if (!/^[A-Za-z0-9_-]{11}$/.test(videoId)) {
    return res.status(400).json({ error: 'Invalid video ID' });
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 12000);

  try {
    const upstream = await fetch(
      'https://music.youtube.com/youtubei/v1/next?alt=json',
      {
        method: 'POST',
        signal: controller.signal,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Origin': 'https://music.youtube.com',
          'User-Agent': 'Mozilla/5.0',
        },
        body: JSON.stringify({
          context: {
            client: {
              clientName: 'WEB_REMIX',
              clientVersion: '1.20261024.01.00',
            },
            user: {},
          },
          playlistId: `RDAMVM${videoId}`,
          videoId,
        }),
      }
    );

    const responseText = await upstream.text();

    let responseData;
    try {
      responseData = JSON.parse(responseText);
    } catch (_) {
      return res.status(502).json({
        error: 'YouTube Music returned an invalid response',
      });
    }

    if (!upstream.ok) {
      return res.status(502).json({
        error: 'YouTube Music radio provider unavailable',
      });
    }

    res.setHeader(
      'Cache-Control',
      'public, s-maxage=30, stale-while-revalidate=60'
    );

    return res.status(200).json(responseData);
  } catch (_) {
    return res.status(502).json({
      error: 'YouTube Music radio temporarily unavailable',
    });
  } finally {
    clearTimeout(timeout);
  }
};
