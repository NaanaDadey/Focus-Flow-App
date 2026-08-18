-- =====================================================================
-- FocusFlow — Supabase Schema
-- Run this in: Supabase Dashboard → SQL Editor → New query → Run
-- =====================================================================

-- ---------------------------------------------------------------------
-- 1. PROFILES
-- One row per auth user. Created automatically on sign-up via trigger.
-- ---------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  email text not null,
  full_name text,
  institution text,
  program text,
  avatar_url text,
  reminder_times text[] not null default array['08:00','13:00','19:00'], -- 3x/day defaults
  daily_reminders_enabled boolean not null default true,
  exam_alert_days_before int[] not null default array[7,3,1], -- countdown milestones
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.profiles enable row level security;

create policy "Users can view own profile"
  on public.profiles for select
  using (auth.uid() = id);

create policy "Users can update own profile"
  on public.profiles for update
  using (auth.uid() = id);

create policy "Users can insert own profile"
  on public.profiles for insert
  with check (auth.uid() = id);

-- Auto-create a profile row whenever a new auth user signs up
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, full_name)
  values (new.id, new.email, new.raw_user_meta_data ->> 'full_name');
  return new;
end;
$$ language plpgsql security definer;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute procedure public.handle_new_user();

-- ---------------------------------------------------------------------
-- 2. TASKS
-- ---------------------------------------------------------------------
create table if not exists public.tasks (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  title text not null,
  description text,
  category text not null default 'general', -- general, assignment, project, reading, personal
  priority text not null default 'medium',  -- low, medium, high, urgent
  status text not null default 'pending',   -- pending, in_progress, completed, missed
  deadline timestamptz not null,
  suggested_start timestamptz,              -- app-computed "start early" nudge
  estimated_minutes int default 60,
  actual_minutes int,
  course_code text,                         -- optional link to a course
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  completed_at timestamptz
);

create index if not exists idx_tasks_user_id on public.tasks (user_id);
create index if not exists idx_tasks_deadline on public.tasks (deadline);

alter table public.tasks enable row level security;

create policy "Users manage own tasks"
  on public.tasks for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 3. TIMETABLE ENTRIES (weekly recurring class schedule)
-- ---------------------------------------------------------------------
create table if not exists public.timetable_entries (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  course_code text not null,
  course_name text not null,
  day_of_week int not null check (day_of_week between 1 and 7), -- 1=Mon .. 7=Sun
  start_time text not null,   -- 'HH:mm'
  end_time text not null,     -- 'HH:mm'
  location text,
  color_hex text default '#6C63FF',
  created_at timestamptz not null default now()
);

create index if not exists idx_timetable_user_id on public.timetable_entries (user_id);

alter table public.timetable_entries enable row level security;

create policy "Users manage own timetable"
  on public.timetable_entries for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 4. SEMESTER (defines the active term window, used for progress bars)
-- ---------------------------------------------------------------------
create table if not exists public.semesters (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  name text not null,             -- e.g. "2026/2027 - Semester 1"
  start_date date not null,
  end_date date not null,
  is_active boolean not null default true,
  created_at timestamptz not null default now()
);

alter table public.semesters enable row level security;

create policy "Users manage own semesters"
  on public.semesters for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 5. COURSES (semester outline)
-- ---------------------------------------------------------------------
create table if not exists public.courses (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  semester_id uuid references public.semesters (id) on delete cascade,
  course_code text not null,
  course_name text not null,
  credit_hours numeric default 3,
  instructor text,
  created_at timestamptz not null default now()
);

alter table public.courses enable row level security;

create policy "Users manage own courses"
  on public.courses for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 6. EXAMS
-- ---------------------------------------------------------------------
create table if not exists public.exams (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  course_code text not null,
  course_name text not null,
  exam_date date not null,
  exam_time text,           -- 'HH:mm', nullable if TBA
  venue text,
  notes text,
  created_at timestamptz not null default now()
);

create index if not exists idx_exams_user_id on public.exams (user_id);
create index if not exists idx_exams_date on public.exams (exam_date);

alter table public.exams enable row level security;

create policy "Users manage own exams"
  on public.exams for all
  using (auth.uid() = user_id)
  with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------
-- 7. updated_at auto-touch trigger (tasks + profiles)
-- ---------------------------------------------------------------------
create or replace function public.touch_updated_at()
returns trigger as $$
begin
  new.updated_at = now();
  return new;
end;
$$ language plpgsql;

drop trigger if exists touch_tasks_updated_at on public.tasks;
create trigger touch_tasks_updated_at
  before update on public.tasks
  for each row execute procedure public.touch_updated_at();

drop trigger if exists touch_profiles_updated_at on public.profiles;
create trigger touch_profiles_updated_at
  before update on public.profiles
  for each row execute procedure public.touch_updated_at();

-- ---------------------------------------------------------------------
-- 8. Helper view: task completion stats per user (used for dashboard)
-- ---------------------------------------------------------------------
create or replace view public.task_stats as
select
  user_id,
  count(*) filter (where status = 'completed') as completed_count,
  count(*) filter (where status = 'pending' or status = 'in_progress') as active_count,
  count(*) filter (where status = 'missed') as missed_count,
  count(*) as total_count
from public.tasks
group by user_id;

-- Note: views inherit RLS from underlying tables when queried through
-- PostgREST with the user's JWT, so no separate policy is required here.
