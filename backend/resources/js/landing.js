// Lightweight landing page JS for animations and counters
document.addEventListener('DOMContentLoaded', () => {
  const io = new IntersectionObserver((entries) => {
    entries.forEach(e => {
      if (e.isIntersecting) {
        e.target.classList.add('in-view');
        if (e.target.classList.contains('counter')) startCounter(e.target);
        e.target.querySelectorAll && e.target.querySelectorAll('.counter').forEach(startCounter);
        io.unobserve(e.target);
      }
    });
  }, { threshold: 0.12 });

  document.querySelectorAll('[data-anim]').forEach(el => io.observe(el));

  document.querySelectorAll('.counter').forEach(el => { if (isElementInViewport(el)) startCounter(el); });

  const floatEl = document.querySelector('[data-anim="float"]');
  if (floatEl) {
    let dir = 1, y = 0;
    setInterval(() => { y = y + 0.6 * dir; if (Math.abs(y) > 12) dir *= -1; floatEl.style.transform = `translateY(${y}px)`; }, 2200);
  }

  const bookingForm = document.getElementById('bookingForm');
  if (bookingForm) bookingForm.addEventListener('submit', (e) => {
    e.preventDefault();
    const data = new FormData(bookingForm);
    fetch('/booking', { method: 'POST', body: data, headers: { 'X-Requested-With': 'XMLHttpRequest' } })
      .then(r => r.json())
      .then(json => { if (json.success) { alert('Permintaan booking dikirim. Terima kasih!'); bookingForm.reset(); } else { alert(json.message || 'Gagal mengirim booking'); } })
      .catch(()=> alert('Gagal mengirim booking (network)'));
  });
});

function startCounter(el) {
  if (el.dataset.started) return; const target = parseInt(el.dataset.target||el.getAttribute('data-target')||0, 10);
  if (!target) { el.textContent = el.textContent || '0'; return; }
  el.dataset.started = '1'; const duration = 1600, stepTime = 16; const steps = Math.ceil(duration / stepTime); let current = 0; const step = target / steps;
  const iv = setInterval(() => { current += step; if (current >= target) { el.textContent = target.toLocaleString(); clearInterval(iv); } else el.textContent = Math.floor(current).toLocaleString(); }, stepTime);
}

function isElementInViewport(el) { const rect = el.getBoundingClientRect(); return rect.top < (window.innerHeight||document.documentElement.clientHeight) && rect.bottom >= 0; }
