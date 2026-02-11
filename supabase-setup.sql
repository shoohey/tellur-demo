-- ============================================================
-- TELLUR Supabase セットアップ SQL
-- Supabase ダッシュボード > SQL Editor で実行してください
-- ============================================================

-- 1. プロフィールテーブル（auth.usersの拡張）
create table if not exists profiles (
  id uuid references auth.users on delete cascade primary key,
  email text,
  display_name text,
  facility_name text,
  role text default 'user' check (role in ('user', 'admin')),
  created_at timestamptz default now()
);

-- 2. 案件テーブル
create table if not exists cases (
  id uuid default gen_random_uuid() primary key,
  user_id uuid references profiles(id) on delete cascade,
  client_name text not null,
  phase text default 'input' check (phase in ('input','organized','family','summary','judged')),
  status text default 'in_progress' check (status in ('in_progress','waiting','review','completed')),
  judgment_result text check (judgment_result in ('accepted','declined', null)),
  judgment_memo text,
  created_at timestamptz default now(),
  updated_at timestamptz default now()
);

-- 3. 案件データ（セクションごとにJSON保存）
create table if not exists case_data (
  id uuid default gen_random_uuid() primary key,
  case_id uuid references cases(id) on delete cascade,
  section text not null,
  data jsonb default '{}',
  updated_at timestamptz default now(),
  unique(case_id, section)
);

-- 4. RLS（Row Level Security）有効化
alter table profiles enable row level security;
alter table cases enable row level security;
alter table case_data enable row level security;

-- 5. RLSポリシー: profiles
create policy "Users can view own profile"
  on profiles for select using (auth.uid() = id);

create policy "Users can update own profile"
  on profiles for update using (auth.uid() = id);

create policy "Admins can view all profiles"
  on profiles for select using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- 6. RLSポリシー: cases
create policy "Users can view own cases"
  on cases for select using (auth.uid() = user_id);

create policy "Users can insert own cases"
  on cases for insert with check (auth.uid() = user_id);

create policy "Users can update own cases"
  on cases for update using (auth.uid() = user_id);

create policy "Users can delete own cases"
  on cases for delete using (auth.uid() = user_id);

create policy "Admins can view all cases"
  on cases for select using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- 7. RLSポリシー: case_data
create policy "Users can manage own case data"
  on case_data for all using (
    exists (select 1 from cases where cases.id = case_data.case_id and cases.user_id = auth.uid())
  );

create policy "Admins can view all case data"
  on case_data for select using (
    exists (select 1 from profiles where id = auth.uid() and role = 'admin')
  );

-- 8. 新規ユーザー登録時に自動でprofileを作成するトリガー
create or replace function public.handle_new_user()
returns trigger as $$
begin
  insert into public.profiles (id, email, display_name)
  values (new.id, new.email, split_part(new.email, '@', 1));
  return new;
end;
$$ language plpgsql security definer;

create or replace trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- 9. 最初の管理者を作るためのSQL（登録後にメールアドレスを指定して実行）
-- update profiles set role = 'admin' where email = 'your-admin@example.com';
