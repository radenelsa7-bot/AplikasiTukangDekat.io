<aside class="main-sidebar sidebar-dark-primary elevation-4" style="background-color: #0b1d4f;">
    <a href="{{ route('dashboard') }}" class="brand-link text-decoration-none border-bottom" style="background-color: #0a1a47;">
        <span class="brand-text fw-semibold ps-3">TukangDekat</span>
    </a>

    <div class="sidebar pt-4">
        <nav class="mt-2">
            <ul class="nav nav-pills nav-sidebar flex-column" data-widget="treeview" role="menu" data-accordion="false">
                @php $role = auth()->user()->role ?? 'ADMIN'; @endphp

                @if(in_array($role, ['ADMIN']))
                    <li class="nav-item">
                        <a href="{{ route('admin.dashboard') }}" class="nav-link text-white">
                            <i class="nav-icon fas fa-tachometer-alt"></i>
                            <p>Dashboard Admin</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('admin.categories') }}" class="nav-link text-white">
                            <i class="nav-icon fas fa-list"></i>
                            <p>Manajemen Kategori Jasa</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('admin.providers') }}" class="nav-link text-white">
                            <i class="nav-icon fas fa-user-check"></i>
                            <p>Verifikasi Penyedia Jasa</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('admin.orders') }}" class="nav-link text-white">
                            <i class="nav-icon fas fa-chart-line"></i>
                            <p>Monitoring Aktivitas</p>
                        </a>
                    </li>
                @endif

                @if(in_array($role, ['TREASURER']))
                    <li class="nav-item">
                        <a href="{{ route('admin.treasurer.report') }}" class="nav-link text-white">
                            <i class="nav-icon fas fa-wallet"></i>
                            <p>Dashboard Keuangan</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('admin.treasurer.provider_payouts') }}" class="nav-link text-white">
                            <i class="nav-icon fas fa-money-check-alt"></i>
                            <p>Monitoring Transaksi</p>
                        </a>
                    </li>
                    <li class="nav-item">
                        <a href="{{ route('admin.treasurer.report') }}" class="nav-link text-white">
                            <i class="nav-icon fas fa-file-invoice-dollar"></i>
                            <p>Laporan Keuangan</p>
                        </a>
                    </li>
                @endif
            </ul>
        </nav>
    </div>
</aside>
