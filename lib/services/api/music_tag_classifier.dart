import '../../models/song.dart';

/// Pure logic classifier for song languages and musical eras.
class MusicTagClassifier {
  MusicTagClassifier._();

  /// Detects language of a song (Hindi, Punjabi, South, English, Bhojpuri, Haryanvi)
  static String detectSongLanguage(Song song) {
    final titleLower = song.title.toLowerCase();
    final artistLower = song.artist.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final genreLower = song.genre.toLowerCase();
    final langLower = song.language.toLowerCase();

    // 1. Explicit Hindi words in title (Never treat as English if title has Hindi words)
    final bool hasHindiWords =
        titleLower.contains('dil') ||
        titleLower.contains('pyar') ||
        titleLower.contains('pyaar') ||
        titleLower.contains('ishq') ||
        titleLower.contains('tere') ||
        titleLower.contains('teri') ||
        titleLower.contains('tera') ||
        titleLower.contains('tum') ||
        titleLower.contains('hum') ||
        titleLower.contains('chalein') ||
        titleLower.contains('aao') ||
        titleLower.contains('kya') ||
        titleLower.contains('hai') ||
        titleLower.contains('hain') ||
        titleLower.contains('zindagi') ||
        titleLower.contains('sukoon') ||
        titleLower.contains('mohabbat') ||
        titleLower.contains('saath') ||
        titleLower.contains('raatein') ||
        titleLower.contains('baatein') ||
        titleLower.contains('jaana') ||
        titleLower.contains('deewana') ||
        titleLower.contains('sanam') ||
        titleLower.contains('chura') ||
        titleLower.contains('aaja') ||
        titleLower.contains('naina') ||
        titleLower.contains('akhiyaan') ||
        titleLower.contains('dholna') ||
        titleLower.contains('rabba') ||
        titleLower.contains('meri') ||
        titleLower.contains('mera') ||
        titleLower.contains('mere') ||
        titleLower.contains('musafir') ||
        titleLower.contains('dard') ||
        titleLower.contains('intezaar');

    if (hasHindiWords && !albumLower.contains('english')) {
      return 'Hindi';
    }

    if (langLower.contains('punjabi') ||
        genreLower.contains('punjabi') ||
        albumLower.contains('punjabi')) {
      return 'Punjabi';
    }
    if (langLower.contains('tamil') ||
        langLower.contains('telugu') ||
        langLower.contains('kannada') ||
        langLower.contains('malayalam') ||
        genreLower.contains('tamil') ||
        genreLower.contains('telugu') ||
        genreLower.contains('south')) {
      return 'South';
    }
    if (langLower.contains('bhojpuri') || genreLower.contains('bhojpuri')) {
      return 'Bhojpuri';
    }
    if (langLower.contains('haryanvi') || genreLower.contains('haryanvi')) {
      return 'Haryanvi';
    }

    // 2. English Indicators
    if (langLower.contains('english') ||
        langLower.contains('western') ||
        genreLower.contains('english') ||
        albumLower.contains('english') ||
        albumLower.contains('billboard') ||
        albumLower.contains('global') ||
        albumLower.contains('hollywood') ||
        artistLower.contains('taylor swift') ||
        artistLower.contains('the weeknd') ||
        artistLower.contains('drake') ||
        artistLower.contains('ed sheeran') ||
        artistLower.contains('justin bieber') ||
        artistLower.contains('dua lipa') ||
        artistLower.contains('billie eilish') ||
        artistLower.contains('bruno mars') ||
        artistLower.contains('coldplay') ||
        artistLower.contains('post malone') ||
        artistLower.contains('maroon 5') ||
        artistLower.contains('charlie puth') ||
        artistLower.contains('shawn mendes') ||
        artistLower.contains('selena gomez') ||
        artistLower.contains('ariana grande') ||
        artistLower.contains('eminem') ||
        artistLower.contains('adele') ||
        artistLower.contains('rihanna') ||
        artistLower.contains('hanumankind') ||
        artistLower.contains('parekh & singh') ||
        artistLower.contains('when chai met toast') ||
        artistLower.contains('raghav meattle') ||
        artistLower.contains('tsumyoki')) {
      return 'English';
    }

    // Check specific English track titles
    if (titleLower == 'blush' ||
        titleLower == 'co2' ||
        titleLower.contains('mess') ||
        titleLower.contains('doll') ||
        titleLower.contains('unicorn') ||
        titleLower.contains('pink blue') ||
        titleLower.contains('when we feel young') ||
        titleLower.contains('big dawgs')) {
      return 'English';
    }

    // Punjabi Artists
    if (artistLower.contains('karan aujla') ||
        artistLower.contains('diljit') ||
        artistLower.contains('sidhu moose') ||
        artistLower.contains('ap dhillon') ||
        artistLower.contains('shubh') ||
        artistLower.contains('bohemia') ||
        artistLower.contains('talwiinder') ||
        artistLower.contains('ammy virk') ||
        artistLower.contains('b praak') ||
        artistLower.contains('parmish verma')) {
      return 'Punjabi';
    }

    // South Artists
    if (artistLower.contains('anirudh') ||
        artistLower.contains('sid sriram') ||
        artistLower.contains('devi sri prasad') ||
        artistLower.contains('ilaiyaraaja') ||
        artistLower.contains('thaman') ||
        artistLower.contains('santhosh narayanan') ||
        artistLower.contains('harris jayaraj') ||
        artistLower.contains('yuvan shankar') ||
        artistLower.contains('spb') ||
        artistLower.contains('chithra')) {
      return 'South';
    }

    // Bhojpuri
    if (artistLower.contains('pawan singh') ||
        artistLower.contains('khesari') ||
        artistLower.contains('shilpi raj') ||
        artistLower.contains('nirahua') ||
        titleLower.contains('lollipop')) {
      return 'Bhojpuri';
    }

    // Haryanvi
    if (artistLower.contains('gulzaar chhaniwala') ||
        artistLower.contains('renuka panwar') ||
        artistLower.contains('diler kharkiya')) {
      return 'Haryanvi';
    }

    return 'Hindi';
  }

  /// Checks if a song belongs to the 1950s - 1970s Vintage Golden Era
  static bool isVintageGoldenEra(Song song) {
    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    final year = int.tryParse(song.releaseYear);
    if (year != null && year >= 1940 && year < 1980) {
      return true;
    }

    // Iconic 50s-70s film & track titles
    if (albumLower.contains('baharon ke sapne') ||
        albumLower.contains('aradhana') ||
        albumLower.contains('anand') ||
        albumLower.contains('sholay') ||
        albumLower.contains('kati patang') ||
        albumLower.contains('amar prem') ||
        albumLower.contains('pakeezah') ||
        albumLower.contains('mughal-e-azam') ||
        albumLower.contains('guide') ||
        albumLower.contains('hum kisise kum naheen') ||
        albumLower.contains('kabhie kabhie') ||
        albumLower.contains('silsila') ||
        titleLower.contains('aaja piya tohe') ||
        titleLower.contains('lag ja gale') ||
        titleLower.contains('pal pal dil') ||
        titleLower.contains('roop tera mastana') ||
        titleLower.contains('mere sapno ki rani') ||
        titleLower.contains('gulabi aankhen') ||
        titleLower.contains('chaudhvin ka chand') ||
        titleLower.contains('chura liya hai tumne') ||
        titleLower.contains('tere bina zindagi se') ||
        titleLower.contains('pyar kiya to darna kya') ||
        titleLower.contains('panna ki tamanna') ||
        titleLower.contains('ek ajnabee haseena')) {
      return true;
    }

    // Exclusive Vintage Legends (before 1980)
    final isClassicSinger =
        artistLower.contains('kishore kumar') ||
        artistLower.contains('mohammed rafi') ||
        artistLower.contains('mohd rafi') ||
        artistLower.contains('mukesh') ||
        artistLower.contains('hemant kumar') ||
        artistLower.contains('talat mahmood') ||
        artistLower.contains('manna dey') ||
        artistLower.contains('geeta dutt') ||
        artistLower.contains('s. d. burman') ||
        artistLower.contains('sd burman') ||
        artistLower.contains('naushad') ||
        artistLower.contains('madan mohan') ||
        artistLower.contains('o.p. nayyar') ||
        artistLower.contains('salil chowdhury') ||
        artistLower.contains('khayyam');

    if (isClassicSinger) {
      if (year == null || year < 1980 || year >= 2024) {
        return true;
      }
    }

    // Lata Mangeshkar / Asha Bhosle vintage check
    if ((artistLower.contains('lata mangeshkar') ||
            artistLower.contains('asha bhosle')) &&
        !artistLower.contains('kumar sanu') &&
        !artistLower.contains('udit narayan') &&
        !artistLower.contains('sonu nigam') &&
        !artistLower.contains('arijit') &&
        !titleLower.contains('dil to pagal hai') &&
        !titleLower.contains('tujhe dekha to') &&
        !titleLower.contains('andekhi anjaani') &&
        !titleLower.contains('humko humise') &&
        !titleLower.contains('tere liye') &&
        !titleLower.contains('kabhi khushi') &&
        !titleLower.contains('zubi zubi') &&
        !titleLower.contains('radha kaise na jale')) {
      if (year == null || year < 1980 || year >= 2024) {
        return true;
      }
    }

    return genreLower.contains('retro') ||
        genreLower.contains('golden') ||
        genreLower.contains('purane') ||
        genreLower.contains('60s') ||
        genreLower.contains('70s');
  }

  /// Checks if a song belongs to the 1980s Era (Bappi Lahiri, Disco, Chandni, Tezaab, QSQT)
  static bool is80sEra(Song song) {
    if (isVintageGoldenEra(song)) return false;

    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    final year = int.tryParse(song.releaseYear);
    if (year != null && year >= 1980 && year < 1990) {
      return true;
    }

    return artistLower.contains('bappi lahiri') ||
        artistLower.contains('amit kumar') ||
        artistLower.contains('shabbir kumar') ||
        artistLower.contains('mohammed aziz') ||
        artistLower.contains('salma agha') ||
        artistLower.contains('nazia hassan') ||
        artistLower.contains('alisha chinai') ||
        albumLower.contains('disco dancer') ||
        albumLower.contains('chandni') ||
        albumLower.contains('tezaab') ||
        albumLower.contains('qayamat se qayamat tak') ||
        albumLower.contains('mr. india') ||
        albumLower.contains('mr india') ||
        albumLower.contains('himmatwala') ||
        albumLower.contains('karz') ||
        albumLower.contains('hero (1983)') ||
        albumLower.contains('maine pyar kiya') ||
        albumLower.contains('tridev') ||
        albumLower.contains('ram lakhan') ||
        titleLower.contains('i am a disco dancer') ||
        titleLower.contains('jimmy jimmy') ||
        titleLower.contains('ek do teen') ||
        titleLower.contains('mere haathon mein') ||
        titleLower.contains('papa kehte hain') ||
        titleLower.contains('gazab ka hai din') ||
        titleLower.contains('hawa hawai') ||
        titleLower.contains('dil deewana') ||
        titleLower.contains('kabootar ja ja') ||
        genreLower.contains('80s');
  }

  /// Checks if a song belongs to the 1990s Melodies Era (Kumar Sanu, Alka Yagnik, Udit Narayan, DDLJ, Saajan)
  static bool is90sMelodyEra(Song song) {
    if (isVintageGoldenEra(song) || is80sEra(song)) return false;

    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    final year = int.tryParse(song.releaseYear);
    if (year != null && year >= 1990 && year < 2000) {
      return true;
    }

    return artistLower.contains('kumar sanu') ||
        artistLower.contains('alka yagnik') ||
        artistLower.contains('udit narayan') ||
        artistLower.contains('anuradha paudwal') ||
        artistLower.contains('sadhana sargam') ||
        artistLower.contains('kavita krishnamurthy') ||
        artistLower.contains('abhijeet') ||
        artistLower.contains('pankaj udhas') ||
        artistLower.contains('roop kumar rathod') ||
        artistLower.contains('nadeem') ||
        artistLower.contains('shravan') ||
        artistLower.contains('jatin') ||
        artistLower.contains('lalit') ||
        albumLower.contains('aashiqui') ||
        albumLower.contains('saajan') ||
        albumLower.contains('dil to pagal hai') ||
        albumLower.contains('kuch kuch hota hai') ||
        albumLower.contains('raja hindustani') ||
        albumLower.contains('baazigar') ||
        albumLower.contains('hum aapke hain koun') ||
        albumLower.contains('pardes') ||
        albumLower.contains('mohra') ||
        albumLower.contains('border') ||
        albumLower.contains('kaho naa... pyaar hai') ||
        titleLower.contains('dil to pagal hai') ||
        titleLower.contains('tujhe dekha to') ||
        titleLower.contains('chura ke dil mera') ||
        titleLower.contains('tip tip barsa') ||
        titleLower.contains('aashiqui') ||
        titleLower.contains('saajan') ||
        titleLower.contains('kuch kuch hota hai') ||
        titleLower.contains('raja hindustani') ||
        titleLower.contains('baazigar') ||
        titleLower.contains('hum aapke hain koun') ||
        titleLower.contains('dilwale dulhania') ||
        genreLower.contains('90s');
  }

  /// Checks if a song belongs to the 2000s - 2009 Bollywood Soulful / Emraan Hashmi Era / KK
  static bool is2000sSong(Song song) {
    if (isVintageGoldenEra(song) || is80sEra(song) || is90sMelodyEra(song)) {
      return false;
    }

    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final year = int.tryParse(song.releaseYear);
    if (year != null && year >= 2000 && year < 2010) {
      return true;
    }

    return artistLower.contains('kk') ||
        artistLower.contains('krishnakumar') ||
        artistLower.contains('shaan') ||
        artistLower.contains('lucky ali') ||
        artistLower.contains('himesh reshammiya') ||
        artistLower.contains('kailash kher') ||
        artistLower.contains('adnan sami') ||
        artistLower.contains('zubeen garg') ||
        artistLower.contains('kunal ganjawala') ||
        artistLower.contains('mustafa zahid') ||
        artistLower.contains('jal') ||
        artistLower.contains('roxen') ||
        artistLower.contains('strings') ||
        albumLower.contains('tere naam') ||
        albumLower.contains('kal ho naa ho') ||
        albumLower.contains('main hoon na') ||
        albumLower.contains('veer-zaara') ||
        albumLower.contains('jab we met') ||
        albumLower.contains('fanaa') ||
        albumLower.contains('jannat') ||
        albumLower.contains('gangster') ||
        albumLower.contains('murder') ||
        albumLower.contains('awarapan') ||
        titleLower.contains('woh lamhe') ||
        titleLower.contains('tu hi meri shab') ||
        titleLower.contains('labon ko') ||
        titleLower.contains('kya mujhe pyar hai') ||
        titleLower.contains('zara sa') ||
        titleLower.contains('peehloon') ||
        titleLower.contains('mitwa') ||
        titleLower.contains('alvida') ||
        titleLower.contains('aadat');
  }

  /// Checks if a song belongs to the 2010s (2010 - 2019) Arijit Singh / Modern Romantic Era
  static bool is2010sSong(Song song) {
    if (isVintageGoldenEra(song) ||
        is80sEra(song) ||
        is90sMelodyEra(song) ||
        is2000sSong(song)) {
      return false;
    }

    final year = int.tryParse(song.releaseYear);
    if (year != null && year >= 2010 && year < 2020) {
      return true;
    }

    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();

    return albumLower.contains('aashiqui 2') ||
        albumLower.contains('kabir singh') ||
        albumLower.contains('yeh jawaani hai deewani') ||
        albumLower.contains('rockstar') ||
        albumLower.contains('sanam re') ||
        albumLower.contains('ae dil hai mushkil') ||
        albumLower.contains('raabta') ||
        titleLower.contains('tum hi ho') ||
        titleLower.contains('channa mereya') ||
        titleLower.contains('gerua') ||
        titleLower.contains('bekhayali') ||
        titleLower.contains('shayad') ||
        titleLower.contains('hawayein');
  }

  /// Checks if a song belongs to Indie / Acoustic / Sukoon
  static bool isIndieOrSukoonSong(Song song) {
    final artistLower = song.artist.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    return artistLower.contains('anuv jain') ||
        artistLower.contains('prateek kuhad') ||
        artistLower.contains('jasleen royal') ||
        artistLower.contains('aditya a') ||
        artistLower.contains('mitraz') ||
        artistLower.contains('aur') ||
        artistLower.contains('kaifi khalil') ||
        artistLower.contains('faheem abdullah') ||
        artistLower.contains('bharat chauhan') ||
        artistLower.contains('local train') ||
        genreLower.contains('indie') ||
        genreLower.contains('acoustic') ||
        genreLower.contains('sukoon') ||
        genreLower.contains('lo-fi');
  }
}
