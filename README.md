# iuto.work

Personal profile and photo gallery for iuto.

## Pages

- `index.html` - profile page
- `photos.html` - photo gallery with metadata, tags, maps, and likes
- `style.css` - shared design
- `photos/` - gallery images and icon

## Shared Likes

The photo detail modal can show likes shared across all visitors with Supabase.
Until Supabase is configured, likes fall back to the visitor's browser storage.

1. Create a Supabase project.
2. Open the SQL editor and run `supabase-likes.sql`.
3. Copy the Project URL and anon public key.
4. Paste them into `likes-config.js`.

```js
window.IUTO_LIKES_CONFIG = {
  supabaseUrl: "https://YOUR_PROJECT.supabase.co",
  supabaseAnonKey: "YOUR_ANON_PUBLIC_KEY"
};
```

The anon key is safe to publish here because the database only allows public reads and the `increment_photo_like` function.

## Health Sync

The home page can show the latest Galaxy Watch data for steps, distance, and sleep.
The static site only reads public rows from Supabase; automatic updates need a phone-side sync path such as:

Galaxy Watch -> Samsung Health -> Health Connect -> Android sync app -> Supabase -> iuto.work

1. Run `supabase-health.sql` in the Supabase SQL editor.
2. Put the same Supabase Project URL and anon public key into `health-config.js`.
3. Replace the sync token placeholder at the bottom of `supabase-health.sql` and run that insert once.
4. Build an Android sync app that reads Health Connect records and calls `upsert_health_daily`.

Do not ship a Supabase service role key in the website or Android app. The Android app should use the anon key plus a private sync token, and the database function should reject writes without that token.

## Deploy

This site is static and is deployed from the repository root with Vercel.

## Links

- X: https://x.com/iuto_025
- Instagram: https://www.instagram.com/iuto_025/
