@extends('layouts.admin')

@section('title', 'Pemesanan & Pembayaran - TukangDekat')
@section('page_title', 'Pemesanan & Pembayaran')

@section('admin_content')
<div class="row">
    <div class="col-12">
        <div class="card">
            <div class="card-body">
                <div class="d-flex justify-content-between align-items-center mb-4">
                    <div>
                        <h5 class="card-title">Order Terbaru</h5>
                        <p class="text-muted mb-0">Kelola order dan status pembayaran.</p>
                    </div>
                    <button class="btn btn-accent">Buat Invoice</button>
                </div>
                <div class="table-responsive">
                    <table class="table align-middle">
                        <thead>
                            <tr>
                                <th>Order ID</th>
                                <th>Customer</th>
                                <th>Provider</th>
                                <th>Status</th>
                                <th>Total</th>
                            </tr>
                        </thead>
                        <tbody>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>ODR-1001</td>
                                <td>Rina</td>
                                <td>CV Maju Jaya</td>
                                <td><span class="badge bg-success">Selesai</span></td>
                                <td>Rp 475.000</td>
                            </tr>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>ODR-1002</td>
                                <td>Hendra</td>
                                <td>Fixit Service</td>
                                <td><span class="badge bg-warning">Proses</span></td>
                                <td>Rp 225.000</td>
                            </tr>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>ODR-1003</td>
                                <td>Aulia</td>
                                <td>Solusi Plumbing</td>
                                <td><span class="badge bg-secondary">Menunggu</span></td>
                                <td>Rp 350.000</td>
                            </tr>
                            <tr class="bg-white rounded-3 shadow-sm mb-2">
                                <td>ODR-1004</td>
                                <td>Aditya</td>
                                <td>Bangun Cepat</td>
                                <td><span class="badge bg-success">Selesai</span></td>
                                <td>Rp 1.050.000</td>
                            </tr>
                        </tbody>
                    </table>
                </div>
            </div>
        </div>
    </div>
</div>
@endsection
