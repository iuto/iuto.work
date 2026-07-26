const crypto = require("node:crypto");

const matchesPassword = (provided, expected) => {
  const providedBuffer = Buffer.from(provided);
  const expectedBuffer = Buffer.from(expected);
  return providedBuffer.length === expectedBuffer.length
    && crypto.timingSafeEqual(providedBuffer, expectedBuffer);
};

module.exports = async function handler(request, response) {
  if (request.method !== "POST") {
    return response.status(405).json({ error: "Method not allowed" });
  }

  const apiKey = process.env.SIZU_API_KEY;
  const accessPassword = process.env.SIZU_ACCESS_PASSWORD;
  if (!apiKey || !accessPassword) {
    return response.status(500).json({ error: "Server is not configured" });
  }

  let requestBody = request.body || {};
  if (typeof requestBody === "string") {
    try {
      requestBody = JSON.parse(requestBody || "{}");
    } catch {
      requestBody = {};
    }
  }
  const providedPassword = typeof requestBody.password === "string" ? requestBody.password : "";
  if (!matchesPassword(providedPassword, accessPassword)) {
    response.setHeader("Cache-Control", "no-store");
    return response.status(401).json({ error: "Unauthorized" });
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

    response.setHeader("Cache-Control", "no-store");
    return response.status(200).json({ posts: urlOnlyPosts });
  } catch {
    return response.status(502).json({ error: "Could not connect to sizu.me API" });
  }
};
