@extends('layouts.admin')

@section('title', 'Provider Payouts - TukangDekat')
@section('page_title', 'Provider Payouts')

@section('admin_content')
<div class="max-w-6xl mx-auto p-6">
    <h1 class="text-2xl font-bold mb-4">Daftar Provider Payouts</h1>

    <div class="mb-4">
      <label class="inline-flex items-center mr-4"><input id="force_fail_toggle" type="checkbox" class="mr-2">Force fail (testing)</label>
      <button id="sendSelected" class="bg-green-600 text-white px-4 py-2 rounded">Kirim yang dipilih</button>
    </div>

    <div class="bg-white rounded shadow overflow-x-auto">
      <table class="w-full text-sm">
        <thead class="bg-gray-100">
          <tr>
            <th class="p-2"><input type="checkbox" id="select_all"></th>
            <th class="p-2">ID</th>
            <th class="p-2">Provider</th>
            <th class="p-2">Jumlah</th>
            <th class="p-2"># Payments</th>
            <th class="p-2">Status</th>
            <th class="p-2">Sent At</th>
            <th class="p-2">Aksi</th>
          </tr>
        </thead>
        <tbody>
          @foreach($payouts as $p)
            <tr class="border-b">
              <td class="p-2 text-center"><input type="checkbox" class="sel" value="{{ $p->id }}"></td>
              <td class="p-2">{{ $p->id }}</td>
              <td class="p-2">{{ optional($p->provider)->name ?? 'N/A' }} ({{ $p->provider_id }})</td>
              <td class="p-2 text-right">Rp {{ number_format($p->amount,0,',','.') }}</td>
              <td class="p-2 text-center">{{ is_array($p->payment_ids) ? count($p->payment_ids) : 0 }}</td>
              <td class="p-2">{{ $p->status }}</td>
              <td class="p-2">{{ $p->sent_at }}</td>
              <td class="p-2">
                @if($p->status === 'PENDING')
                  <button class="sendBtn bg-blue-600 text-white px-3 py-1 rounded" data-id="{{ $p->id }}">Kirim</button>
                @else
                  <span class="text-gray-500">-</span>
                @endif
              </td>
            </tr>
          @endforeach
        </tbody>
      </table>
    </div>

    <div class="mt-4">
      {{ $payouts->links() }}
    </div>
  </div>
@endsection

@push('scripts')
<script>
    document.getElementById('select_all').addEventListener('change', function(e){
      document.querySelectorAll('.sel').forEach(cb => cb.checked = e.target.checked);
    });

    function csrfToken(){
      return document.querySelector('meta[name="csrf-token"]')?.getAttribute('content') || '{{ csrf_token() }}';
    }

    function isForceFail(){
      return !!document.getElementById('force_fail_toggle')?.checked;
    }

    async function sendId(id, btn){
      btn.disabled = true;
      btn.textContent = 'Mengirim...';
      try{
        const res = await fetch('/admin/treasurer/provider-payouts/' + id + '/send', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': csrfToken() },
          credentials: 'same-origin',
          body: JSON.stringify({ force_fail: isForceFail() })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.message || 'gagal');
        btn.textContent = 'Terkirim';
        location.reload();
      }catch(err){
        alert('Gagal: ' + err.message);
        btn.disabled = false;
        btn.textContent = 'Kirim';
      }
    }

    document.querySelectorAll('.sendBtn').forEach(b => {
      b.addEventListener('click', (e) => sendId(b.dataset.id, b));
    });

    document.getElementById('sendSelected').addEventListener('click', async function(){
      const ids = Array.from(document.querySelectorAll('.sel:checked')).map(i => i.value);
      if (ids.length === 0) return alert('Pilih minimal 1 payout');
      if (!confirm('Kirim ' + ids.length + ' payout?')) return;
      this.disabled = true; this.textContent = 'Mengirim...';
      try{
        const res = await fetch('/admin/treasurer/provider-payouts/send-batch', {
          method: 'POST',
          headers: { 'Content-Type': 'application/json', 'X-CSRF-TOKEN': csrfToken() },
          credentials: 'same-origin',
          body: JSON.stringify({ ids, force_fail: isForceFail() })
        });
        const data = await res.json();
        if (!res.ok) throw new Error(data.message || 'gagal batch');
        alert('Selesai');
        location.reload();
      }catch(err){
        alert('Gagal: ' + err.message);
        this.disabled = false; this.textContent = 'Kirim yang dipilih';
      }
    });
  </script>
@endpush
