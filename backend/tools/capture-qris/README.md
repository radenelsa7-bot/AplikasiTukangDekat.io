Capture QRIS worker

This worker uses `puppeteer-core` and requires a system Chrome/Chromium binary.

Setup

1. Install dependencies:

```bash
cd backend/tools/capture-qris
npm install
```

2. Install Chrome or Chromium on your machine. On Windows you can use Chrome stable; on Linux install `chromium` or `google-chrome`.

3. Set environment variable `PUPPETEER_EXECUTABLE_PATH` to the Chrome/Chromium executable path. Example:

Windows (PowerShell):

```powershell
$env:PUPPETEER_EXECUTABLE_PATH = 'C:\\Program Files\\Google\\Chrome\\Application\\chrome.exe'
```

Linux / macOS:

```bash
export PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium
```

4. Run the capture script manually to test:

```bash
node index.js --url="https://checkout-staging.xendit.co/web/<invoice_id>" --timeout=20000
```

Notes

- We intentionally use `puppeteer-core` to avoid `@puppeteer/browsers` which pulls in vulnerable tar-fs/ws dependencies.
- Keep this tool restricted to developer/worker environments. For production, prefer Xendit enabling QR API or a dedicated secure worker environment.
