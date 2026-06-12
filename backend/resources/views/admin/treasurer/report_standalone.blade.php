@extends('layouts.admin')

@section('title', 'Laporan Bendahara - TukangDekat')
@section('page_title', 'Laporan Bendahara')

@section('admin_content')
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
                <select id="per_page" name="per_page" class="border p-2 rounded w-28">
                    <option value="10">10</option>
                    <option value="20" selected>20</option>
                    <option value="50">50</option>
                    <option value="100">100</option>
                </select>
                <div id="loading" class="hidden items-center ml-2">
                    <svg class="animate-spin h-5 w-5 text-gray-600" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24"><circle class="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" stroke-width="4"></circle><path class="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8v4a4 4 0 00-4 4H4z"></path></svg>
                </div>
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
        <div id="pagination" class="flex flex-col items-center gap-2 mt-4 mb-6">
            <div id="pagination-controls" class="flex justify-center gap-2"></div>
            <div class="flex items-center gap-2 text-sm">
                <label for="jump_page" class="text-gray-600">Jump to</label>
                <input id="jump_page" type="number" min="1" class="border p-1 rounded w-20" />
                <button id="jump_btn" class="px-3 py-1 bg-gray-200 rounded hover:bg-gray-300">Go</button>
            </div>
        </div>
    </div>
@endsection

@push('scripts')
<script>
        // Format currency IDR
        function formatCurrency(value) {
            return new Intl.NumberFormat('id-ID', { style: 'currency', currency: 'IDR', minimumFractionDigits: 0 }).format(value);
        }

        function showLoading(on) {
            const loading = document.getElementById('loading');
            const applyBtn = document.getElementById('apply');
            const exportXlsx = document.getElementById('exportXlsx');
            const exportBtn = document.getElementById('exportBtn');
            const jumpBtn = document.getElementById('jump_btn');
            if (on) {
                loading.classList.remove('hidden');
                applyBtn.disabled = true;
                exportXlsx.disabled = true;
                exportBtn.classList.add('opacity-50');
                jumpBtn.disabled = true;
            } else {
                loading.classList.add('hidden');
                applyBtn.disabled = false;
                exportXlsx.disabled = false;
                exportBtn.classList.remove('opacity-50');
                jumpBtn.disabled = false;
            }
        }

        async function fetchReport(params = {}) {
            showLoading(true);
            try {
                const qs = new URLSearchParams(params);
                const res = await fetch('/api/treasurer/payments/report?' + qs.toString(), {
                    credentials: 'include',
                    headers: {
                        'X-Requested-With': 'XMLHttpRequest',
                        'Accept': 'application/json'
                    }
                });
                console.log('API Response Status:', res.status, res.statusText);
                if (!res.ok) {
                    const errorData = await res.json().catch(() => ({message: res.statusText}));
                    throw new Error(errorData.message || 'Gagal memuat data');
                }
                return await res.json();
            } finally {
                showLoading(false);
            }
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

        // Render pagination controls (ke luar dari template literal)
        function renderPagination(meta) {
            const container = document.getElementById('pagination-controls');
            container.innerHTML = '';
            if (!meta || meta.last_page <= 1) return;

            const addBtn = (text, enabled, onClick, extraClass = '') => {
                const b = document.createElement('button');
                b.textContent = text;
                b.className = `px-3 py-1 border rounded ${extraClass}`;
                if (!enabled) {
                    b.disabled = true;
                    b.classList.add('opacity-50');
                } else {
                    b.onclick = onClick;
                }
                container.appendChild(b);
            };

            const addPageButton = (i) => {
                const btn = document.createElement('button');
                btn.textContent = i;
                btn.className = `px-3 py-1 border rounded ${i === meta.current_page ? 'bg-blue-600 text-white' : 'hover:bg-gray-100'}`;
                if (i === meta.current_page) btn.disabled = true;
                btn.onclick = () => load(i);
                container.appendChild(btn);
            };

            const addEllipsis = () => {
                const span = document.createElement('span');
                span.textContent = '...';
                span.className = 'px-2 text-gray-500';
                container.appendChild(span);
            };

            const total = meta.last_page;
            const current = meta.current_page;

            addBtn('<<', current > 1, () => load(1));
            addBtn('Prev', current > 1, () => load(current - 1));

            let start = Math.max(1, current - 2);
            let end = Math.min(total, current + 2);
            if (start > 1) {
                addPageButton(1);
                if (start > 2) addEllipsis();
            }
            for (let i = start; i <= end; i++) addPageButton(i);
            if (end < total) {
                if (end < total - 1) addEllipsis();
                addPageButton(total);
            }

            addBtn('Next', current < total, () => load(current + 1));
            addBtn('>>', current < total, () => load(total));
            // update jump input
            const jumpInput = document.getElementById('jump_page');
            if (jumpInput) {
                jumpInput.value = current;
                jumpInput.setAttribute('max', total);
                jumpInput.setAttribute('min', 1);
            }
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

                // Pagination - render into #pagination-controls
                const meta = data.meta;
                // store last meta for jump handler
                window.__treasurer_last_meta = meta;
                renderPagination(meta);

                // Export links
                const qs = new URLSearchParams(paramsFromForm());
                document.getElementById('exportBtn').href = '/api/treasurer/payments/report?' + qs.toString() + '&export=csv';
            } catch (e) {
                console.error('Error:', e);
                alert(e.message || 'Error');
            }
        }

        // Event listeners
        document.getElementById('apply').addEventListener('click', () => load(1));
        document.getElementById('exportXlsx').addEventListener('click', () => {
            try {
                // Build summary sheet data from summary cards
                const summaryEl = document.getElementById('summary');
                const summaryRows = [];
                if (summaryEl) {
                    Array.from(summaryEl.children).forEach(card => {
                        const label = (card.querySelector('p.text-gray-600') || card.querySelector('p')).innerText.trim();
                        const value = (card.querySelector('p.text-2xl') || card.querySelector('p:nth-child(2)')).innerText.trim();
                        summaryRows.push([label, value]);
                    });
                }

                // Build payments sheet data from table
                const table = document.getElementById('table');
                const paymentsRows = [];
                if (table) {
                    const headers = Array.from(table.querySelectorAll('thead th')).map(h => h.innerText.trim());
                    paymentsRows.push(headers);
                    Array.from(table.querySelectorAll('tbody tr')).forEach(tr => {
                        const row = Array.from(tr.querySelectorAll('td')).map(td => td.innerText.trim());
                        paymentsRows.push(row);
                    });
                }

                const wb = XLSX.utils.book_new();
                const wsSummary = XLSX.utils.aoa_to_sheet(summaryRows.length ? summaryRows : [['No data']]);
                XLSX.utils.book_append_sheet(wb, wsSummary, 'Summary');
                const wsPayments = XLSX.utils.aoa_to_sheet(paymentsRows.length ? paymentsRows : [['No data']]);
                XLSX.utils.book_append_sheet(wb, wsPayments, 'Payments');

                XLSX.writeFile(wb, `treasurer_report_${new Date().toISOString().slice(0,10)}.xlsx`);
            } catch (err) {
                alert('Gagal mengekspor XLSX: ' + err.message);
            }
        });

        // Event hookups
        document.getElementById('per_page').addEventListener('change', () => load(1));
        document.getElementById('jump_btn').addEventListener('click', () => {
            const v = parseInt(document.getElementById('jump_page').value || '0', 10);
            const meta = window.__treasurer_last_meta || { last_page: 1 };
            if (!v || v < 1) return;
            const page = Math.min(Math.max(1, v), meta.last_page);
            load(page);
        });

        // Initial load
        load();
    </script>
@endpush
