# Flag Football Lineup Tool

Single-file web app for youth flag football lineup planning, shared coach access, touch tracking, and roster setup.

## Files

- `index.html` - the hosted app
- `supabase_setup.sql` - main Supabase schema and policies
- `supabase_create_team_function.sql` - helper function for cloud team creation
- `supabase_role_lockdown.sql` - database guard for assistant coach permissions
- `supabase_email_invites.sql` - email-based assistant coach invitations

## Deploy

This app is static. Host `index.html` with Netlify, GitHub Pages, Cloudflare Pages, or any static host.
