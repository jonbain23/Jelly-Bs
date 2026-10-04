-- Jelly B's Battle of the Bands: run all of this in Supabase > SQL Editor. Safe to run again.

-- ===== Invite codes (one-time use) =====
create table if not exists public.jb_invites (
  code text primary key,
  note text,
  created_at timestamptz not null default now(),
  used_by uuid references auth.users (id) on delete set null,
  used_at timestamptz
);
alter table public.jb_invites enable row level security;
-- no policies on jb_invites: players can never read the list of codes

-- ===== Members: people who have redeemed a code =====
create table if not exists public.jb_members (
  user_id uuid primary key references auth.users (id) on delete cascade,
  code text,
  joined_at timestamptz not null default now()
);
alter table public.jb_members enable row level security;
drop policy if exists "Members can see their own membership" on public.jb_members;
create policy "Members can see their own membership" on public.jb_members for select using (auth.uid() = user_id);

-- Check a code before signing up (true if it exists and is unused)
create or replace function public.jb_invite_valid(p_code text) returns boolean
language sql security definer set search_path = public as $$
  select exists (select 1 from public.jb_invites where code = upper(trim(p_code)) and used_by is null);
$$;
revoke all on function public.jb_invite_valid(text) from public;
grant execute on function public.jb_invite_valid(text) to anon, authenticated;

-- Use a code: marks it used by the signed-in player and makes them a member
create or replace function public.jb_redeem_invite(p_code text) returns boolean
language plpgsql security definer set search_path = public as $$
declare uid uuid := auth.uid();
begin
  if uid is null then raise exception 'Sign in first'; end if;
  if exists (select 1 from public.jb_members where user_id = uid) then return true; end if;
  update public.jb_invites set used_by = uid, used_at = now()
    where code = upper(trim(p_code)) and used_by is null;
  if not found then return false; end if;
  insert into public.jb_members (user_id, code) values (uid, upper(trim(p_code)));
  return true;
end $$;
revoke all on function public.jb_redeem_invite(text) from public;
grant execute on function public.jb_redeem_invite(text) to authenticated;

-- Make new codes (only you can run this, here in the SQL Editor)
create or replace function public.jb_make_invites(how_many int, p_note text default null) returns setof text
language plpgsql security definer set search_path = public as $$
declare c text; i int; j int;
begin
  for i in 1..how_many loop
    loop
      c := 'JB-';
      for j in 1..8 loop c := c || substr('ABCDEFGHJKLMNPQRSTUVWXYZ23456789', 1 + floor(random() * 32)::int, 1); end loop;
      exit when not exists (select 1 from public.jb_invites where code = c);
    end loop;
    insert into public.jb_invites (code, note) values (c, p_note);
    return next c;
  end loop;
end $$;
revoke all on function public.jb_make_invites(int, text) from public, anon, authenticated;

-- ===== Saved tours: members only, each player sees only their own =====
create table if not exists public.jb_saves (
  user_id uuid primary key references auth.users (id) on delete cascade,
  tour jsonb not null,
  updated_at timestamptz not null default now()
);
alter table public.jb_saves enable row level security;
drop policy if exists "Players read their own save" on public.jb_saves;
drop policy if exists "Players create their own save" on public.jb_saves;
drop policy if exists "Players update their own save" on public.jb_saves;
create policy "Players read their own save" on public.jb_saves for select
  using (auth.uid() = user_id and exists (select 1 from public.jb_members m where m.user_id = auth.uid()));
create policy "Players create their own save" on public.jb_saves for insert
  with check (auth.uid() = user_id and exists (select 1 from public.jb_members m where m.user_id = auth.uid()));
create policy "Players update their own save" on public.jb_saves for update
  using (auth.uid() = user_id and exists (select 1 from public.jb_members m where m.user_id = auth.uid()));

-- ===== Leaderboard: only members can see it or appear on it =====
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
drop policy if exists "Anyone can see the leaderboard" on public.jb_leaderboard;
drop policy if exists "Members can see the leaderboard" on public.jb_leaderboard;
drop policy if exists "Players add their own row" on public.jb_leaderboard;
drop policy if exists "Players update their own row" on public.jb_leaderboard;
create policy "Members can see the leaderboard" on public.jb_leaderboard for select
  using (exists (select 1 from public.jb_members m where m.user_id = auth.uid()));
create policy "Players add their own row" on public.jb_leaderboard for insert
  with check (auth.uid() = user_id and exists (select 1 from public.jb_members m where m.user_id = auth.uid()));
create policy "Players update their own row" on public.jb_leaderboard for update
  using (auth.uid() = user_id and exists (select 1 from public.jb_members m where m.user_id = auth.uid()));
create index if not exists jb_leaderboard_rank on public.jb_leaderboard (gigs desc, fans desc);

-- ===== Make your first 10 codes (shows them below when you click Run) =====
select * from public.jb_make_invites(10, 'Family and friends');
