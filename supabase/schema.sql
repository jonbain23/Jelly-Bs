-- Jelly B's Battle of the Bands: run once in Supabase > SQL Editor.

-- One saved tour per player
create table if not exists public.jb_saves (
  user_id uuid primary key references auth.users (id) on delete cascade,
  tour jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.jb_saves enable row level security;
create policy "Players read their own save"   on public.jb_saves for select using (auth.uid() = user_id);
create policy "Players create their own save" on public.jb_saves for insert with check (auth.uid() = user_id);
create policy "Players update their own save" on public.jb_saves for update using (auth.uid() = user_id);

-- Leaderboard: everyone can read, players only write their own row
create table if not exists public.jb_leaderboard (
  user_id uuid primary key references auth.users (id) on delete cascade,
  player_name text not null check (char_length(player_name) <= 20),
  band text not null check (char_length(band) <= 28),
  leader text not null,
  gigs int not null default 0 check (gigs between 0 and 10),
  fans int not null default 0,
  leadership int not null default 0,
  champion boolean not null default false,
  updated_at timestamptz not null default now()
);
alter table public.jb_leaderboard enable row level security;
create policy "Anyone can see the leaderboard" on public.jb_leaderboard for select using (true);
create policy "Players add their own row"      on public.jb_leaderboard for insert with check (auth.uid() = user_id);
create policy "Players update their own row"   on public.jb_leaderboard for update using (auth.uid() = user_id);
create index if not exists jb_leaderboard_rank on public.jb_leaderboard (gigs desc, fans desc);
