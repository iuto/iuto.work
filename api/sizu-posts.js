module.exports = async function handler(request, response) {
  if (request.method !== "GET") {
    return response.status(405).json({ error: "Method not allowed" });
  }

  const apiKey = process.env.SIZU_API_KEY;
  if (!apiKey) {
    return response.status(500).json({ error: "SIZU_API_KEY is not configured" });
  }

  try {
    const allPosts = [];
    const knownSlugs = new Set();

    for (let page = 1; page <= 50; page += 1) {
      const apiResponse = await fetch(`https://sizu.me/api/v1/posts?page=${page}`, {
        headers: {
          Authorization: apiKey,
          Accept: "application/json"
        }
      });

      if (!apiResponse.ok) {
        return response.status(502).json({ error: "sizu.me API request failed" });
      }

      const payload = await apiResponse.json();
      const posts = Array.isArray(payload.posts) ? payload.posts : [];
      const newPosts = posts.filter((post) => post.slug && !knownSlugs.has(post.slug));
      newPosts.forEach((post) => {
        knownSlugs.add(post.slug);
        allPosts.push(post);
      });

      if (posts.length === 0 || newPosts.length === 0 || posts.length < 20) break;
    }

    const urlOnlyPosts = allPosts
      .filter((post) => post.visibility === "URL_ONLY")
      .map((post) => ({
        title: post.title,
        slug: post.slug,
        tags: Array.isArray(post.tags) ? post.tags : [],
        createdAt: post.createdAt,
        updatedAt: post.updatedAt
      }));

    response.setHeader("Cache-Control", "s-maxage=300, stale-while-revalidate=3600");
    return response.status(200).json({ posts: urlOnlyPosts });
  } catch {
    return response.status(502).json({ error: "Could not connect to sizu.me API" });
  }
};
