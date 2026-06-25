const fs = require("fs");
const path = require("path");

const root = __dirname;
const outDir = path.join(root, "dist");
const files = ["index.html", "photos.html", "health.html", "style.css", "likes-config.js", "health-config.js", "robots.txt"];
const folders = ["photos"];

fs.rmSync(outDir, { recursive: true, force: true });
fs.mkdirSync(outDir, { recursive: true });

for (const file of files) {
  fs.copyFileSync(path.join(root, file), path.join(outDir, file));
}

for (const folder of folders) {
  fs.cpSync(path.join(root, folder), path.join(outDir, folder), { recursive: true });
}
