module.exports = async function handler(req, res) {
  if (req.method !== 'GET') {
    return res.status(405).json({ error: 'Method not allowed' });
  }

  const query = String(req.query.q || '').trim();
  const limit = Math.min(25, Math.max(1, Number(req.query.limit) || 20));
  const apiKey = process.env.YOUTUBE_API_KEY;

  if (!query || query.length > 150) {
    return res.status(400).json({ error: 'Invalid search query' });
  }

  if (!apiKey) {
    return res.status(503).json({ error: 'YouTube search is not configured' });
  }

  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), 12000);

  try {
    const searchUrl = new URL(
      'https://www.googleapis.com/youtube/v3/search'
    );

    searchUrl.searchParams.set('part', 'snippet');
    searchUrl.searchParams.set('type', 'video');
    searchUrl.searchParams.set('maxResults', String(limit));
    searchUrl.searchParams.set('q', query);
    searchUrl.searchParams.set('key', apiKey);

    const searchResponse = await fetch(searchUrl, {
      signal: controller.signal,
      headers: { Accept: 'application/json' },
    });

    if (!searchResponse.ok) {
      return res.status(502).json({
        error: 'YouTube search provider unavailable',
      });
    }

    const searchData = await searchResponse.json();
    const sourceItems = Array.isArray(searchData.items)
      ? searchData.items
      : [];

    const videoItems = sourceItems.filter(
      (item) =>
        typeof item.id?.videoId === 'string' &&
        item.id.videoId.length > 0 &&
        item.snippet
    );

    const videoIds = videoItems.map((item) => item.id.videoId);
    const durations = new Map();

    if (videoIds.length > 0) {
      const detailsUrl = new URL(
        'https://www.googleapis.com/youtube/v3/videos'
      );

      detailsUrl.searchParams.set('part', 'contentDetails');
      detailsUrl.searchParams.set('id', videoIds.join(','));
      detailsUrl.searchParams.set('key', apiKey);

      const detailsResponse = await fetch(detailsUrl, {
        signal: controller.signal,
        headers: { Accept: 'application/json' },
      });

      if (detailsResponse.ok) {
        const detailsData = await detailsResponse.json();

        for (const item of detailsData.items || []) {
          const value = item.contentDetails?.duration || '';
          const match = value.match(
            /^PT(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?$/
          );

          if (match) {
            const seconds =
              Number(match[1] || 0) * 3600 +
              Number(match[2] || 0) * 60 +
              Number(match[3] || 0);

            durations.set(item.id, seconds);
          }
        }
      }
    }

    const items = videoItems.map((item) => {
      const snippet = item.snippet;
      const thumbnails = snippet.thumbnails || {};

      return {
        videoId: item.id.videoId,
        title: snippet.title || '',
        channelTitle: snippet.channelTitle || '',
        publishedAt: snippet.publishedAt || '',
        thumbnail:
          thumbnails.high?.url ||
          thumbnails.medium?.url ||
          thumbnails.default?.url ||
          '',
        durationSeconds: durations.get(item.id.videoId) || 0,
      };
    });

    res.setHeader(
      'Cache-Control',
      'public, s-maxage=60, stale-while-revalidate=120'
    );

    return res.status(200).json({ items });
  } catch (_) {
    return res.status(502).json({
      error: 'YouTube search temporarily unavailable',
    });
  } finally {
    clearTimeout(timeout);
  }
};
