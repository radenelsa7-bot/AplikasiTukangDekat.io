@extends('layouts.admin')

@section('title', 'Payout Detail')

@section('content')
<div class="max-w-4xl mx-auto p-6">
    <h1 class="text-2xl font-bold mb-4">Payout #{{ $p->id }} - {{ optional($p->provider)->name }}</h1>
    <div class="bg-white p-4 rounded shadow mb-4">
      <div>Jumlah: Rp {{ number_format($p->amount,0,',','.') }}</div>
      <div>Status: <strong>{{ $p->status }}</strong></div>
      <div>Transaction ref: {{ $p->transaction_reference ?? '-' }}</div>
      <div>Error: {{ $p->error_message ?? '-' }}</div>
    </div>

    <div class="mb-4">
      @if($p->status === 'FAILED')
        <button id="retryBtn" class="bg-yellow-600 text-white px-4 py-2 rounded">Retry</button>
      @endif
      <a href="/admin/treasurer/provider-payouts" class="ml-2 text-sm text-blue-600">Kembali</a>
    </div>

    <div class="bg-white rounded shadow">
      <table class="w-full text-sm">
        <thead class="bg-gray-100"><tr><th class="p-2">ID</th><th class="p-2">Status</th><th class="p-2">Ref</th><th class="p-2">Error</th><th class="p-2">At</th></tr></thead>
        <tbody>
          @foreach($p->attempts as $a)
            <tr class="border-b"><td class="p-2">{{ $a->id }}</td><td class="p-2">{{ $a->status }}</td><td class="p-2">{{ $a->transaction_reference ?? '-' }}</td><td class="p-2">{{ $a->error_message ?? '-' }}</td><td class="p-2">{{ $a->created_at }}</td></tr>
          @endforeach
        </tbody>
      </table>
    </div>
  </div>
@endsection

@push('scripts')
<script>
    function csrfToken(){ return document.querySelector('meta[name="csrf-token"]').getAttribute('content'); }
    document.getElementById('retryBtn')?.addEventListener('click', async function(){
      if (!confirm('Retry payout?')) return;
      this.disabled = true; this.textContent = 'Mengirim...';
      const res = await fetch('/admin/treasurer/provider-payouts/{{ $p->id }}/retry', { method: 'POST', headers: {'X-CSRF-TOKEN': csrfToken(), 'Content-Type':'application/json'}, credentials: 'same-origin' });
      const d = await res.json().catch(()=>({}));
      if (!res.ok) { alert('Gagal: ' + (d.message||res.statusText)); this.disabled=false; this.textContent='Retry'; return; }
      alert('Retry dispatched'); location.reload();
    });
  </script>
@endpush