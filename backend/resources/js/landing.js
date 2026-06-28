// Lightweight landing page JS for animations and counters
document.addEventListener('DOMContentLoaded', function(){
  // prefers-reduced-motion
  const reduced = window.matchMedia('(prefers-reduced-motion: reduce)').matches;

  // simple reveal observer
  const obs = new IntersectionObserver(entries=>{
    entries.forEach(e=>{ if(e.isIntersecting) e.target.classList.add('in-view'); });
  }, { threshold: .15 });
  document.querySelectorAll('[data-anim]').forEach(el=>obs.observe(el));

  // counters
  function startCounter(el){
    const target = +el.dataset.to || 0; let v=0; const step = Math.max(1, Math.round(target/100));
    if(reduced){ el.textContent = target; return; }
    const iv = setInterval(()=>{ v+=step; if(v>=target){ v=target; clearInterval(iv);} el.textContent=v; }, 16);
  }
  document.querySelectorAll('[data-counter]').forEach(el=>startCounter(el));

  // smooth scrolling for anchor links
  document.querySelectorAll('a[href^="#"]').forEach(a=>{
    a.addEventListener('click', e=>{
      const href = a.getAttribute('href'); if(href.length>1){ e.preventDefault(); const target = document.querySelector(href); if(target) target.scrollIntoView({ behavior: 'smooth', block: 'start' }); }
    });
  });

  // simple ripple effect for buttons
  document.querySelectorAll('.btn').forEach(btn=>{
    btn.addEventListener('click', function(e){
      const rect = btn.getBoundingClientRect(); const x = e.clientX - rect.left; const y = e.clientY - rect.top;
      const ripple = document.createElement('span'); ripple.className = 'btn-ripple'; ripple.style.left = x+'px'; ripple.style.top = y+'px';
      btn.appendChild(ripple); setTimeout(()=>ripple.remove(), 450);
    });
  });

  // booking form (AJAX)
  const form = document.getElementById('bookingForm');
  if(form){ form.addEventListener('submit', async (ev)=>{
    ev.preventDefault(); const data = Object.fromEntries(new FormData(form));
    try{ const res = await fetch('/booking',{ method:'POST', headers:{'X-CSRF-TOKEN': document.querySelector('input[name="_token"]').value,'Accept':'application/json','Content-Type':'application/json'}, body: JSON.stringify(data)});
      const json = await res.json(); if(res.ok){
        // show success inline
        const e = document.createElement('div'); e.className='alert alert-success mt-3'; e.textContent = 'Booking terkirim. Tim kami akan menghubungi Anda.';
        form.prepend(e); form.reset(); setTimeout(()=>e.remove(),7000);
      } else { const msg = json.message||'Gagal mengirim booking'; alert(msg); }
    }catch(err){ alert('Terjadi kesalahan jaringan'); }
  })}
});
});

function startCounter(el) {
  if (el.dataset.started) return; const target = parseInt(el.dataset.target||el.getAttribute('data-target')||0, 10);
  if (!target) { el.textContent = el.textContent || '0'; return; }
  el.dataset.started = '1'; const duration = 1600, stepTime = 16; const steps = Math.ceil(duration / stepTime); let current = 0; const step = target / steps;
  const iv = setInterval(() => { current += step; if (current >= target) { el.textContent = target.toLocaleString(); clearInterval(iv); } else el.textContent = Math.floor(current).toLocaleString(); }, stepTime);
}

function isElementInViewport(el) { const rect = el.getBoundingClientRect(); return rect.top < (window.innerHeight||document.documentElement.clientHeight) && rect.bottom >= 0; }
