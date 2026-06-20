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

## Deploy

This site is static, so GitHub Pages can serve it directly from the repository root.

## Links

- X: https://x.com/iuto_025
- Instagram: https://www.instagram.com/iuto_025/
