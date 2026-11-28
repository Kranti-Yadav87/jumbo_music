const { test, before, after } = require('node:test');
const assert = require('node:assert/strict');

const { Innertube } = require('youtubei.js');

const originalCreate = Innertube.create;
const originalApiKey = process.env.YOUTUBE_API_KEY;

const fixtures = {
  'Heer Afusic': [
    {
      type: 'Video',
      video_id: 'WgGV5EE-8Co',
      title: 'Afusic - Heer (Official Music Video)',
      author: 'AFUSIC',
      length_text: '3:17',
      view_count: '1.2M views',
      thumbnails: [{ url: 'https://example.com/heer.jpg' }],
    },
    { type: 'GridShelfView', contents: [] },
  ],
  'Stand By Me': [
    {
      type: 'Video',
      video_id: 'hwZNL7QVJjE',
      title: 'Ben E. King - Stand By Me (Audio)',
      author: 'Soulful Sounds',
      length_text: '2:58',
    },
  ],
  'Kesariya Arijit Singh': [
    {
      type: 'Video',
      video_id: 'BddP6PYo2gs',
      title: 'Kesariya - Brahmastra',
      author: 'Sony Music India',
      length_text: '2:53',
    },
  ],
};

before(() => {
  process.env.YOUTUBE_API_KEY = '';

  Innertube.create = async () => ({
    search: async (query) => ({
      results: fixtures[query] || [],
    }),
  });
});

after(() => {
  Innertube.create = originalCreate;

  if (originalApiKey === undefined) {
    delete process.env.YOUTUBE_API_KEY;
  } else {
    process.env.YOUTUBE_API_KEY = originalApiKey;
  }
});

const handler = require('../../api/youtube-search.js');

async function invoke(query, method = 'GET') {
  const response = {
    statusCode: 200,
    headers: {},
    body: null,
    status(code) {
      this.statusCode = code;
      return this;
    },
    setHeader(name, value) {
      this.headers[name] = value;
    },
    json(data) {
      this.body = data;
      return this;
    },
  };

  await handler(
    { method, query: query === undefined ? {} : { q: query, limit: '15' } },
    response
  );

  return response;
}

test('Heer Afusic returns the official AFUSIC video with correct duration', async () => {
  const response = await invoke('Heer Afusic');

  assert.equal(response.statusCode, 200);
  assert.equal(response.body.items.length, 1);
  assert.equal(response.body.items[0].videoId, 'WgGV5EE-8Co');
  assert.equal(response.body.items[0].channelTitle, 'AFUSIC');
  assert.equal(response.body.items[0].durationSeconds, 197);
  assert.equal(response.body.items[0].viewCount, 1200000);
  assert.match(response.headers['Cache-Control'], /s-maxage=60/);
});

test('Stand By Me maps title, channel and duration correctly', async () => {
  const response = await invoke('Stand By Me');

  assert.equal(response.statusCode, 200);
  assert.equal(response.body.items[0].videoId, 'hwZNL7QVJjE');
  assert.equal(response.body.items[0].channelTitle, 'Soulful Sounds');
  assert.equal(response.body.items[0].durationSeconds, 178);
});

test('Kesariya returns the Sony Music India result', async () => {
  const response = await invoke('Kesariya Arijit Singh');

  assert.equal(response.statusCode, 200);
  assert.equal(response.body.items[0].videoId, 'BddP6PYo2gs');
  assert.equal(response.body.items[0].channelTitle, 'Sony Music India');
  assert.equal(response.body.items[0].durationSeconds, 173);
});

test('legacy youtubei.js object fields are also supported', async () => {
  fixtures['Legacy format'] = [
    {
      type: 'Video',
      video_id: 'legacy123',
      title: { text: 'Legacy Song' },
      author: { name: 'Legacy Artist', id: 'channel123' },
      published: { text: '2y ago' },
      duration: { seconds: 200 },
      view_count: { text: '2M views' },
      description_snippet: { text: 'Legacy description' },
      thumbnails: [{ url: 'https://example.com/legacy.jpg' }],
    },
  ];

  const response = await invoke('Legacy format');
  const item = response.body.items[0];

  assert.equal(item.title, 'Legacy Song');
  assert.equal(item.channelTitle, 'Legacy Artist');
  assert.equal(item.channelId, 'channel123');
  assert.equal(item.durationSeconds, 200);
  assert.equal(item.viewCount, 2000000);
  assert.equal(item.description, 'Legacy description');

  delete fixtures['Legacy format'];
});

test('non-video search entries are excluded', async () => {
  fixtures['Mixed results'] = [
    { type: 'GridShelfView', contents: [] },
    { type: 'LockupView', content_id: 'test' },
    {
      type: 'Video',
      video_id: 'valid123',
      title: 'Valid Video',
      author: 'Test Channel',
      length_text: '3:00',
    },
  ];

  const response = await invoke('Mixed results');

  assert.equal(response.statusCode, 200);
  assert.equal(response.body.items.length, 1);
  assert.equal(response.body.items[0].videoId, 'valid123');

  delete fixtures['Mixed results'];
});

test('empty query returns HTTP 400', async () => {
  const response = await invoke('');

  assert.equal(response.statusCode, 400);
  assert.equal(response.body.error, 'Invalid search query');
});

test('non-GET request returns HTTP 405', async () => {
  const response = await invoke('Heer Afusic', 'POST');

  assert.equal(response.statusCode, 405);
  assert.equal(response.body.error, 'Method not allowed');
});
