// Simple animation and counter utilities for landing page
document.addEventListener('DOMContentLoaded', ()=>{
  // Intersection observer for animations
  const io = new IntersectionObserver((entries)=>{
    entries.forEach(e=>{
      if(e.isIntersecting){
        e.target.classList.add('in-view');
        // start counters inside
        if(e.target.classList.contains('counter')|| e.target.querySelectorAll('.counter').length){
          e.target.querySelectorAll('.counter').forEach(startCounter);
        }
        io.unobserve(e.target);
      }
    })
  },{threshold:0.12});

  document.querySelectorAll('[data-anim]').forEach(el=>io.observe(el));

  // Start counters for elements already visible
  document.querySelectorAll('.counter').forEach(el=>{
    if(isElementInViewport(el)) startCounter(el);
  });

  // Floating hero
  const floatEl = document.querySelector('[data-anim="float"]');
  if(floatEl){
    let dir = 1, y=0;
    setInterval(()=>{
      y = y + 0.6*dir;
      if(Math.abs(y) > 12) dir *= -1;
      floatEl.style.transform = `translateY(${y}px)`;
    }, 2200);
  }

  // booking form simple handler
  const bookingForm = document.getElementById('bookingForm');
  if(bookingForm) bookingForm.addEventListener('submit', e=>{
    e.preventDefault();
    alert('Terima kasih! Permintaan booking Anda telah diterima (demo).');
    bookingForm.reset();
  });
});

function startCounter(el){
  if(el.dataset.started) return;
  const target = parseInt(el.dataset.target||el.getAttribute('data-target')||0,10);
  if(!target) return el.textContent = el.textContent || '0';
  el.dataset.started = '1';
  const duration = 1600; const start = 0; const stepTime = 16;
  const steps = Math.ceil(duration/stepTime); let current = start; let step = target/steps;
  const iv = setInterval(()=>{
    current += step; if(current >= target){ el.textContent = target.toLocaleString(); clearInterval(iv); } else el.textContent = Math.floor(current).toLocaleString();
  }, stepTime);
}

function isElementInViewport(el){
  const rect = el.getBoundingClientRect();
  return rect.top < (window.innerHeight||document.documentElement.clientHeight) && rect.bottom >= 0;
}
