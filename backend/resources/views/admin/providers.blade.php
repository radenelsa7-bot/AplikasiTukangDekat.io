@extends('layouts.admin')

@section('title', 'Manajemen Provider - TukangDekat')
@section('page_title', 'Manajemen Provider')

@section('admin_content')
<div class="row">
    <div class="col-12">
        <div class="card">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h5 class="card-title">Provider Terverifikasi</h5>
                        <p class="text-muted mb-0">Daftar provider aktif yang terdaftar.</p>
                    </div>
                    <button class="btn btn-accent">Tambah Provider</button>
                </div>
                <div class="table-responsive">
                    <table class="table align-middle">
                        <thead>
                            <tr>
                                <th>Nama Provider</th>
                                <th>Kategori</th>
                                <th>Status</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>CV Maju Jaya</td>
                                <td>Listrik</td>
                                <td><span class="badge bg-success">Aktif</span></td>
                            </tr>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>Fixit Service</td>
                                <td>AC</td>
                                <td><span class="badge bg-success">Aktif</span></td>
                            </tr>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>Bangun Cepat</td>
                                <td>Bangunan Ringan</td>
                                <td><span class="badge bg-warning">Verifikasi</span></td>
                            </tr>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>Solusi Plumbing</td>
                                <td>Plumbing</td>
                                <td><span class="badge bg-success">Aktif</span></td>
                            </tr>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>ElektronikPro</td>
                                <td>Servis Elektronik</td>
                                <td><span class="badge bg-success">Aktif</span></td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
