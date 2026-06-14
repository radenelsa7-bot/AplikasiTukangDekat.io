@extends('layouts.admin')
@section('title', 'Laporan Bendahara - Admin')

@section('content')
    <div class="max-w-6xl mx-auto p-6">
        <h2 class="text-2xl font-bold mb-6">Laporan Bendahara - Pembayaran</h2>

        <!-- Filters -->
        <form id="filters" class="bg-gray-100 p-4 rounded mb-6">
            <div class="grid grid-cols-2 md:grid-cols-4 gap-3 mb-3">
                <input type="date" name="start_date" id="start_date" class="border p-2 rounded" placeholder="Dari Tanggal" />
                <input type="date" name="end_date" id="end_date" class="border p-2 rounded" placeholder="Sampai Tanggal" />
                <select id="status" name="status" class="border p-2 rounded">
                    <option value="">Semua Status</option>
                    <option value="UNPAID">UNPAID</option>
                    <option value="PENDING">PENDING</option>
                    <option value="PAID">PAID</option>
                    <option value="FAILED">FAILED</option>
                    <option value="EXPIRED">EXPIRED</option>
                </select>
                <select id="payment_type" name="payment_type" class="border p-2 rounded">
                    <option value="">Semua Tipe</option>
                    <option value="DP">DP</option>
                    <option value="FINAL">FINAL</option>
                </select>
            </div>
            <div class="flex flex-wrap gap-2">
                <input type="number" id="per_page" name="per_page" placeholder="Per page" class="border p-2 rounded w-28" value="20" />
                <button type="button" id="apply" class="px-4 py-2 bg-blue-600 text-white rounded hover:bg-blue-700">Terapkan Filter</button>
                <a id="exportBtn" href="#" class="px-4 py-2 bg-green-600 text-white rounded hover:bg-green-700">📥 Unduh CSV</a>
                <button type="button" id="exportXlsx" class="px-4 py-2 bg-orange-600 text-white rounded hover:bg-orange-700">📊 Export XLSX</button>
            </div>
        </form>

        <!-- Summary Cards -->
        <div id="summary" class="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6"></div>

        <!-- Breakdown -->
        <div id="breakdown" class="grid grid-cols-2 md:grid-cols-2 gap-4 mb-6"></div>

        <!-- Table -->
        <div class="overflow-x-auto bg-white rounded shadow mb-6">
            <table id="table" class="w-full border-collapse text-sm">
                <thead class="bg-gray-200">
                    <tr>
                        <th class="border p-3 text-left">ID</th>
                        <th class="border p-3 text-left">Order</th>
                        <th class="border p-3 text-left">Tipe</th>
                        <th class="border p-3 text-left">Status</th>
                        <th class="border p-3 text-right">Jumlah</th>
                        <th class="border p-3 text-right">Platform Fee</th>
                        <th class="border p-3 text-right">Provider Payout</th>
                        <th class="border p-3 text-left">Tanggal</th>
                    </tr>
                </thead>
                <tbody id="rows"></tbody>
            </table>
        </div>

        <!-- Pagination -->
        <div id="pagination" class="flex justify-center gap-2 mt-4 mb-6"></div>
    </div>

    @endsection


@push('scripts')
<script>
        // Format currency IDR
        function formatCurrency(value) {
            return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(value);
        }

        async function fetchReport(params = {}) {
            const qs = new URLSearchParams(params);
            const res = await fetch('/api/treasurer/payments/report?' + qs.toString(), { credentials: 'same-origin', headers: { 'X-Requested-With': 'XMLHttpRequest' } });
            if (!res.ok) throw new Error('Gagal memuat data');
            return res.json();
        }

        function paramsFromForm() {
            return {
                start_date: document.getElementById('start_date').value,
                end_date: document.getElementById('end_date').value,
                status: document.getElementById('status').value,
                payment_type: document.getElementById('payment_type').value,
                per_page: document.getElementById('per_page').value || 20,
            };
        }

        async function load(page = 1) {
            try {
                const params = { ...paramsFromForm(), page };
                const data = await fetchReport(params);

                // Summary cards
                const summaryHtml = `
                    <div class="bg-blue-50 border-l-4 border-blue-400 p-4 rounded">
                        <p class="text-gray-600 text-sm">Total Pembayaran</p>
                        <p class="text-2xl font-bold text-blue-700">${data.summary.total_payments}</p>
                    </div>
                    <div class="bg-green-50 border-l-4 border-green-400 p-4 rounded">
                        <p class="text-gray-600 text-sm">Total Nominal</p>
                        <p class="text-2xl font-bold text-green-700">${formatCurrency(data.summary.total_amount)}</p>
                    </div>
                    <div class="bg-purple-50 border-l-4 border-purple-400 p-4 rounded">
                        <p class="text-gray-600 text-sm">Total Platform Fee</p>
                        <p class="text-2xl font-bold text-purple-700">${formatCurrency(data.summary.total_platform_fee)}</p>
                    </div>
                    <div class="bg-orange-50 border-l-4 border-orange-400 p-4 rounded">
                        <p class="text-gray-600 text-sm">Total Provider Payout</p>
                        <p class="text-2xl font-bold text-orange-700">${formatCurrency(data.summary.total_provider_payout)}</p>
                    </div>
                `;
                document.getElementById('summary').innerHTML = summaryHtml;

                // Breakdown by status & type
                const breakdownHtml = `
                    <div class="bg-white border rounded p-4">
                        <h3 class="font-semibold mb-3">Breakdown by Status</h3>
                        <div class="space-y-2">
                            ${(data.breakdown?.by_status || []).map(b => `
                                <div class="flex justify-between text-sm">
                                    <span>${b.status}</span>
                                    <span>${b.total} items (${formatCurrency(b.amount)})</span>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                    <div class="bg-white border rounded p-4">
                        <h3 class="font-semibold mb-3">Breakdown by Type</h3>
                        <div class="space-y-2">
                            ${(data.breakdown?.by_type || []).map(b => `
                                <div class="flex justify-between text-sm">
                                    <span>${b.payment_type}</span>
                                    <span>${b.total} items (${formatCurrency(b.amount)})</span>
                                </div>
                            `).join('')}
                        </div>
                    </div>
                `;
                document.getElementById('breakdown').innerHTML = breakdownHtml;

                // Rows
                const rows = document.getElementById('rows');
                rows.innerHTML = '';
                (data.data || []).forEach(p => {
                    const tr = document.createElement('tr');
                    tr.className = p.status === 'PAID' ? 'bg-green-50' : p.status === 'UNPAID' ? 'bg-red-50' : '';
                    tr.innerHTML = `
                        <td class="border p-3">${p.id}</td>
                        <td class="border p-3">${p.order_id}</td>
                        <td class="border p-3"><span class="px-2 py-1 text-xs rounded font-semibold ${p.payment_type === 'DP' ? 'bg-yellow-200' : 'bg-blue-200'}">${p.payment_type}</span></td>
                        <td class="border p-3"><span class="px-2 py-1 text-xs rounded font-semibold ${p.status === 'PAID' ? 'bg-green-200' : p.status === 'UNPAID' ? 'bg-red-200' : 'bg-gray-200'}">${p.status}</span></td>
                        <td class="border p-3 text-right font-mono">${formatCurrency(p.amount)}</td>
                        <td class="border p-3 text-right font-mono">${formatCurrency(p.platform_fee)}</td>
                        <td class="border p-3 text-right font-mono">${formatCurrency(p.provider_payout)}</td>
                        <td class="border p-3 text-xs">${new Date(p.created_at).toLocaleDateString('id-ID')}</td>
                    `;
                    rows.appendChild(tr);
                });

                // Pagination
                const paginationDiv = document.getElementById('pagination');
                paginationDiv.innerHTML = '';
                const meta = data.meta;
                if (meta.last_page > 1) {
                    // Previous
                    if (meta.current_page > 1) {
                        const prevBtn = document.createElement('button');
                        prevBtn.textContent = '← Prev';
                        prevBtn.className = 'px-3 py-1 border rounded hover:bg-gray-100';
                        prevBtn.onclick = () => load(meta.current_page - 1);
                        paginationDiv.appendChild(prevBtn);
                    }
                    // Page numbers
                    for (let i = Math.max(1, meta.current_page - 2); i <= Math.min(meta.last_page, meta.current_page + 2); i++) {
                        const pageBtn = document.createElement('button');
                        pageBtn.textContent = i;
                        pageBtn.className = `px-3 py-1 border rounded ${i === meta.current_page ? 'bg-blue-600 text-white' : 'hover:bg-gray-100'}`;
                        if (i === meta.current_page) pageBtn.disabled = true;
                        pageBtn.onclick = () => load(i);
                        paginationDiv.appendChild(pageBtn);
                    }
                    // Next
                    if (meta.current_page < meta.last_page) {
                        const nextBtn = document.createElement('button');
                        nextBtn.textContent = 'Next →';
                        nextBtn.className = 'px-3 py-1 border rounded hover:bg-gray-100';
                        nextBtn.onclick = () => load(meta.current_page + 1);
                        paginationDiv.appendChild(nextBtn);
                    }
                }

                // Export links
                const qs = new URLSearchParams(paramsFromForm());
                document.getElementById('exportBtn').href = '/api/treasurer/payments/report?' + qs.toString() + '&export=csv';
            } catch (e) {
                alert(e.message || 'Error');
            }
        }

        // Event listeners
        document.getElementById('apply').addEventListener('click', () => load(1));
        document.getElementById('exportXlsx').addEventListener('click', () => {
            alert('XLSX export akan segera tersedia. Gunakan CSV untuk saat ini.');
        });

        // Initial load
        load();
    </script>
@endpush
