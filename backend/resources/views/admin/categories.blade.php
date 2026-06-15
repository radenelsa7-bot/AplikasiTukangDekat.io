@extends('layouts.admin')

@section('title', 'Manajemen Kategori Jasa - TukangDekat')
@section('page_title', 'Manajemen Kategori Jasa')

@section('admin_content')
<div class="row">
    <div class="col-12">
        <div class="card">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h5 class="card-title">Kategori Jasa</h5>
                        <p class="text-muted mb-0">Kelola kategori layanan sesuai SRS.</p>
                    </div>
                    <button class="btn btn-accent">Tambah Kategori</button>
                </div>
                <div class="table-responsive">
                    <table class="table align-middle">
                        <thead>
                            <tr>
                                <th>Nama Kategori</th>
                                <th>Deskripsi</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>Listrik</td>
                                <td>Instalasi, perbaikan, & service listrik.</td>
                                <td><span class="badge bg-primary">Aktif</span></td>
                            </tr>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>Plumbing</td>
                                <td>Perbaikan pipa dan sanitasi.</td>
                                <td><span class="badge bg-primary">Aktif</span></td>
                            </tr>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>AC</td>
                                <td>Maintenance & pemasangan AC.</td>
                                <td><span class="badge bg-primary">Aktif</span></td>
                            </tr>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>Bangunan Ringan</td>
                                <td>Renovasi & perbaikan bangunan ringan.</td>
                                <td><span class="badge bg-primary">Aktif</span></td>
                            </tr>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>Servis Elektronik</td>
                                <td>Perbaikan elektronik rumah tangga.</td>
                                <td><span class="badge bg-primary">Aktif</span></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
