<header class="main-header navbar navbar-expand navbar-dark" style="background-color: #0b1d4f;">
    <div class="container-fluid px-4">
        <a href="{{ route('admin.dashboard') }}" class="navbar-brand">
            <span class="brand-text fw-bold">TukangDekat</span>
        </a>

        <ul class="navbar-nav ms-auto align-items-center gap-2">
            <li class="nav-item d-none d-md-inline">
                <span class="nav-link text-white px-0">{{ auth()->user()->name ?? 'Admin' }}</span>
            </li>
            <li class="nav-item">
                <a href="{{ url('/') }}" class="btn btn-accent btn-sm">Lihat Situs</a>
            </li>
        </ul>
    </div>
</header>
