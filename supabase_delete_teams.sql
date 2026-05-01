drop policy if exists "heads can delete teams" on public.teams;
create policy "heads can delete teams"
on public.teams
for delete
to authenticated
using (
  public.is_team_head(teams.id)
);
