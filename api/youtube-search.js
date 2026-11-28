const { Innertube } = require('youtubei.js');

let youtubeClientPromise = null;

function setCacheHeaders(res) {
  res.setHeader(
    'Cache-Control',
    'public, s-maxage=60, stale-while-revalidate=120'
  );
}

function withTimeout(task, milliseconds, label) {
  let timer;

  return Promise.race([
    Promise.resolve().then(task),
    new Promise((_, reject) => {
      timer = setTimeout(
        () => reject(new Error(`${label} timed out`)),
        milliseconds
      );
    }),
  ]).finally(() => clearTimeout(timer));
}

function parseViewCount(value) {
  const match = String(value || '').match(/([\d,.]+)\s*([KMB])?/i);
  if (!match) return 0;

  const number = Number.parseFloat(match[1].replace(/,/g, ''));
  if (!Number.isFinite(number)) return 0;

  const suffix = (match[2] || '').toUpperCase();
  const multiplier =
    suffix === 'K' ? 1e3 :
    suffix === 'M' ? 1e6 :
    suffix === 'B' ? 1e9 : 1;

  return Math.round(number * multiplier);
}

function parseDurationSeconds(value) {
  const parts = String(value || '').trim().split(':').map(Number);

  if (
    (parts.length !== 2 && parts.length !== 3) ||
    parts.some((part) => !Number.isFinite(part) || part < 0)
  ) {
    return 0;
  }

  return parts.reduce((total, part) => total * 60 + part, 0);
}

function readInnertubeText(value) {
  if (typeof value === 'string') return value;
  if (typeof value === 'number') return String(value);
  if (!value || typeof value !== 'object') return '';

  if (typeof value.text === 'string') return value.text;

  if (
    typeof value.toString === 'function' &&
    value.toString !== Object.prototype.toString
  ) {
    const text = value.toString();
    return text === 'N/A' ? '' : text;
  }

  return '';
}

async function searchWithInnertube(query, limit) {
  if (!youtubeClientPromise) {
    youtubeClientPromise = Innertube.create();
  }

  const pendingClient = youtubeClientPromise;
  let youtube;

  try {
    youtube = await withTimeout(
      () => pendingClient,
      7000,
      'YouTube client initialization'
    );
  } catch (error) {
    if (youtubeClientPromise === pendingClient) {
      youtubeClientPromise = null;
    }
    throw error;
  }

  const searchData = await withTimeout(
    () => youtube.search(query),
    8000,
    'YouTube alternative search'
  );

  const results = Array.isArray(searchData?.results)
    ? searchData.results
    : [];

  return results
    .filter((video) => {
      const title = readInnertubeText(video?.title);

      return (
        video?.type === 'Video' &&
        typeof video.video_id === 'string' &&
        video.video_id.length > 0 &&
        title.trim().length > 0
      );
    })
    .slice(0, limit)
    .map((video) => {
      const author = video.author;
      const title = readInnertubeText(video.title);
      const thumbnails = Array.isArray(video.thumbnails)
        ? video.thumbnails
        : [];

      return {
        videoId: video.video_id,
        title,
        channelTitle:
          typeof author === 'string'
            ? author
            : readInnertubeText(author?.name),
        channelId: typeof author === 'object' ? author?.id || '' : '',
        publishedAt: readInnertubeText(video.published),
        thumbnail: thumbnails[0]?.url || '',
        durationSeconds: Number(
          video.duration?.seconds ||
          parseDurationSeconds(readInnertubeText(video.length_text)) ||
          0
        ),
        categoryId: '',
        description: readInnertubeText(video.description_snippet),
        tags: [],
        viewCount: parseViewCount(readInnertubeText(video.view_count)),
        likeCount: 0,
      };
    });
}

async function respondWithFallback(res, query, limit, reason) {
  console.warn('[youtube-search] Using youtubei.js fallback', { reason });

  try {
    const items = await searchWithInnertube(query, limit);
    setCacheHeaders(res);
    return res.status(200).json({ items });
  } catch (error) {
    console.error('[youtube-search] Alternative provider failed', {
      name: error?.name || 'UnknownError',
      message: error?.message || 'No error message',
    });

    return res.status(502).json({
      error: 'YouTube search temporarily unavailable',
    });
  }
}

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
    return respondWithFallback(
      res,
      query,
      limit,
      'Google API key is not configured'
    );
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

    let searchResponse;

    try {
      searchResponse = await fetch(searchUrl, {
        signal: controller.signal,
        headers: { Accept: 'application/json' },
      });
    } catch (error) {
      console.error('[youtube-search] Google Search request failed', {
        name: error?.name || 'UnknownError',
        message: error?.message || 'No error message',
        aborted: error?.name === 'AbortError',
      });

      return await respondWithFallback(
        res,
        query,
        limit,
        'Google Search request failed'
      );
    }

    if (!searchResponse.ok) {
      let providerError = {};

      try {
        providerError = await searchResponse.json();
      } catch (_) {}

      const reason =
        providerError.error?.errors?.[0]?.reason || 'unknown';

      console.error('[youtube-search] Google Search API failure', {
        status: searchResponse.status,
        statusText: searchResponse.statusText,
        reason,
        message: providerError.error?.message || 'No provider message',
      });

      return await respondWithFallback(
        res,
        query,
        limit,
        `Google Search API returned ${searchResponse.status}: ${reason}`
      );
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
    const videoDetails = new Map();

    if (videoIds.length > 0) {
      const detailsUrl = new URL(
        'https://www.googleapis.com/youtube/v3/videos'
      );

      detailsUrl.searchParams.set(
        'part',
        'snippet,contentDetails,statistics'
      );
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

          const seconds = match
            ? Number(match[1] || 0) * 3600 +
              Number(match[2] || 0) * 60 +
              Number(match[3] || 0)
            : 0;

          const statistics = item.statistics || {};
          const snippetDetails = item.snippet || {};

          videoDetails.set(item.id, {
            durationSeconds: seconds,
            title: snippetDetails.title || '',
            description: (snippetDetails.description || '').slice(0, 1500),
            tags: Array.isArray(snippetDetails.tags)
              ? snippetDetails.tags.slice(0, 30)
              : [],
            categoryId: snippetDetails.categoryId || '',
            channelId: snippetDetails.channelId || '',
            viewCount: Number(statistics.viewCount || 0),
            likeCount: Number(statistics.likeCount || 0),
          });
        }
      }
    }

    const items = videoItems.map((item) => {
      const snippet = item.snippet;
      const thumbnails = snippet.thumbnails || {};
      const details = videoDetails.get(item.id.videoId) || {};

      return {
        videoId: item.id.videoId,
        title: details.title || snippet.title || '',
        channelTitle: snippet.channelTitle || '',
        channelId: details.channelId || '',
        publishedAt: snippet.publishedAt || '',
        thumbnail:
          thumbnails.high?.url ||
          thumbnails.medium?.url ||
          thumbnails.default?.url ||
          '',
        durationSeconds: details.durationSeconds || 0,
        categoryId: details.categoryId || '',
        description: details.description || '',
        tags: details.tags || [],
        viewCount: details.viewCount || 0,
        likeCount: details.likeCount || 0,
      };
    });

    setCacheHeaders(res);
    return res.status(200).json({ items });
  } catch (error) {
    console.error('[youtube-search] Request failed', {
      name: error?.name || 'UnknownError',
      message: error?.message || 'No error message',
      aborted: error?.name === 'AbortError',
    });

    return res.status(502).json({
      error: 'YouTube search temporarily unavailable',
    });
  } finally {
    clearTimeout(timeout);
  }
};
