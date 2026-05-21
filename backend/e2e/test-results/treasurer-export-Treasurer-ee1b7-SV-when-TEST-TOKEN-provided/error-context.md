# Instructions

- Following Playwright test failed.
- Explain why, be concise, respect Playwright best practices.
- Provide a snippet of code with the fix, if possible.

# Test info

- Name: treasurer-export.spec.js >> Treasurer export endpoint >> CSV export returns CSV when TEST_TOKEN provided
- Location: tests\treasurer-export.spec.js:4:3

# Error details

```
Error: expect(received).toBe(expected) // Object.is equality

Expected: 200
Received: 404
```

# Test source

```ts
  1  | const { test, expect } = require('@playwright/test');
  2  | 
  3  | test.describe('Treasurer export endpoint', () => {
  4  |   test('CSV export returns CSV when TEST_TOKEN provided', async ({ request }) => {
  5  |     const token = process.env.TEST_TOKEN;
  6  |     test.skip(!token, 'TEST_TOKEN not set in environment');
  7  | 
  8  |     const res = await request.get('/api/treasurer/payments/report?export=csv', {
  9  |       headers: {
  10 |         'Authorization': `Bearer ${token}`,
  11 |         'Accept': 'text/csv'
  12 |       }
  13 |     });
  14 | 
> 15 |     expect(res.status()).toBe(200);
     |                          ^ Error: expect(received).toBe(expected) // Object.is equality
  16 |     const ct = res.headers()['content-type'] || '';
  17 |     expect(ct).toContain('text/csv');
  18 | 
  19 |     const body = await res.text();
  20 |     expect(body.length).toBeGreaterThan(10);
  21 |     expect(body).toContain('payment_id');
  22 |   });
  23 | });
  24 | 
```