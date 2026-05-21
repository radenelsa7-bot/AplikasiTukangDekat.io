const fs = require('fs');
const path = require('path');
const { test, expect } = require('@playwright/test');

function loadToken() {
  if (process.env.TEST_TOKEN) return process.env.TEST_TOKEN;

  const envPath = path.resolve(__dirname, '..', '.env');
  if (!fs.existsSync(envPath)) return '';

  const content = fs.readFileSync(envPath, 'utf8');
  const match = content.match(/^TEST_TOKEN=(.+)$/m);
  return match ? match[1].trim() : '';
}

test.describe('Treasurer export endpoint', () => {
  test('CSV export returns CSV when TEST_TOKEN provided', async ({ request }) => {
    const token = loadToken();
    test.skip(!token, 'TEST_TOKEN not set in environment');

    const res = await request.get('/api/treasurer/payments/report?export=csv', {
      headers: {
        'Authorization': `Bearer ${token}`,
        'Accept': 'text/csv'
      }
    });

    expect(res.status()).toBe(200);
    const ct = res.headers()['content-type'] || '';
    expect(ct).toContain('text/csv');

    const body = await res.text();
    expect(body.length).toBeGreaterThan(10);
    expect(body).toContain('payment_id');
  });
});
