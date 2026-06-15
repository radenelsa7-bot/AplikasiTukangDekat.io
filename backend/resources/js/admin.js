import 'bootstrap/dist/js/bootstrap.bundle.min.js';
import '@fortawesome/fontawesome-free/js/all.min.js';
import 'admin-lte/dist/js/adminlte.min.js';

window.addEventListener('DOMContentLoaded', () => {
    document.querySelectorAll('.btn-accent').forEach((button) => {
        button.addEventListener('mouseenter', () => button.classList.add('shadow-lg'));
        button.addEventListener('mouseleave', () => button.classList.remove('shadow-lg'));
    });
});
