-- =============================================================================
-- DailyDash — Supabase schema
-- Run this in the Supabase SQL Editor (Project → SQL → New Query).
-- =============================================================================

-- 1. Table ---------------------------------------------------------------------
create table if not exists public.expenses (
  id            uuid primary key default gen_random_uuid(),
  user_id       uuid not null references auth.users(id) on delete cascade,
  amount        numeric(14, 2) not null,
  date_time     timestamptz    not null,
  description   text           not null default '',
  category      text           not null default '',
  payment_mode  text           not null default '',
  is_income     boolean        not null default false,
  last_updated  timestamptz    not null default now(),
  created_at    timestamptz    not null default now()
);

create index if not exists expenses_user_id_idx       on public.expenses (user_id);
create index if not exists expenses_last_updated_idx  on public.expenses (last_updated);

-- 2. Auto-update `last_updated` ------------------------------------------------
create or replace function public.set_last_updated()
returns trigger
language plpgsql
as $$
begin
  new.last_updated := now();
  return new;
end;
$$;

drop trigger if exists trg_expenses_last_updated on public.expenses;
create trigger trg_expenses_last_updated
  before update on public.expenses
  for each row execute function public.set_last_updated();

-- 3. Row Level Security --------------------------------------------------------
alter table public.expenses enable row level security;

drop policy if exists "expenses_select_own" on public.expenses;
create policy "expenses_select_own"
  on public.expenses for select
  using (auth.uid() = user_id);

drop policy if exists "expenses_insert_own" on public.expenses;
create policy "expenses_insert_own"
  on public.expenses for insert
  with check (auth.uid() = user_id);

drop policy if exists "expenses_update_own" on public.expenses;
create policy "expenses_update_own"
  on public.expenses for update
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

drop policy if exists "expenses_delete_own" on public.expenses;
create policy "expenses_delete_own"
  on public.expenses for delete
  using (auth.uid() = user_id);
