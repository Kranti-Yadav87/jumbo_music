import '../../models/song.dart';

/// Musical eras supported by the recommendation engine.
enum MusicEra { vintage70s, era80s, era90s, era2000s, era2010s, genZModern }

/// Pure logic classifier for song languages and musical eras.
class MusicTagClassifier {
  MusicTagClassifier._();

  /// Helper to check if a song is strictly English
  static bool isEnglishSong(Song song) {
    return detectSongLanguage(song) == 'English';
  }

  /// Detects language from raw strings/metadata
  static String detectTextLanguage({
    required String title,
    required String artist,
    String album = '',
    String genre = '',
    String rawLanguage = '',
    String audioUrl = '',
    String id = '',
  }) {
    final titleLower = title.toLowerCase();
    final artistLower = artist.toLowerCase();
    final albumLower = album.toLowerCase();
    final genreLower = genre.toLowerCase();
    final langLower = rawLanguage.toLowerCase();

    // 0. Jamendo tracks are 100% Western / English creative commons catalog
    if (id.startsWith('jamendo_') || audioUrl.contains('jamendo')) {
      return 'English';
    }

    // 1. Explicit Hindi phonetic tokens
    final titleTokens = titleLower
        .split(RegExp(r'[^a-z0-9]+'))
        .where((t) => t.isNotEmpty)
        .toSet();

    const hindiPhoneticTokens = {
      'dil',
      'hindi',
      'bollywood',
      'desi',
      'filmi',
      'ghazal',
      'qawwali',
      'sufi',
      'bhangra',
      'pyar',
      'pyaar',
      'ishq',
      'tere',
      'teri',
      'tera',
      'tum',
      'hum',
      'chalein',
      'aao',
      'kya',
      'hai',
      'hain',
      'zindagi',
      'sukoon',
      'mohabbat',
      'saath',
      'raatein',
      'baatein',
      'jaana',
      'deewana',
      'deewani',
      'sanam',
      'chura',
      'aaja',
      'naina',
      'akhiyaan',
      'dholna',
      'rabba',
      'meri',
      'mera',
      'mere',
      'musafir',
      'dard',
      'intezaar',
      'aankhen',
      'aankhon',
      'khuda',
      'dua',
      'wafa',
      'bewafa',
      'tujhe',
      'mujhko',
      'humko',
      'tumko',
      'kabhi',
      'kahin',
      'kahan',
      'jaane',
      'maahi',
      'chupke',
      'dhadkan',
      'saanson',
      'rooh',
      'chaahat',
      'afsaana',
      'yaadein',
      'yaad',
      'jeena',
      'marna',
      'kasam',
      'khwaab',
      'sapne',
      'deewangi',
      'nazar',
      'nazron',
      'aashiqui',
      'safar',
      'hawa',
      'hawayein',
      'hawaayein',
      'banke',
      'barsaat',
      'baarish',
      'chaand',
      'roshni',
      'tasveer',
      'dosti',
      'yaar',
      'yaara',
      'sajna',
      'jhumka',
      'saajan',
      'awaaz',
      'geet',
      'kesariya',
      'chaleya',
      'satranga',
      'heeriye',
      'ranjha',
      'bekhayali',
      'aadat',
      'alvida',
      'khoobsurat',
      'kamleya',
      'kamli',
      'tauba',
      'sajni',
      'taras',
      'gulabi',
      'chuttamalle',
      'zikr',
      'asal',
      'mehar',
      'jinna',
      'sohna',
      'apna',
      'apne',
      'apni',
      'tumhe',
      'humein',
      'mujhe',
      'bhi',
      'main',
      'mein',
      'pehle',
      'suno',
      'kahani',
      'chale',
      'gaya',
      'gaye',
      'gayi',
      'raha',
      'rahe',
      'rahi',
      'hua',
      'hue',
      'hui',
      'tha',
      'the',
      'thi',
      'hoon',
      'hona',
      'hone',
      'jaan',
      'jaani',
      'jahaan',
      'duniya',
      'khushi',
      'gham',
      'pal',
      'lamha',
      'lamhe',
      'shab',
      'subah',
      'shaam',
      'raat',
      'din',
      'aaj',
      'kal',
      'barsa',
      'barso',
      'aansoo',
      'muskurana',
      'shanti',
      'chain',
      'qaraar',
      'tanha',
      'tanhaai',
      'akele',
      'akelapan',
      'juda',
      'judaai',
      'ibadat',
      'ibaadat',
      'sajda',
    };

    final bool hasHindiWords =
        titleTokens.any(hindiPhoneticTokens.contains) ||
        titleLower.contains('dil') ||
        titleLower.contains('pyar') ||
        titleLower.contains('pyaar') ||
        titleLower.contains('ishq') ||
        titleLower.contains('tere') ||
        titleLower.contains('teri') ||
        titleLower.contains('tera') ||
        titleLower.contains('zindagi') ||
        titleLower.contains('sukoon') ||
        titleLower.contains('mohabbat') ||
        titleLower.contains('tum hi ho') ||
        titleLower.contains('channa mereya') ||
        titleLower.contains('pal pal dil') ||
        titleLower.contains('lag ja gale') ||
        titleLower.contains('roop tera mastana') ||
        titleLower.contains('gulabi aankhen') ||
        titleLower.contains('chaudhvin ka chand') ||
        titleLower.contains('tere bina zindagi') ||
        titleLower.contains('ek ajnabee haseena') ||
        titleLower.contains('yeh dosti') ||
        titleLower.contains('o mere dil ke chain') ||
        titleLower.contains('kya hua tera wada') ||
        titleLower.contains('baharon phool barsao') ||
        titleLower.contains('tum se hi') ||
        titleLower.contains('pee loon') ||
        titleLower.contains('kya mujhe pyar hai') ||
        titleLower.contains('labon ko') ||
        titleLower.contains('zara sa') ||
        titleLower.contains('dil ibaadat') ||
        titleLower.contains('woh lamhe') ||
        titleLower.contains('tu hi meri shab') ||
        titleLower.contains('tu jaane na') ||
        titleLower.contains('pehle bhi main') ||
        titleLower.contains('o maahi') ||
        titleLower.contains('lutt putt gaya') ||
        titleLower.contains('aaj ki raat') ||
        titleLower.contains('aayi nai') ||
        titleLower.contains('ve kamleya') ||
        titleLower.contains('what jhumka') ||
        titleLower.contains('hawa banke') ||
        titleLower.contains('lut gaye');

    if (hasHindiWords &&
        !albumLower.contains('english') &&
        !genreLower.contains('english')) {
      return 'Hindi';
    }

    // Explicit English rawLanguage metadata from API
    if (langLower == 'english' ||
        langLower == 'en' ||
        langLower.contains('english')) {
      return 'English';
    }

    // 2. Punjabi Indicators
    if (langLower.contains('punjabi') ||
        genreLower.contains('punjabi') ||
        albumLower.contains('punjabi') ||
        artistLower.contains('karan aujla') ||
        artistLower.contains('diljit') ||
        artistLower.contains('sidhu moose') ||
        artistLower.contains('ap dhillon') ||
        artistLower.contains('shubh') ||
        artistLower.contains('bohemia') ||
        artistLower.contains('talwiinder') ||
        artistLower.contains('ammy virk') ||
        artistLower.contains('b praak') ||
        artistLower.contains('parmish verma') ||
        artistLower.contains('gurdas maan') ||
        artistLower.contains('kuldeep manak') ||
        artistLower.contains('surinder kaur') ||
        artistLower.contains('chamkila') ||
        titleLower.contains('tauba tauba') ||
        titleLower.contains('winning speech') ||
        titleLower.contains('softly') ||
        titleLower.contains('cheques') ||
        titleLower.contains('one love') ||
        titleLower.contains('brown munde') ||
        titleLower.contains('excuses') ||
        titleLower.contains('insane')) {
      return 'Punjabi';
    }

    // 3. South Indicators
    if (langLower.contains('tamil') ||
        langLower.contains('telugu') ||
        langLower.contains('kannada') ||
        langLower.contains('malayalam') ||
        genreLower.contains('tamil') ||
        genreLower.contains('telugu') ||
        genreLower.contains('south') ||
        artistLower.contains('anirudh') ||
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

    // 4. Bhojpuri Indicators
    if (langLower.contains('bhojpuri') ||
        genreLower.contains('bhojpuri') ||
        artistLower.contains('pawan singh') ||
        artistLower.contains('khesari') ||
        artistLower.contains('shilpi raj') ||
        artistLower.contains('nirahua') ||
        titleLower.contains('lollipop')) {
      return 'Bhojpuri';
    }

    // 5. Haryanvi Indicators
    if (langLower.contains('haryanvi') ||
        genreLower.contains('haryanvi') ||
        artistLower.contains('gulzaar chhaniwala') ||
        artistLower.contains('renuka panwar') ||
        artistLower.contains('diler kharkiya') ||
        artistLower.contains('masoom sharma') ||
        titleLower.contains('52 gaj')) {
      return 'Haryanvi';
    }

    // 6. Global & Western English Artists
    final bool isEnglishArtist =
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
        artistLower.contains('tsumyoki') ||
        artistLower.contains('imagine dragons') ||
        artistLower.contains('queen') ||
        artistLower.contains('the beatles') ||
        artistLower.contains('michael jackson') ||
        artistLower.contains('katy perry') ||
        artistLower.contains('lady gaga') ||
        artistLower.contains('beyonce') ||
        artistLower.contains('shakira') ||
        artistLower.contains('harry styles') ||
        artistLower.contains('zayn') ||
        artistLower.contains('sia') ||
        artistLower.contains('alan walker') ||
        artistLower.contains('marshmello') ||
        artistLower.contains('chainsmokers') ||
        artistLower.contains('onerepublic') ||
        artistLower.contains('one direction') ||
        artistLower.contains('stephen sanchez') ||
        artistLower.contains('jvke') ||
        artistLower.contains('benson boone') ||
        artistLower.contains('sabrina carpenter') ||
        artistLower.contains('olivia rodrigo') ||
        artistLower.contains('travis scott') ||
        artistLower.contains('kendrick lamar') ||
        artistLower.contains('sza') ||
        artistLower.contains('lana del rey') ||
        artistLower.contains('cigarettes after sex') ||
        artistLower.contains('arctic monkeys') ||
        artistLower.contains('the neighbourhood') ||
        artistLower.contains('alec benjamin') ||
        artistLower.contains('conan gray') ||
        artistLower.contains('laufey') ||
        artistLower.contains('tom odell') ||
        artistLower.contains('james arthur') ||
        artistLower.contains('lewis capaldi') ||
        artistLower.contains('dean lewis') ||
        artistLower.contains('calum scott') ||
        artistLower.contains('ruth b.') ||
        artistLower.contains('lord huron') ||
        artistLower.contains('hozier') ||
        artistLower.contains('avicii') ||
        artistLower.contains('david guetta') ||
        artistLower.contains('calvin harris') ||
        artistLower.contains('martin garrix') ||
        artistLower.contains('kygo') ||
        artistLower.contains('sam smith') ||
        artistLower.contains('glass animals') ||
        artistLower.contains('the kid laroi') ||
        artistLower.contains('chappell roan') ||
        artistLower.contains('tate mcrae') ||
        artistLower.contains('pitbull') ||
        artistLower.contains('teddy swims') ||
        artistLower.contains('noah kahan') ||
        artistLower.contains('shaboozey') ||
        artistLower.contains('tommy richman') ||
        artistLower.contains('artemas') ||
        artistLower.contains('myles smith') ||
        artistLower.contains('david kushner') ||
        artistLower.contains('alex warren') ||
        artistLower.contains('djo') ||
        artistLower.contains('mark ambor') ||
        artistLower.contains('zach bryan') ||
        artistLower.contains('gracie abrams') ||
        artistLower.contains('luke combs') ||
        artistLower.contains('morgan wallen') ||
        artistLower.contains('linkin park') ||
        artistLower.contains('green day') ||
        artistLower.contains('twenty one pilots') ||
        artistLower.contains('21 pilots') ||
        artistLower.contains('passenger') ||
        artistLower.contains('kodaline') ||
        artistLower.contains('vance joy') ||
        artistLower.contains('dj snake') ||
        artistLower.contains('major lazer') ||
        artistLower.contains('swedish house mafia') ||
        artistLower.contains('fred again') ||
        artistLower.contains('akon');

    if (isEnglishArtist && !hasHindiWords) {
      return 'English';
    }

    // 7. English Metadata or Specific English Title Words
    if (langLower.contains('english') ||
        langLower.contains('western') ||
        genreLower.contains('english') ||
        albumLower.contains('english') ||
        albumLower.contains('billboard') ||
        albumLower.contains('hollywood')) {
      return 'English';
    }

    // Check specific English track titles
    if (titleLower == 'blush' ||
        titleLower == 'co2' ||
        titleLower == 'stay' ||
        titleLower == 'starboy' ||
        titleLower == 'believer' ||
        titleLower == 'heat waves' ||
        titleLower == 'blinding lights' ||
        titleLower == 'shape of you' ||
        titleLower == 'bad guy' ||
        titleLower == 'levitating' ||
        titleLower == 'alone' ||
        titleLower == 'faded' ||
        titleLower == 'counting stars' ||
        titleLower == 'night changes' ||
        titleLower == 'until i found you' ||
        titleLower == 'golden hour' ||
        titleLower == 'espresso' ||
        titleLower == 'please please please' ||
        titleLower == 'birds of a feather' ||
        titleLower == 'beautiful things' ||
        titleLower == 'die with a smile' ||
        titleLower == 'ocean' ||
        titleLower.contains('mess') ||
        titleLower.contains('doll') ||
        titleLower.contains('unicorn') ||
        titleLower.contains('pink blue') ||
        titleLower.contains('when we feel young') ||
        titleLower.contains('big dawgs')) {
      return 'English';
    }

    // 8. English Vocabulary & Token Check (when title contains English words and NO Hindi words)
    final bool hasEnglishWords =
        titleLower.contains('love') ||
        titleLower.contains('baby') ||
        titleLower.contains('night') ||
        titleLower.contains('heart') ||
        titleLower.contains('stay') ||
        titleLower.contains('alone') ||
        titleLower.contains('dance') ||
        titleLower.contains('song') ||
        titleLower.contains('eyes') ||
        titleLower.contains('tears') ||
        titleLower.contains('hold') ||
        titleLower.contains('rain') ||
        titleLower.contains('dream') ||
        titleLower.contains('world') ||
        titleLower.contains('forever') ||
        titleLower.contains('never') ||
        titleLower.contains('always') ||
        titleLower.contains('goodbye') ||
        titleLower.contains('hello') ||
        titleLower.contains('light') ||
        titleLower.contains('fire') ||
        titleLower.contains('cold') ||
        titleLower.contains('mess') ||
        titleLower.contains('words') ||
        titleLower.contains('movie') ||
        titleLower.contains('pause') ||
        titleLower.contains('need') ||
        titleLower.contains('kiss') ||
        titleLower.contains('touch') ||
        titleLower.contains('stop') ||
        titleLower.contains('beautiful') ||
        titleLower.contains('sweet') ||
        titleLower.contains('crazy') ||
        titleLower.contains('wild') ||
        titleLower.contains('young') ||
        titleLower.contains('summer') ||
        titleLower.contains('just like') ||
        titleLower.contains('with you') ||
        titleLower.contains('for you') ||
        titleLower.contains('all i need') ||
        titleLower.contains('into the') ||
        titleLower.contains('apart') ||
        titleLower.contains('favourite') ||
        titleLower.contains('favorite') ||
        titleLower.contains('peeps') ||
        titleLower.contains('memories') ||
        titleLower.contains('feelings');

    const commonEnglishTokens = {
      'the',
      'a',
      'an',
      'i',
      'you',
      'me',
      'my',
      'he',
      'she',
      'it',
      'we',
      'they',
      'us',
      'them',
      'him',
      'her',
      'his',
      'its',
      'our',
      'their',
      'mine',
      'yours',
      'ours',
      'theirs',
      'myself',
      'yourself',
      'who',
      'whom',
      'whose',
      'which',
      'what',
      'this',
      'that',
      'these',
      'those',
      'somebody',
      'someone',
      'something',
      'anybody',
      'anyone',
      'anything',
      'nobody',
      'nothing',
      'everybody',
      'everyone',
      'everything',
      'in',
      'on',
      'at',
      'to',
      'for',
      'with',
      'by',
      'from',
      'up',
      'about',
      'into',
      'over',
      'after',
      'under',
      'above',
      'through',
      'between',
      'before',
      'against',
      'out',
      'off',
      'down',
      'around',
      'without',
      'and',
      'but',
      'or',
      'nor',
      'so',
      'yet',
      'because',
      'if',
      'is',
      'am',
      'are',
      'was',
      'were',
      'be',
      'been',
      'being',
      'have',
      'has',
      'had',
      'do',
      'does',
      'did',
      'done',
      'can',
      'could',
      'will',
      'would',
      'shall',
      'should',
      'may',
      'might',
      'must',
      'get',
      'got',
      'make',
      'know',
      'think',
      'take',
      'see',
      'want',
      'look',
      'find',
      'give',
      'tell',
      'feel',
      'leave',
      'put',
      'keep',
      'let',
      'talk',
      'hear',
      'play',
      'run',
      'like',
      'live',
      'believe',
      'hold',
      'bring',
      'happen',
      'stand',
      'lose',
      'meet',
      'watch',
      'stop',
      'speak',
      'read',
      'spend',
      'grow',
      'open',
      'walk',
      'win',
      'love',
      'die',
      'stay',
      'fall',
      'time',
      'year',
      'people',
      'way',
      'day',
      'man',
      'woman',
      'life',
      'child',
      'world',
      'school',
      'hand',
      'part',
      'place',
      'night',
      'home',
      'water',
      'eye',
      'word',
      'head',
      'house',
      'friend',
      'hour',
      'game',
      'line',
      'end',
      'city',
      'name',
      'minute',
      'idea',
      'body',
      'face',
      'party',
      'morning',
      'girl',
      'guy',
      'moment',
      'boy',
      'baby',
      'song',
      'music',
      'dream',
      'heart',
      'soul',
      'sky',
      'sun',
      'moon',
      'star',
      'stars',
      'rain',
      'tears',
      'smile',
      'kiss',
      'touch',
      'fire',
      'ice',
      'cold',
      'dark',
      'light',
      'shadow',
      'ocean',
      'waves',
      'sea',
      'river',
      'road',
      'street',
      'summer',
      'winter',
      'spring',
      'good',
      'new',
      'first',
      'last',
      'long',
      'great',
      'little',
      'own',
      'other',
      'old',
      'right',
      'big',
      'high',
      'different',
      'small',
      'large',
      'next',
      'early',
      'young',
      'bad',
      'same',
      'sweet',
      'beautiful',
      'crazy',
      'wild',
      'happy',
      'sad',
      'lonely',
      'alone',
      'perfect',
      'better',
      'best',
      'broken',
      'blind',
      'golden',
      'deep',
      'free',
      'alive',
      'true',
      'lost',
      'found',
      'taste',
      'casual',
      'luck',
      'babe',
      'control',
      'door',
      'dreams',
      'stargazing',
      'daylight',
      'carry',
      'bar',
      'tipsy',
      'help',
      'skies',
      'sorry',
      'trouble',
      'troubles',
      'heaven',
      'hell',
      'angels',
      'devil',
      'money',
      'rich',
      'poor',
      'gold',
      'silver',
      'diamond',
      'diamonds',
      'ring',
      'secret',
      'secrets',
      'breath',
      'breathe',
      'burn',
      'burning',
      'shadows',
      'magic',
      'miracle',
      'gravity',
      'electric',
      'radio',
      'weekend',
      'holiday',
      'christmas',
      'sunday',
      'monday',
      'friday',
      'saturday',
      'acoustic',
      'unplugged',
      'remix',
      'edit',
      'version',
      'cover',
      'single',
      'album',
      'words',
      'movie',
      'pause',
      'need',
      'mess',
      'loving',
      'fade',
      'faded',
      'starboy',
      'believer',
      'shape',
      'habits',
      'attention',
      'ghost',
      'peaches',
      'dynamite',
      'butter',
      'levitating',
      'flowers',
      'greedy',
      'vampire',
      'cruel',
      'cardigan',
      'style',
      'blank',
      'space',
      'lover',
      'karma',
      'espresso',
      'birds',
      'feather',
      'breeze',
      'shore',
      'track',
      'tracks',
      'isolated',
      'instrumental',
      'soundtrack',
      'score',
    };

    final bool hasEnglishToken = titleTokens.any(commonEnglishTokens.contains);

    // If title contains clear English vocabulary/tokens and zero Hindi phonetic words,
    // it IS English (even if sung by an Indian artist like Prateek Kuhad, Hanumankind, etc.)
    if ((hasEnglishWords || hasEnglishToken) && !hasHindiWords) {
      return 'English';
    }

    // Indian Artist Signatures
    final bool isIndianArtist =
        artistLower.contains('arijit') ||
        artistLower.contains('kishore kumar') ||
        artistLower.contains('lata mangeshkar') ||
        artistLower.contains('mohammed rafi') ||
        artistLower.contains('mohd rafi') ||
        artistLower.contains('mukesh') ||
        artistLower.contains('asha bhosle') ||
        artistLower.contains('kumar sanu') ||
        artistLower.contains('alka yagnik') ||
        artistLower.contains('udit narayan') ||
        artistLower.contains('sonu nigam') ||
        artistLower.contains('shaan') ||
        artistLower.contains('kk') ||
        artistLower.contains('mohit chauhan') ||
        artistLower.contains('lucky ali') ||
        artistLower.contains('sunidhi') ||
        artistLower.contains('shreya ghoshal') ||
        artistLower.contains('neha kakkar') ||
        artistLower.contains('jubin') ||
        artistLower.contains('armaan malik') ||
        artistLower.contains('amaal mallik') ||
        artistLower.contains('vishal mishra') ||
        artistLower.contains('stebin ben') ||
        artistLower.contains('darshan raval') ||
        artistLower.contains('anuv jain') ||
        artistLower.contains('prateek kuhad') ||
        artistLower.contains('mitraz') ||
        artistLower.contains('jasleen royal') ||
        artistLower.contains('kaifi khalil') ||
        artistLower.contains('faheem abdullah') ||
        artistLower.contains('aditya a') ||
        artistLower.contains('king') ||
        artistLower.contains('divine') ||
        artistLower.contains('emiway') ||
        artistLower.contains('mc stan') ||
        artistLower.contains('raftaar') ||
        artistLower.contains('kr\$na') ||
        artistLower.contains('seedhe maut') ||
        artistLower.contains('bappi lahiri') ||
        artistLower.contains('amit kumar') ||
        artistLower.contains('shabbir kumar') ||
        artistLower.contains('anuradha paudwal') ||
        artistLower.contains('sadhana sargam') ||
        artistLower.contains('kavita krishnamurthy') ||
        artistLower.contains('abhijeet') ||
        artistLower.contains('pankaj udhas') ||
        artistLower.contains('himesh reshammiya') ||
        artistLower.contains('kailash kher') ||
        artistLower.contains('adnan sami') ||
        artistLower.contains('kunal ganjawala') ||
        artistLower.contains('zubeen garg') ||
        artistLower.contains('mustafa zahid') ||
        artistLower.contains('atif aslam') ||
        artistLower.contains('badshah') ||
        artistLower.contains('honey singh') ||
        artistLower.contains('pritam') ||
        artistLower.contains('sachin-jigar') ||
        artistLower.contains('mithoon') ||
        artistLower.contains('vishal-shekhar') ||
        artistLower.contains('shankar-ehsaan-loy') ||
        artistLower.contains('amit trivedi') ||
        artistLower.contains('ajay-atul') ||
        artistLower.contains('tanishk bagchi') ||
        artistLower.contains('rochak kohli') ||
        artistLower.contains('meet bros') ||
        artistLower.contains('tony kakkar') ||
        artistLower.contains('dhvani bhanushali') ||
        artistLower.contains('tulsi kumar') ||
        artistLower.contains('palak muchhal') ||
        artistLower.contains('monali thakur') ||
        artistLower.contains('shilpa rao') ||
        artistLower.contains('neeti mohan') ||
        artistLower.contains('jonita gandhi') ||
        artistLower.contains('jagjit singh') ||
        artistLower.contains('ghulam ali') ||
        artistLower.contains('s. d. burman') ||
        artistLower.contains('r. d. burman') ||
        artistLower.contains('manna dey') ||
        artistLower.contains('hemant kumar') ||
        artistLower.contains('a. r. rahman') ||
        artistLower.contains('ar rahman');

    if (isIndianArtist) {
      return 'Hindi';
    }

    if (langLower.contains('hindi') && !hasEnglishWords && !hasEnglishToken) {
      return 'Hindi';
    }

    // Default: If track has NO Indian artist, NO Indic phonetic tokens, and NO Hindi metadata,
    // it is an English/Western track. Defaulting to 'Hindi' causes cross-language queue pollution.
    return 'English';
  }

  /// Detects language of a song (Hindi, Punjabi, South, English, Bhojpuri, Haryanvi)
  static String detectSongLanguage(Song song) {
    return detectTextLanguage(
      title: song.title,
      artist: song.artist,
      album: song.album,
      genre: song.genre,
      rawLanguage: song.language,
      audioUrl: song.audioUrl,
      id: song.id,
    );
  }

  /// Extracts the genuine release year from releaseYear field, title, or album.
  static int? extractReleaseYear(Song song) {
    final yearRegex = RegExp(r'\b(19\d{2}|20\d{2})\b');
    final titleMatch = yearRegex.firstMatch(song.title);
    if (titleMatch != null) {
      final y = int.tryParse(titleMatch.group(1)!);
      if (y != null && y >= 1940 && y <= DateTime.now().year + 1) return y;
    }

    final albumMatch = yearRegex.firstMatch(song.album);
    if (albumMatch != null) {
      final y = int.tryParse(albumMatch.group(1)!);
      if (y != null && y >= 1940 && y <= DateTime.now().year + 1) return y;
    }

    final direct = int.tryParse(song.releaseYear.trim());
    if (direct != null && direct >= 1940 && direct <= DateTime.now().year + 1) {
      return direct;
    }

    return null;
  }

  /// Detects the musical era of a song (70s, 80s, 90s, 2000s, 2010s, Gen Z/Modern)
  static MusicEra detectSongEra(Song song) {
    if (isVintageGoldenEra(song)) return MusicEra.vintage70s;
    if (is80sEra(song)) return MusicEra.era80s;
    if (is90sMelodyEra(song)) return MusicEra.era90s;
    if (is2000sSong(song)) return MusicEra.era2000s;
    if (is2010sSong(song)) return MusicEra.era2010s;
    if (isGenZModern(song)) return MusicEra.genZModern;

    final year = extractReleaseYear(song);
    if (year != null) {
      if (year < 1980) return MusicEra.vintage70s;
      if (year < 1990) return MusicEra.era80s;
      if (year < 2000) return MusicEra.era90s;
      if (year < 2010) return MusicEra.era2000s;
      if (year < 2020) return MusicEra.era2010s;
      return MusicEra.genZModern;
    }

    return MusicEra.genZModern;
  }

  /// Checks if a song belongs to the 1950s - 1970s Vintage Golden Era
  static bool isVintageGoldenEra(Song song) {
    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    // 1. Exclusive Vintage Legends (1950s - 1970s)
    // These legends NEVER sang Gen Z or modern tracks; they are permanently Vintage Golden Era
    // regardless of compilation or remaster album release years (e.g. 2020 - 2026).
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
        artistLower.contains('op nayyar') ||
        artistLower.contains('salil chowdhury') ||
        artistLower.contains('khayyam') ||
        artistLower.contains('roshan');

    if (isClassicSinger) {
      return true;
    }

    final year = extractReleaseYear(song);
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
        albumLower.contains('bobby') ||
        albumLower.contains('deewaar') ||
        albumLower.contains('padosan') ||
        albumLower.contains('yaadon ki baaraat') ||
        albumLower.contains('chupke chupke') ||
        albumLower.contains('caravan') ||
        albumLower.contains('teesri manzil') ||
        albumLower.contains('kashmir ki kali') ||
        albumLower.contains('hare rama hare krishna') ||
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
        titleLower.contains('ek ajnabee haseena') ||
        titleLower.contains('ye shaam mastani') ||
        titleLower.contains('hothon se chhu lo') ||
        titleLower.contains('yeh dosti') ||
        titleLower.contains('o mere dil ke chain') ||
        titleLower.contains('kya hua tera wada') ||
        titleLower.contains('baharon phool barsao') ||
        titleLower.contains('jeena yahan')) {
      return true;
    }

    // Lata Mangeshkar / Asha Bhosle vintage check
    // If Lata/Asha and not accompanied by 90s/2000s singers or films
    if ((artistLower.contains('lata mangeshkar') ||
            artistLower.contains('asha bhosle')) &&
        !artistLower.contains('kumar sanu') &&
        !artistLower.contains('udit narayan') &&
        !artistLower.contains('sonu nigam') &&
        !artistLower.contains('arijit') &&
        !artistLower.contains('shabbir kumar') &&
        !artistLower.contains('bappi') &&
        !titleLower.contains('dil to pagal hai') &&
        !titleLower.contains('tujhe dekha to') &&
        !titleLower.contains('andekhi anjaani') &&
        !titleLower.contains('humko humise') &&
        !titleLower.contains('tere liye') &&
        !titleLower.contains('kabhi khushi') &&
        !titleLower.contains('zubi zubi') &&
        !titleLower.contains('radha kaise na jale') &&
        !titleLower.contains('didi tera devar')) {
      return true;
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

    // Invariable 80s Artists & Films
    final is80sIcon =
        artistLower.contains('bappi lahiri') ||
        artistLower.contains('amit kumar') ||
        artistLower.contains('shabbir kumar') ||
        artistLower.contains('mohammed aziz') ||
        artistLower.contains('mohd aziz') ||
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
        albumLower.contains('dance dance') ||
        albumLower.contains('kasam paida karne wale ki') ||
        titleLower.contains('i am a disco dancer') ||
        titleLower.contains('jimmy jimmy') ||
        titleLower.contains('ek do teen') ||
        titleLower.contains('mere haathon mein') ||
        titleLower.contains('papa kehte hain') ||
        titleLower.contains('gazab ka hai din') ||
        titleLower.contains('hawa hawai') ||
        titleLower.contains('dil deewana') ||
        titleLower.contains('kabootar ja ja') ||
        titleLower.contains('so gaya yeh jahan');

    if (is80sIcon) {
      return true;
    }

    final year = extractReleaseYear(song);
    if (year != null && year >= 1980 && year < 1990) {
      return true;
    }

    return genreLower.contains('80s');
  }

  /// Checks if a song belongs to the 1990s Melodies Era (Kumar Sanu, Alka Yagnik, Udit Narayan, DDLJ, Saajan)
  static bool is90sMelodyEra(Song song) {
    if (isVintageGoldenEra(song) || is80sEra(song)) return false;

    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    // Do not misclassify 2010s / Gen Z releases (e.g. Aashiqui 2 vs 1990 Aashiqui)
    if (albumLower.contains('aashiqui 2') ||
        albumLower.contains('aashiqui-2') ||
        titleLower.contains('tum hi ho') ||
        titleLower.contains('sunn raha hai') ||
        artistLower.contains('arijit') ||
        artistLower.contains('anuv jain') ||
        artistLower.contains('prateek kuhad') ||
        artistLower.contains('karan aujla') ||
        artistLower.contains('ap dhillon') ||
        artistLower.contains('badshah')) {
      return false;
    }

    // Invariable 90s Artists & Films (Even if compilation year says 2021/2023)
    final is90sIcon =
        artistLower.contains('kumar sanu') ||
        artistLower.contains('alka yagnik') ||
        artistLower.contains('udit narayan') ||
        artistLower.contains('anuradha paudwal') ||
        artistLower.contains('sadhana sargam') ||
        artistLower.contains('kavita krishnamurthy') ||
        artistLower.contains('abhijeet') ||
        artistLower.contains('pankaj udhas') ||
        artistLower.contains('roop kumar rathod') ||
        artistLower.contains('vinod rathod') ||
        artistLower.contains('nadeem-shravan') ||
        artistLower.contains('nadeem shravan') ||
        artistLower.contains('jatin-lalit') ||
        artistLower.contains('jatin lalit') ||
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
        albumLower.contains('dilwale dulhania') ||
        albumLower.contains('hum dil de chuke sanam') ||
        albumLower.contains('taal') ||
        albumLower.contains('karan arjun') ||
        albumLower.contains('deewana') ||
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
        titleLower.contains('sandese aate hai') ||
        titleLower.contains('didi tera devar') ||
        titleLower.contains('mera dil bhi kitna pagal') ||
        titleLower.contains('bahut pyar karte hain') ||
        titleLower.contains('dheere dheere se meri') ||
        titleLower.contains('pehla nasha') ||
        titleLower.contains('jaati hoon main');

    if (is90sIcon) {
      return true;
    }

    final year = extractReleaseYear(song);
    if (year != null && year >= 1990 && year < 2000) {
      return true;
    }

    return genreLower.contains('90s');
  }

  /// Checks if a song belongs to the 2000s - 2009 Bollywood Soulful / Emraan Hashmi Era / KK
  static bool is2000sSong(Song song) {
    if (isVintageGoldenEra(song) || is80sEra(song) || is90sMelodyEra(song)) {
      return false;
    }

    final artistLower = song.artist.toLowerCase();
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();

    // Do not misclassify 2010s / Gen Z releases
    if (albumLower.contains('aashiqui 2') ||
        albumLower.contains('kabir singh') ||
        albumLower.contains('agneepath') ||
        titleLower.contains('abhi mujh mein kahin') ||
        artistLower.contains('anuv jain') ||
        artistLower.contains('karan aujla') ||
        artistLower.contains('ap dhillon') ||
        artistLower.contains('shubh') ||
        artistLower.contains('arijit')) {
      return false;
    }

    // Invariable 2000s Artists & Iconic Films
    final is2000sIcon =
        artistLower.contains('kk') ||
        artistLower.contains('krishnakumar') ||
        artistLower.contains('sonu nigam') ||
        artistLower.contains('sonu nigum') ||
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
        artistLower.contains('euphoria') ||
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
        albumLower.contains('zeher') ||
        albumLower.contains('kalyug') ||
        albumLower.contains('life in a metro') ||
        albumLower.contains('rang de basanti') ||
        albumLower.contains('dil chahta hai') ||
        albumLower.contains('lagaan') ||
        albumLower.contains('kabhi khushi kabhie gham') ||
        albumLower.contains('rehnaa hai terre dil mein') ||
        albumLower.contains('saathiya') ||
        albumLower.contains('dhoom') ||
        albumLower.contains('omkara') ||
        albumLower.contains('guru') ||
        albumLower.contains('chak de india') ||
        albumLower.contains('taare zameen par') ||
        albumLower.contains('bhool bhulaiyaa') ||
        albumLower.contains('race') ||
        albumLower.contains('jaane tu ya jaane na') ||
        albumLower.contains('ghajini') ||
        albumLower.contains('rab ne bana di jodi') ||
        albumLower.contains('3 idiots') ||
        albumLower.contains('krrish') ||
        albumLower.contains('om shanti om') ||
        albumLower.contains('kabhi alvida naa kehna') ||
        albumLower.contains('mujhse shaadi karogi') ||
        albumLower.contains('namastey london') ||
        albumLower.contains('parineeta') ||
        titleLower.contains('woh lamhe') ||
        titleLower.contains('tu hi meri shab') ||
        titleLower.contains('labon ko') ||
        titleLower.contains('kya mujhe pyar hai') ||
        titleLower.contains('zara sa') ||
        titleLower.contains('peehloon') ||
        titleLower.contains('pee loon') ||
        titleLower.contains('mitwa') ||
        titleLower.contains('alvida') ||
        titleLower.contains('aadat') ||
        titleLower.contains('dil ibaadat') ||
        titleLower.contains('beete lamhein') ||
        titleLower.contains('tu aashiqui hai') ||
        titleLower.contains('o sanam') ||
        titleLower.contains('maeri') ||
        titleLower.contains('teri deewani') ||
        titleLower.contains('suraj hua maddham') ||
        titleLower.contains('kal ho naa ho') ||
        titleLower.contains('main hoon na') ||
        titleLower.contains('tumse milke dil ka') ||
        titleLower.contains('sau dard') ||
        titleLower.contains('tanhayee') ||
        titleLower.contains('soniyo') ||
        titleLower.contains('do pal') ||
        titleLower.contains('kabhi alvida naa kehna') ||
        titleLower.contains('jane nahin denge tujhe') ||
        titleLower.contains('shukran allah') ||
        titleLower.contains('main agar kahoon') ||
        titleLower.contains('tumhi dekho naa') ||
        titleLower.contains('ab mujhe raat din') ||
        titleLower.contains('deewana tera') ||
        titleLower.contains('saathiya');

    if (is2000sIcon) {
      return true;
    }

    final year = extractReleaseYear(song);
    if (year != null && year >= 2000 && year < 2010) {
      return true;
    }

    return false;
  }

  /// Helper to identify 2020+ modern / Gen Z releases by Arijit Singh
  static bool isArijitGenZModern(Song song) {
    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();

    if (albumLower.contains('animal') ||
        albumLower.contains('dunki') ||
        albumLower.contains('jawan') ||
        albumLower.contains('pathaan') ||
        albumLower.contains('stree 2') ||
        albumLower.contains('stree-2') ||
        albumLower.contains('brahmastra') ||
        albumLower.contains('rocky aur rani') ||
        albumLower.contains('fighter') ||
        albumLower.contains('tu jhoothi main makkaar') ||
        albumLower.contains('chandu champion') ||
        albumLower.contains('bhool bhulaiyaa 3') ||
        albumLower.contains('bhediya') ||
        albumLower.contains('shershaah') ||
        albumLower.contains('chhatrapati') ||
        albumLower.contains('zara hatke zara bachke')) {
      return true;
    }

    if (titleLower.contains('satranga') ||
        titleLower.contains('pehle bhi main') ||
        titleLower.contains('o maahi') ||
        titleLower.contains('lutt putt gaya') ||
        titleLower.contains('chal kudiye') ||
        titleLower.contains('chaleya') ||
        titleLower.contains('kesariya') ||
        titleLower.contains('deva deva') ||
        titleLower.contains('tere pyaar mein') ||
        titleLower.contains('pyaar hota kayi baar hai') ||
        titleLower.contains('khoobsurat') ||
        titleLower.contains('tum kya mile') ||
        titleLower.contains('ve kamleya') ||
        titleLower.contains('what jhumka') ||
        titleLower.contains('sajni') ||
        titleLower.contains('heer aasmani') ||
        titleLower.contains('apna bana le') ||
        titleLower.contains('phir aur kya chahiye') ||
        titleLower.contains('tere vaaste')) {
      return true;
    }

    final year = extractReleaseYear(song);
    return year != null && year >= 2020;
  }

  /// Checks if a song belongs to the 2010s (2010 - 2019) Arijit Singh / Modern Romantic Era
  static bool is2010sSong(Song song) {
    if (isVintageGoldenEra(song) ||
        is80sEra(song) ||
        is90sMelodyEra(song) ||
        is2000sSong(song)) {
      return false;
    }

    final titleLower = song.title.toLowerCase();
    final albumLower = song.album.toLowerCase();
    final artistLower = song.artist.toLowerCase();

    // 1. "Ocean" by Anuv Jain is strictly a 2010s English acoustic masterpiece (2016-2018)
    if ((titleLower == 'ocean' || titleLower.contains('ocean')) &&
        artistLower.contains('anuv jain')) {
      return true;
    }

    // Modern 2020+ releases cannot be 2010s
    final year = extractReleaseYear(song);
    if (year != null && year >= 2020) {
      return false;
    }

    // 2. Arijit Singh's primary defining musical era is 2010s Bollywood soulful romance
    if (artistLower.contains('arijit') && !isArijitGenZModern(song)) {
      return true;
    }

    // 3. Iconic 2010s English tracks
    if (isEnglishSong(song)) {
      if (titleLower == 'shape of you' ||
          titleLower == 'someone like you' ||
          titleLower == 'rolling in the deep' ||
          titleLower == 'thinking out loud' ||
          titleLower == 'perfect' ||
          titleLower == 'closer' ||
          titleLower == 'see you again' ||
          titleLower == 'counting stars' ||
          titleLower == 'sugar' ||
          titleLower == 'radioactive' ||
          titleLower == 'bad guy' ||
          titleLower == 'all of me' ||
          titleLower == 'love yourself' ||
          titleLower == 'sorry' ||
          titleLower == 'roar' ||
          titleLower == 'blank space' ||
          titleLower == 'shake it off' ||
          titleLower == 'starboy' ||
          titleLower == 'believer' ||
          titleLower == 'night changes' ||
          titleLower == 'let her go' ||
          titleLower == "say you won't let go" ||
          titleLower == 'photograph' ||
          titleLower == 'demons' ||
          titleLower == 'stitches' ||
          titleLower == 'treat you better' ||
          titleLower == 'ocean') {
        return true;
      }
    }

    // 4. Iconic 2010s Albums, Titles & Artists
    if (albumLower.contains('aashiqui 2') ||
        albumLower.contains('kabir singh') ||
        albumLower.contains('yeh jawaani hai deewani') ||
        albumLower.contains('rockstar') ||
        albumLower.contains('sanam re') ||
        albumLower.contains('ae dil hai mushkil') ||
        albumLower.contains('raabta') ||
        albumLower.contains('barfi') ||
        albumLower.contains('cocktail') ||
        albumLower.contains('half girlfriend') ||
        albumLower.contains('kalank') ||
        albumLower.contains('kedarnath') ||
        albumLower.contains('dangal') ||
        albumLower.contains('sultan') ||
        albumLower.contains('bajrangi bhaijaan') ||
        albumLower.contains('padmaavat') ||
        albumLower.contains('gully boy') ||
        albumLower.contains('war') ||
        albumLower.contains('agneepath') ||
        albumLower.contains('tamasha') ||
        albumLower.contains('raazi') ||
        albumLower.contains('ek villain') ||
        albumLower.contains('kesari') ||
        albumLower.contains('highway') ||
        albumLower.contains('fukrey') ||
        albumLower.contains('roy') ||
        albumLower.contains('dilwale') ||
        albumLower.contains('hamari adhuri kahani') ||
        albumLower.contains('ms dhoni') ||
        albumLower.contains('m.s. dhoni') ||
        artistLower.contains('ankit tiwari') ||
        artistLower.contains('armaan malik') ||
        artistLower.contains('jubin nautiyal') ||
        titleLower.contains('tum hi ho') ||
        titleLower.contains('channa mereya') ||
        titleLower.contains('gerua') ||
        titleLower.contains('bekhayali') ||
        titleLower.contains('tujhe kitna chahne lage') ||
        titleLower.contains('shayad') ||
        titleLower.contains('hawayein') ||
        titleLower.contains('kabira') ||
        titleLower.contains('ilahi') ||
        titleLower.contains('sunn raha hai') ||
        titleLower.contains('galliyan') ||
        titleLower.contains('humnava mere') ||
        titleLower.contains('abhi mujh mein kahin') ||
        titleLower.contains('tera yaar hoon main') ||
        titleLower.contains('soch na sake') ||
        titleLower.contains('en na sona') ||
        titleLower.contains('enna sona') ||
        titleLower.contains('phir bhi tumko chahunga') ||
        titleLower.contains('muskurane') ||
        titleLower.contains('sun saathiya') ||
        titleLower.contains('banjaara') ||
        titleLower.contains('zaalima') ||
        titleLower.contains('naina') ||
        titleLower.contains('laal ishq') ||
        titleLower.contains('mast magan') ||
        titleLower.contains('khairiyat') ||
        titleLower.contains('ghungroo') ||
        titleLower.contains('subhanallah') ||
        titleLower.contains('badtameez dil') ||
        titleLower.contains('balam pichkari') ||
        titleLower.contains('agar tum saath ho') ||
        titleLower.contains('matargashti') ||
        titleLower.contains('safarnama') ||
        titleLower.contains('samjhawan') ||
        titleLower.contains('ishq wala love') ||
        titleLower.contains('radha') ||
        titleLower.contains('meherbaan') ||
        titleLower.contains('tu chahiye') ||
        titleLower.contains('bol do na zara')) {
      return true;
    }

    if (year != null && year >= 2010 && year < 2020) {
      return true;
    }

    return false;
  }

  /// Checks if a song belongs to Indie / Acoustic / Sukoon
  static bool isIndieOrSukoonSong(Song song) {
    final titleLower = song.title.toLowerCase();
    final artistLower = song.artist.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    // "Ocean" by Anuv Jain is strictly 2010s English acoustic, NOT Gen Z modern indie
    if ((titleLower == 'ocean' || titleLower.contains('ocean')) &&
        artistLower.contains('anuv jain')) {
      return false;
    }

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

  /// Checks if a song belongs to Gen Z / Contemporary Hits (2020 - Present)
  static bool isGenZModern(Song song) {
    final titleLower = song.title.toLowerCase();
    final artistLower = song.artist.toLowerCase();

    // "Ocean" by Anuv Jain is strictly 2010s English acoustic, NOT Gen Z modern
    if ((titleLower == 'ocean' || titleLower.contains('ocean')) &&
        artistLower.contains('anuv jain')) {
      return false;
    }

    if (isVintageGoldenEra(song) ||
        is80sEra(song) ||
        is90sMelodyEra(song) ||
        is2000sSong(song) ||
        is2010sSong(song)) {
      return false;
    }

    final albumLower = song.album.toLowerCase();
    final genreLower = song.genre.toLowerCase();

    // Gen Z Indie / Sukoon / Lofi
    if (isIndieOrSukoonSong(song)) return true;

    // Gen Z Modern Punjabi / Hip-Hop
    if (artistLower.contains('karan aujla') ||
        artistLower.contains('ap dhillon') ||
        artistLower.contains('shubh') ||
        artistLower.contains('talwiinder') ||
        artistLower.contains('hanumankind') ||
        artistLower.contains('king') ||
        artistLower.contains('mc stan') ||
        artistLower.contains('seedhe maut') ||
        artistLower.contains('divine') ||
        artistLower.contains('raftaar') ||
        artistLower.contains('jordan sandhu') ||
        artistLower.contains('arjan dhillon')) {
      return true;
    }

    // Modern Bollywood / Contemporary independent releases (2020+)
    if (artistLower.contains('stebin ben') ||
        artistLower.contains('darshan raval') ||
        artistLower.contains('vishal mishra') ||
        titleLower.contains('husn') ||
        titleLower.contains('alag aasmaan') ||
        titleLower.contains('baarishein') ||
        titleLower.contains('kasoor') ||
        titleLower.contains('gul') ||
        titleLower.contains('co2') ||
        titleLower.contains('tu aake dekhle') ||
        titleLower.contains('maan meri jaan') ||
        titleLower.contains('kahani suno') ||
        titleLower.contains('big dawgs') ||
        titleLower.contains('brown munde') ||
        titleLower.contains('excuses') ||
        titleLower.contains('insane') ||
        titleLower.contains('cheques') ||
        titleLower.contains('one love') ||
        titleLower.contains('softly') ||
        titleLower.contains('tauba tauba') ||
        titleLower.contains('winning speech') ||
        titleLower.contains('pehle bhi main') ||
        titleLower.contains('satranga') ||
        titleLower.contains('o maahi') ||
        titleLower.contains('chal kudiye') ||
        titleLower.contains('viral') ||
        albumLower.contains('animal') ||
        albumLower.contains('dunki') ||
        albumLower.contains('jawan') ||
        albumLower.contains('pathaan') ||
        albumLower.contains('stree 2') ||
        albumLower.contains('shershaah') ||
        albumLower.contains('brahmastra') ||
        albumLower.contains('rocky aur rani') ||
        albumLower.contains('fighter') ||
        albumLower.contains('amar singh chamkila') ||
        genreLower.contains('gen z') ||
        genreLower.contains('reels') ||
        genreLower.contains('viral')) {
      return true;
    }

    // Global / K-Pop
    if (artistLower.contains('bts') ||
        artistLower.contains('jungkook') ||
        artistLower.contains('blackpink') ||
        artistLower.contains('newjeans') ||
        artistLower.contains('billie eilish') ||
        artistLower.contains('olivia rodrigo') ||
        artistLower.contains('dua lipa') ||
        artistLower.contains('sabrina carpenter') ||
        artistLower.contains('benson boone') ||
        artistLower.contains('chappell roan') ||
        artistLower.contains('tate mcrae')) {
      return true;
    }

    final year = extractReleaseYear(song);
    return year != null && year >= 2020;
  }
}
