@extends('layouts.admin')

@section('title', 'Dashboard Admin - TukangDekat')
@section('page_title', 'Dashboard Admin')

@section('admin_content')
<div class="row g-4">
    <div class="col-12 col-lg-4">
        <div class="card">
            <div class="card-body">
                <h5 class="card-title">Total User</h5>
                <p class="fs-3 fw-bold">1.254</p>
                <p class="text-muted">Jumlah user terdaftar.</p>
            </div>
        </div>
    </div>
    <div class="col-12 col-lg-4">
        <div class="card">
            <div class="card-body">
                <h5 class="card-title">Total Provider</h5>
                <p class="fs-3 fw-bold">152</p>
                <p class="text-muted">Provider aktif terverifikasi.</p>
            </div>
        </div>
    </div>
    <div class="col-12 col-lg-4">
        <div class="card">
            <div class="card-body">
                <h5 class="card-title">Order Aktif</h5>
                <p class="fs-3 fw-bold">87</p>
                <p class="text-muted">Order sedang berjalan saat ini.</p>
            </div>
        </div>
    </div>
</div>

<div class="row g-4 mt-4">
    <div class="col-12 col-lg-8">
        <div class="card">
            <div class="card-header border-0 bg-white pb-0">
                <h5 class="card-title mb-0">Ringkasan Aktivitas</h5>
            </div>
            <div class="card-body">
                <div class="row row-cols-1 row-cols-md-3 g-3">
                    <div class="col">
                        <div class="p-3 bg-slate-50 rounded-3 border">
                            <h6 class="mb-2">Pendaftaran Penyedia</h6>
                            <p class="mb-0 fw-semibold">12 baru minggu ini</p>
                        </div>
                    </div>
                    <div class="col">
                        <div class="p-3 bg-slate-50 rounded-3 border">
                            <h6 class="mb-2">Verifikasi</h6>
                            <p class="mb-0 fw-semibold">7 provider tertunda</p>
                        </div>
                    </div>
                    <div class="col">
                        <div class="p-3 bg-slate-50 rounded-3 border">
                            <h6 class="mb-2">Penghasilan</h6>
                            <p class="mb-0 fw-semibold">Rp 175.000.000</p>
                        </div>
                    </div>
                </div>
            </div>
        </div>
    </div>

    <div class="col-12 col-lg-4">
        <div class="card">
            <div class="card-body">
                <h5 class="card-title">Notifikasi</h5>
                <ul class="list-group list-group-flush">
                    <li class="list-group-item rounded-3 mb-2">3 provider belum diverifikasi</li>
                    <li class="list-group-item rounded-3 mb-2">2 order DP tertunda</li>
                    <li class="list-group-item rounded-3">1 laporan overdue</li>
                </ul>
            </div>
        </div>
    </div>
</div>
@endsection
