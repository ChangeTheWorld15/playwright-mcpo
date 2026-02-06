import fs from "fs";
import { firefox } from "playwright";

const cookiesPath = process.env.COOKIES_PATH || "/data/cookies.txt";
const userDataDir = process.env.PLAYWRIGHT_MCP_USER_DATA_DIR || "/data/profile";
const stateFlag = `${userDataDir}/.cookies-imported`;

function parseNetscapeCookies(text) {
  const lines = text.split(/\r?\n/);
  const cookies = [];

  for (const line of lines) {
    if (!line) continue;
    if (line.startsWith("#")) continue;

    // domain \t includeSubdomains \t path \t secure \t expires \t name \t value
    const parts = line.split("\t");
    if (parts.length < 7) continue;

    const [domainRaw, , pathRaw, secureRaw, expiresRaw, name, value] = parts;

    const domain = domainRaw.trim();
    const path = (pathRaw || "/").trim();
    const secure = String(secureRaw).toUpperCase() === "TRUE";
    const expires = Number(expiresRaw);

    const cookie = {
      name,
      value,
      domain,
      path,
      secure,
      httpOnly: false,
      sameSite: "Lax",
    };

    // Optional expires
    if (Number.isFinite(expires) && expires > 0) cookie.expires = expires;

    cookies.push(cookie);
  }

  return cookies;
}

function parseJsonCookies(text) {
  const parsed = JSON.parse(text);
  const cookies = Array.isArray(parsed) ? parsed : parsed.cookies;
  if (!Array.isArray(cookies)) return [];

  return cookies.map((c) => {
    const out = {
      name: c.name,
      value: c.value,
      domain: c.domain,
      path: c.path || "/",
      httpOnly: !!(c.httpOnly ?? c.http_only),
      secure: !!(c.secure ?? c.isSecure),
      sameSite: c.sameSite || c.same_site || "Lax",
    };
    if (typeof c.expires === "number") out.expires = c.expires;
    if (typeof c.expirationDate === "number") out.expires = c.expirationDate;
    return out;
  });
}

if (!fs.existsSync(cookiesPath)) {
  console.error(`cookies file not found at ${cookiesPath}`);
  process.exit(1);
}

if (fs.existsSync(stateFlag)) {
  console.log("Cookies already imported, skipping.");
  process.exit(0);
}

const raw = fs.readFileSync(cookiesPath, "utf-8");

// IMPORTANT: ignore leading whitespace/newlines before sniffing format
const sniff = raw.trimStart();

let cookies = [];
if (sniff.startsWith("# Netscape HTTP Cookie File")) {
  cookies = parseNetscapeCookies(sniff);
} else {
  cookies = parseJsonCookies(sniff);
}

if (!Array.isArray(cookies) || cookies.length === 0) {
  console.error("No cookies found after parsing. Check export/domain.");
  process.exit(1);
}

console.log(`Importing ${cookies.length} cookies into persistent profile: ${userDataDir}`);

fs.mkdirSync(userDataDir, { recursive: true });

const context = await firefox.launchPersistentContext(userDataDir, { headless: true });
await context.addCookies(cookies);
await context.close();

fs.writeFileSync(stateFlag, new Date().toISOString());
console.log("Cookies imported successfully.");
