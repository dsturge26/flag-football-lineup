create table if not exists public.team_invites (
  id uuid primary key default gen_random_uuid(),
  team_id uuid not null references public.teams(id) on delete cascade,
  team_name text not null default 'Shared team',
  invited_email text not null,
  role text not null default 'assistant' check (role in ('assistant')),
  status text not null default 'pending' check (status in ('pending', 'accepted', 'revoked')),
  invited_by uuid not null default auth.uid() references auth.users(id) on delete cascade,
  accepted_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (team_id, invited_email)
);

alter table public.team_invites
add column if not exists team_name text not null default 'Shared team';

create or replace function public.normalize_invite_email()
returns trigger
language plpgsql
as $$
begin
  new.invited_email = lower(trim(new.invited_email));
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists normalize_team_invite_email on public.team_invites;
create trigger normalize_team_invite_email
before insert or update on public.team_invites
for each row execute function public.normalize_invite_email();

create or replace function public.accept_team_invite(p_invite_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  invite_row public.team_invites%rowtype;
  current_email text;
begin
  current_email := lower(coalesce(auth.jwt() ->> 'email', ''));

  select *
  into invite_row
  from public.team_invites
  where id = p_invite_id
    and status = 'pending'
    and invited_email = current_email;

  if invite_row.id is null then
    raise exception 'No pending invite found for this signed-in email.';
  end if;

  insert into public.team_members (team_id, user_id, role)
  values (invite_row.team_id, auth.uid(), invite_row.role)
  on conflict (team_id, user_id) do update set role = excluded.role;

  update public.team_invites
  set status = 'accepted',
      accepted_by = auth.uid(),
      updated_at = now()
  where id = invite_row.id;

  return invite_row.team_id;
end;
$$;

grant execute on function public.accept_team_invite(uuid) to authenticated;

alter table public.team_invites enable row level security;

drop policy if exists "heads can create invites" on public.team_invites;
create policy "heads can create invites"
on public.team_invites
for insert
to authenticated
with check (
  public.is_team_head(team_id)
  and invited_by = auth.uid()
  and role = 'assistant'
);

drop policy if exists "heads can update invites" on public.team_invites;
create policy "heads can update invites"
on public.team_invites
for update
to authenticated
using (
  public.is_team_head(team_id)
)
with check (
  public.is_team_head(team_id)
);

drop policy if exists "invitees and heads can read invites" on public.team_invites;
create policy "invitees and heads can read invites"
on public.team_invites
for select
to authenticated
using (
  public.is_team_head(team_id)
  or invited_email = lower(coalesce(auth.jwt() ->> 'email', ''))
);
