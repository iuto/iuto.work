const findCollection = (payload) => {
  if (Array.isArray(payload)) return payload;
  if (!payload || typeof payload !== "object") return [];
  return Object.values(payload).find(Array.isArray) || [];
};

module.exports = async function handler(request, response) {
  if (request.method !== "GET") {
    return response.status(405).json({ error: "Method not allowed" });
  }

  const apiKey = process.env.SIZU_API_KEY;
  if (!apiKey) {
    return response.status(500).json({ error: "SIZU_API_KEY is not configured" });
  }

  try {
    const apiResponse = await fetch("https://sizu.me/api/v1/posts", {
      headers: {
        Authorization: apiKey,
        Accept: "application/json"
      }
    });
    const payload = await apiResponse.json();

    if (!apiResponse.ok) {
      return response.status(502).json({
        error: "sizu.me API request failed",
        status: apiResponse.status
      });
    }

    const items = findCollection(payload);
    const safeFields = items.slice(0, 10).map((item) => Object.fromEntries(
      Object.entries(item)
        .filter(([key]) => /(public|publish|visibility|status|limited|secret|url)/i.test(key))
        .map(([key, value]) => [key, typeof value === "object" ? typeof value : value])
    ));

    return response.status(200).json({
      payloadType: Array.isArray(payload) ? "array" : typeof payload,
      topLevelKeys: payload && !Array.isArray(payload) && typeof payload === "object"
        ? Object.keys(payload)
        : [],
      itemCount: items.length,
      itemKeys: items[0] && typeof items[0] === "object" ? Object.keys(items[0]) : [],
      visibilityFields: safeFields
    });
  } catch {
    return response.status(502).json({ error: "Could not connect to sizu.me API" });
  }
};
