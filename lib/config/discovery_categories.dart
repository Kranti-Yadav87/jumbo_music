/// YouTube-style category pills shared by the Home feed and Search screen.
/// Maps the visible label to the live catalog query used to fill it.
/// An empty query means "All" (trending mix).
const Map<String, String> kDiscoveryCategories = <String, String>{
  'All': '',
  'Music': 'latest music hits',
  'Podcasts': 'popular podcasts',
  'Live': 'live music',
  'Bollywood': 'bollywood hits',
  'Chill': 'lofi chill music',
  'Workout': 'workout music',
  'Party': 'party hits',
  'Romance': 'romantic songs',
  'Focus': 'focus study music',
};
