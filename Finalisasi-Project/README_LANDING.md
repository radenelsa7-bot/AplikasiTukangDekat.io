# Tukang Dekat — Landing Page (Blade Template)

Files added to `Finalisasi-Project`:

- `landing.blade.php` — Blade template for the landing page (static demo, placeholders for images/assets).
- `assets/landing.css` — Modular CSS using project brand colors and responsive rules.
- `assets/landing.js` — Lightweight JS for entrance animations, counter, floating hero, and booking demo handler.

How to use (Laravel):

1. Copy `landing.blade.php` into your `resources/views` (or include it in a layout).
2. Move `Finalisasi-Project/assets/*` into your `public/assets/` and adjust paths if needed.
3. Ensure Bootstrap and Google Fonts are available (template uses CDN links).
4. For production, integrate `assets/landing.css` into your SCSS pipeline and `assets/landing.js` into your build (mix/webpack/vite).

Notes & Next steps:

- Replace placeholder images in `assets/` with original illustrations showing tukang listrik, tukang AC, plumber, dll.
- Convert `assets/landing.css` to SCSS variables/partials if you use an existing SCSS architecture.
- Hook booking form to backend endpoint and add validation & recaptcha for production.
- Add optimized SVG icons (do not copy from the reference image), prefer inline SVG for accessibility and theming.

Accessibility & Performance:

- Buttons use clear focus outlines.
- Animations are minimal and driven by IntersectionObserver.
- Counters use low-cost intervals; consider requestAnimationFrame if needed.

If you want, I can:

- Convert `assets/landing.css` to SCSS and split into partials.
- Integrate Blade into your existing layout and asset pipeline.
- Replace placeholders with royalty-free illustrations and icons matching the brand.
