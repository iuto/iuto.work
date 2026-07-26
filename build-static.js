const fs = require("fs");
const path = require("path");

const root = __dirname;
const outDir = path.join(root, "dist");
const files = ["index.html", "photos.html", "health.html", "style.css", "likes-config.js", "health-config.js", "robots.txt"];
const photoFiles = ["icon.png", "favicon.png"];
const photoFolders = ["thumbs", "large"];
const dataFolders = ["data"];

fs.rmSync(outDir, { recursive: true, force: true });
fs.mkdirSync(outDir, { recursive: true });

for (const file of files) {
  fs.copyFileSync(path.join(root, file), path.join(outDir, file));
}

const photoOutDir = path.join(outDir, "photos");
fs.mkdirSync(photoOutDir, { recursive: true });

for (const file of photoFiles) {
  fs.copyFileSync(path.join(root, "photos", file), path.join(photoOutDir, file));
}

for (const folder of photoFolders) {
  fs.cpSync(path.join(root, "photos", folder), path.join(photoOutDir, folder), { recursive: true });
}

for (const folder of dataFolders) {
  fs.cpSync(path.join(root, folder), path.join(outDir, folder), { recursive: true });
}

fs.cpSync(path.join(root, "assets"), path.join(outDir, "assets"), { recursive: true });
