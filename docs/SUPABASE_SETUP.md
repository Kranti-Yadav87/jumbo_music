# Supabase setup (free plan, Hinglish, step-by-step)

Tumhare app mein Supabase pehle se hai: `AppConfig.supabaseEndpoint` ek edge function
`spotify` ko call karta hai (search aur playlists). Is guide mein 3 kaam hain:
0. us function ka backup, 1. project ko pause hone se bachana, 2. lyrics ka shared cache.

Free plan ke limits (2026, third-party guides ke hisaab se, apni dashboard par ek baar verify karo):
500 MB database, 1 GB storage, 5 GB egress, 500,000 edge function calls/month,
aur **7 din inactive rehne par project pause ho jata hai**. Card ki zaroorat nahi.

## STEP 0 - Pehle confirm karo ki project tumhara hai
1. https://supabase.com/dashboard kholo aur login karo.
2. Project list mein ref `uwvsyladvvvjqlgnqppq` wala project dikhna chahiye.
   Na dikhe to ye project kisi aur account ka hai, wahan se kuch deploy nahi kar sakte.
   Tab naya project banao (New project, free) aur app mein `SPOTIFY_ENDPOINT` /
   `SPOTIFY_ANON_KEY` dart-define se naya URL aur key do.

## STEP 1 - CLI install aur login (Terminal)
```bash
brew install supabase/tap/supabase
supabase login
cd ~/projects/jumbo_music
supabase link --project-ref uwvsyladvvvjqlgnqppq
```

## STEP 2 - Maujooda `spotify` function ka backup repo mein
Abhi iska source code repo mein nahi hai, to kho jaye to wapas nahi milega.
```bash
supabase functions download spotify
```
Docker maange to `supabase functions download spotify --use-api` try karo.
Ye `supabase/functions/spotify/` banayega. Use git mein commit kar do. Is function ko
review bhi kar lo: wo kis cheez ko proxy karta hai aur koi secret to hardcoded nahi.

## STEP 3 - Lyrics cache table
Dashboard, SQL Editor, New query mein `supabase/migrations/20261006000000_lyrics_cache.sql`
ka content paste karo aur Run dabao. Table Editor mein `lyrics_cache` dikhni chahiye
(RLS ON, koi policy nahi, matlab sirf edge function isse padh/likh sakta hai).

## STEP 4 - Lyrics function deploy
```bash
supabase functions deploy lyrics
```
Test (anon key dashboard, Project Settings, API se lo):
```bash
curl "https://uwvsyladvvvjqlgnqppq.supabase.co/functions/v1/lyrics?title=Kesariya&artist=Arijit%20Singh&duration=268" \
  -H "Authorization: Bearer <ANON_KEY>" -H "apikey: <ANON_KEY>"
```
Pehli baar `"cached": false`, doosri baar `"cached": true` aana chahiye.
Ye chal jaye to mujhe batao, main app (LyricsService) ko is function se jod dunga
(pehle Supabase, fail ho to seedha LRCLIB).

## STEP 5 - Project ko pause hone se bachao
1. GitHub repo, Settings, Secrets and variables, Actions mein 2 secrets:
   `SUPABASE_URL` = `https://uwvsyladvvvjqlgnqppq.supabase.co`
   `SUPABASE_ANON_KEY` = dashboard wali anon key
2. `.github/workflows/supabase-keepalive.yml` har 3 din mein ek chhoti DB request bhejta hai.
3. Actions tab, "Supabase keep-alive", Run workflow se ek baar test karo (green aana chahiye).
Dhyan: GitHub 60 din repo inactive rehne par scheduled workflows band kar deta hai.
Ye pause rokne ki pakki guarantee nahi hai, bas achhi koshish hai. Dashboard par kabhi
"Project paused" dikhe to Restore dabao.

## Kya Supabase par NAHI karna chahiye
- Auth ya Firestore ka data migrate mat karo. Firebase tumhare liye already free aur kaam kar raha hai.
- Push notification (app band hone par) abhi mat banao: FCM + service account secrets chahiye, complex hai.
