create or replace function public.create_team_as_head(
  p_name text,
  p_division_id text,
  p_roster jsonb default '[]'::jsonb,
  p_touch_tracker jsonb default '{"counts":{},"history":[]}'::jsonb,
  p_attendance jsonb default '[]'::jsonb,
  p_lineup_plan jsonb default null
)
returns uuid
language sql
security definer
set search_path = public
as '
  with inserted_team as (
    insert into public.teams (
      name,
      division_id,
      roster,
      touch_tracker,
      attendance,
      lineup_plan,
      created_by
    )
    values (
      p_name,
      p_division_id,
      coalesce(p_roster, ''[]''::jsonb),
      coalesce(p_touch_tracker, ''{"counts":{},"history":[]}''::jsonb),
      coalesce(p_attendance, ''[]''::jsonb),
      p_lineup_plan,
      auth.uid()
    )
    returning id
  ),
  inserted_member as (
    insert into public.team_members (team_id, user_id, role)
    select id, auth.uid(), ''head'' from inserted_team
    on conflict (team_id, user_id) do update set role = ''head''
    returning team_id
  )
  select id from inserted_team;
';

grant execute on function public.create_team_as_head(text, text, jsonb, jsonb, jsonb, jsonb) to authenticated;
