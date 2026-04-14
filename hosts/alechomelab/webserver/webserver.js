import { serve } from "bun";
import { Database } from 'bun:sqlite';
import { exec } from "child_process";

new Promise((resolve, reject) =>
  exec("mountpoint -q /media", err =>
    err ? reject(new Error("Drive not found")) : resolve()
  )
);

const db = new Database('/media/airQuality.db');

db.run(`
  CREATE TABLE IF NOT EXISTS airquality (
    pm25 INTEGER NOT NULL,
    pm10 INTEGER NOT NULL,
    timestamp INTEGER PRIMARY KEY
  );
  CREATE INDEX IF NOT EXISTS idx_timestamp ON airquality(timestamp DESC);
`);

const insert = db.prepare('INSERT INTO airquality (pm25, pm10, timestamp) VALUES (?, ?, ?)');
const getData = db.prepare(`
  SELECT pm25, pm10, timestamp FROM airquality
  WHERE timestamp >= ?
  ORDER BY timestamp ASC
`);

const send = (status, message) =>
  new Response(message, {
    status,
    headers: { "Content-Type": "text/plain" }
  });

async function handlePost(req) {
  try {
    const { pm25, pm10 } = await req.json();

    if (typeof pm25 !== "number" || typeof pm10 !== "number")
      return send(400, "Invalid data");

    const now = Date.now();
    const last = getData.get();

    if (last && now - last.timestamp < 540_000)
      return send(429, "Rate limited");

    insert.run(pm25, pm10, now);
    return send(200, "Success");
  } catch {
    return send(400, "Invalid data");
  };
};

const page = await Bun.file("/home/alec/homelab/webserver/page.html").text();
const pageWithToken = page.replaceAll("AIRNOW_TOKEN", process.env.AIRNOW_TOKEN);

serve({
  port: 80,
  fetch(req) {
    const url = new URL(req.url);
    const pathname = url.pathname;

    if (req.method === "POST")
      return handlePost(req);

    else if (pathname == "/favicon.ico")
      return new Response(Bun.file("/home/alec/homelab/webserver/favicon.ico"), {
        headers: { "Content-Type": "image/x-icon" }
      });
    else if (pathname.includes("/getdata")) {
      const data = (pathname == "/getdata")
        ? getData.all(Date.now() - 86400000) // Get past 24 hours
        : getData.all(Date.now() - 604800000); // Get past 7 days
      return new Response(JSON.stringify(data), {
        headers: { "Content-Type": "application/json" }
      });
    };

    return new Response(pageWithToken, { headers: { "Content-Type": "text/html" }});
  }
});
