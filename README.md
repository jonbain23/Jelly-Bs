# Jelly B's Battle of the Bands

A family story game. The Jelly B's form a band, lead it down the road to each gig (platformer), build skills, gear and management contracts at Band HQ, and battle 10 rival bands in guitar and dance rhythm rounds on the way to Sugar Rush Arena.

## Run locally
Open `index.html` in a browser. Without Supabase keys the game saves on the device only.

## Deploy (Netlify)
Netlify > Add new site > Import from GitHub > pick this repo. No build command; publish directory is the repo root (set in `netlify.toml`).

## Supabase (logins, cloud saves, leaderboard)
1. Create a project at supabase.com.
2. SQL Editor: run `supabase/schema.sql`.
3. Authentication > Providers: Email on. For a family game you can turn off "Confirm email" so new players can sign in straight away.
4. Authentication > URL Configuration: set Site URL to your Netlify address.
5. Project Settings > API: copy the Project URL and anon public key into `config.js`, commit, and Netlify redeploys.

## Controls
Road: arrows or A/D to move, Space to jump, X for special moves (Cola Jack's fizz rocket, Berry Bella's dash), P to pause.
Battles: D F J K or the arrow keys on the beat; Space for Sugar Rush when the meter is full. Touch screens get on-screen buttons and tappable lanes.
