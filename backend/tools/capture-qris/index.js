#!/usr/bin/env node

const puppeteer = require('puppeteer');
const yargs = require('yargs');
const fetch = require('node-fetch');

const argv = yargs
  .option('url', { type: 'string', demandOption: true })
  .option('timeout', { type: 'number', default: 15000 })
  .help()
  .argv;

(async () => {
  const url = argv.url;
  const timeout = argv.timeout;

  try {
    const browser = await puppeteer.launch({ args: ['--no-sandbox', '--disable-setuid-sandbox'] });
    const page = await browser.newPage();
    await page.setViewport({ width: 1280, height: 800 });
    await page.goto(url, { waitUntil: 'networkidle2', timeout });

    // Try to find the largest image on the page (likely the QR)
    const imgSrc = await page.evaluate(() => {
      const imgs = Array.from(document.querySelectorAll('img'));
      if (!imgs.length) return null;
      let best = null;
      let maxArea = 0;
      imgs.forEach(img => {
        try {
          const rect = img.getBoundingClientRect();
          const area = rect.width * rect.height;
          if (area > maxArea) {
            maxArea = area;
            best = img.src || null;
          }
        } catch (e) {}
      });
      return best;
    });

    let dataUrl = null;

    if (imgSrc) {
      if (imgSrc.startsWith('data:')) {
        dataUrl = imgSrc;
      } else {
        // fetch image bytes
        try {
          const res = await fetch(imgSrc);
          const buffer = await res.buffer();
          const base64 = buffer.toString('base64');
          const contentType = res.headers.get('content-type') || 'image/png';
          dataUrl = `data:${contentType};base64,${base64}`;
        } catch (e) {
          dataUrl = null;
        }
      }
    }

    // If still no dataUrl, try canvas
    if (!dataUrl) {
      const canvasData = await page.evaluate(() => {
        const canvas = document.querySelector('canvas');
        if (!canvas) return null;
        try {
          return canvas.toDataURL('image/png');
        } catch (e) {
          return null;
        }
      });
      if (canvasData) dataUrl = canvasData;
    }

    // Fallback: take a screenshot of the visible QR area by heuristic: look for element with "qrcode" or "qr" in class or id
    if (!dataUrl) {
      const elHandle = await page.$('[class*="qr"], [id*="qr"], [class*="qrcode"], [id*="qrcode"]');
      if (elHandle) {
        const clip = await elHandle.boundingBox();
        if (clip && clip.width > 0 && clip.height > 0) {
          const screenshot = await page.screenshot({ clip, encoding: 'base64' });
          dataUrl = `data:image/png;base64,${screenshot}`;
        }
      }
    }

    // Last resort: full page screenshot
    if (!dataUrl) {
      const screenshot = await page.screenshot({ fullPage: false, encoding: 'base64' });
      dataUrl = `data:image/png;base64,${screenshot}`;
    }

    await browser.close();

    console.log(JSON.stringify({ qris_image: dataUrl }));
    process.exit(0);
  } catch (err) {
    console.error(JSON.stringify({ error: err.message }));
    process.exit(2);
  }
})();
