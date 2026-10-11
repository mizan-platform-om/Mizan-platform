-- MIZAN Admin setup — run once in Supabase SQL Editor as project owner.
-- Replace the placeholder with the UUID of your own Supabase Auth user (Authentication > Users).
-- NEVER use the public/publishable key to authorize admins.
create table if not exists public.mizan_admins (
  user_id uuid primary key references auth.users(id) on delete cascade
);
alter table public.mizan_admins enable row level security;
revoke all on table public.mizan_admins from anon, authenticated;
-- After replacing UUID, run this line separately:
-- insert into public.mizan_admins(user_id) values ('REPLACE_WITH_YOUR_AUTH_USER_UUID') on conflict do nothing;

create or replace function public.mizan_admin_stats()
returns jsonb
language plpgsql security definer
set search_path = ''
as $$
declare result jsonb;
begin
  if auth.uid() is null or not exists (
    select 1 from public.mizan_admins where user_id = auth.uid()
  ) then
    raise exception 'Not authorized' using errcode = '42501';
  end if;
  select jsonb_build_object(
    'total_users', (select count(*) from auth.users),
    'total_projects', (select count(*) from public.projects),
    'projects_last_30_days', (select count(*) from public.projects where created_at >= now() - interval '30 days')
  ) into result;
  return result;
end;
$$;
revoke all on function public.mizan_admin_stats() from public, anon;
grant execute on function public.mizan_admin_stats() to authenticated;
