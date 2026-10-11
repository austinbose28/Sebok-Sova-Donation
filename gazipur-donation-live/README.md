# Gazipur Sebok Sova 2026 Donation Website

## Included
- `index.html`: Bengali donation page, donor receipt, admin login and verification UI.
- `supabase/schema.sql`: database schema and row-level security (RLS).
- `.github/workflows/deploy.yml`: GitHub Pages deployment; creates `config.js` at deploy time from GitHub Actions Secrets.
- `assets-logo.png`: committee logo.

## Important security notes
- Never put a Supabase `service_role` key in this site or GitHub Pages. The site uses only the public anon/publishable key; RLS is mandatory.
- Donor records are private. Anonymous users can INSERT pending donations but cannot SELECT or UPDATE. Only authenticated users with `app_metadata.role = admin` can read/update records.
- Receipt is a submission receipt, NOT proof of successful payment. Admin must verify the transaction against the payment provider/balance.
- The public form collects donor name, phone and transaction ID. Publish a short privacy notice before collecting real donor data.
- Enable email confirmation and MFA for admin accounts where available. Restrict admin access to trusted organizers.

## Setup — GitHub Pages + Supabase

### 1. Create Supabase project
1. Create a project in the Supabase dashboard.
2. Open **Project Settings → API** and copy the Project URL and public anon/publishable key. Never use the `service_role` key.
3. In **SQL Editor**, run all of `supabase/schema.sql`.

### 2. Create an admin user
1. In Supabase **Authentication → Users**, create an account using an organizer-controlled email and a strong unique password.
2. In SQL Editor, replace `ADMIN_EMAIL_HERE` below with that exact email and run:
```sql
update auth.users
set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"admin"}'::jsonb
where email = 'ADMIN_EMAIL_HERE';
```
3. Sign out and sign in again in the site after deployment so the refreshed JWT includes the `role` claim. Do not grant the role to donor accounts.

### 3. Upload to GitHub
1. Create a new GitHub repository, e.g. `gazipur-sebok-sova-donation`.
2. Upload all files in this package. Keep `.github/workflows/deploy.yml` and `supabase/schema.sql`.
3. In repository **Settings → Secrets and variables → Actions → New repository secret**, add:
   - `SUPABASE_URL` = your Supabase Project URL
   - `SUPABASE_ANON_KEY` = your public anon/publishable key
4. Under repository **Settings → Pages**, choose **GitHub Actions** as the build/deployment source.
5. Push/commit to the `main` branch. Open **Actions** and wait for the deployment workflow to succeed. GitHub will show the Pages URL.

### 4. Test before sharing
- Make a small test donation and check that a receipt is shown.
- Sign in to the organizer panel; ensure the record appears.
- Verify and reject a test record, then confirm status updates.
- Test from another browser/device that public users cannot view the donation list.
- Do not announce the site until RLS and admin-only access have been checked.

## Known limits / production checklist
- GitHub Pages is static hosting; Supabase provides the shared database and authentication.
- This version does not automatically verify bKash/Nagad/Rocket payments. A typed transaction ID is unverified until a trusted organizer checks it, unless an approved provider API/payment gateway integration is added.
- Consider adding rate limiting/CAPTCHA and a privacy notice before collecting real data at scale. Public insert-only access can still be abused.
- `SUPABASE_ANON_KEY` is designed for browser use but must be protected by RLS; never substitute a `service_role` secret.
