// Lightweight landing page JS for animations and counters

document.addEventListener('DOMContentLoaded', function () {
  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  const obs = new IntersectionObserver(
    (entries) => {
      entries.forEach((e) => {
        if (e.isIntersecting) {
          e.target.classList.add('in-view');
        }
      });
    },
    { threshold: 0.15 }
  );

  document.querySelectorAll('[data-anim]').forEach((el) => obs.observe(el));

  document.querySelectorAll('[data-counter]').forEach((el) => startCounter(el, reduced));

  document.querySelectorAll('a[href^="#"]').forEach((a) => {
    a.addEventListener('click', (e) => {
      const href = a.getAttribute('href');
      if (href && href.length > 1) {
        e.preventDefault();
        const target = document.querySelector(href);
        if (target) {
          target.scrollIntoView({ behavior: 'smooth', block: 'start' });
        }
      }
    });
  });

  document.querySelectorAll('.btn').forEach((btn) => {
    btn.addEventListener('click', function (e) {
      const rect = btn.getBoundingClientRect();
      const x = e.clientX - rect.left;
      const y = e.clientY - rect.top;
      const ripple = document.createElement('span');
      ripple.className = 'btn-ripple';
      ripple.style.left = `${x}px`;
      ripple.style.top = `${y}px`;
      btn.appendChild(ripple);
      setTimeout(() => ripple.remove(), 450);
    });
  });

  const form = document.getElementById('bookingForm');
  if (form) {
    form.addEventListener('submit', async (ev) => {
      ev.preventDefault();
      const data = Object.fromEntries(new FormData(form));
      try {
        const res = await fetch('/booking', {
          method: 'POST',
          headers: {
            'X-CSRF-TOKEN': document.querySelector('input[name="_token"]')?.value || '',
            Accept: 'application/json',
            'Content-Type': 'application/json',
          },
          body: JSON.stringify(data),
        });
        const json = await res.json();
        if (res.ok) {
          const e = document.createElement('div');
          e.className = 'alert alert-success mt-3';
          e.textContent = 'Booking terkirim. Tim kami akan menghubungi Anda.';
          form.prepend(e);
          form.reset();
          setTimeout(() => e.remove(), 7000);
        } else {
          const msg = json.message || 'Gagal mengirim booking';
          alert(msg);
        }
      } catch (err) {
        alert('Terjadi kesalahan jaringan');
      }
    });
  }
});

function startCounter(el, reduced) {
  const target = parseInt(el.dataset.to || el.getAttribute('data-target') || '0', 10);
  if (reduced || !target) {
    el.textContent = String(target);
    return;
  }
  if (el.dataset.started) return;
  el.dataset.started = '1';

  let value = 0;
  const duration = 1600;
  const stepTime = 16;
  const steps = Math.ceil(duration / stepTime);
  const step = target / steps;

  const iv = setInterval(() => {
    value += step;
    if (value >= target) {
      el.textContent = target.toLocaleString();
      clearInterval(iv);
    } else {
      el.textContent = Math.floor(value).toLocaleString();
    }
  }, stepTime);
}

function isElementInViewport(el) {
  const rect = el.getBoundingClientRect();
  return rect.top < (window.innerHeight || document.documentElement.clientHeight) && rect.bottom >= 0;
}
