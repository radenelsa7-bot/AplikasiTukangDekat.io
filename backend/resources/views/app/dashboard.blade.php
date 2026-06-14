@extends('layouts.admin')

@section('title', 'Dashboard - TukangDekat')

@section('content')
<div class="max-w-5xl mx-auto p-6">
    <div class="flex items-center justify-between mb-4">
      <div>
        <h1 class="text-2xl font-bold">Dashboard (UI placeholder)</h1>
        <p class="text-gray-700">This is a dashboard placeholder. Integrate with backend auth to show real user data.</p>
      </div>
      <div class="flex items-center gap-3">
        <button id="logoutBtn" class="px-3 py-2 bg-red-600 text-white rounded">Logout</button>
        <a href="/" class="text-blue-600">Back to home</a>
      </div>
    </div>

    <div class="grid grid-cols-1 md:grid-cols-3 gap-4">
      <div class="bg-white p-4 rounded shadow">Welcome panel</div>
      <div class="bg-white p-4 rounded shadow">My Orders (placeholder)</div>
      <div class="bg-white p-4 rounded shadow">Profile (placeholder)</div>
    </div>

    <div class="mt-6"></div>
  </div>
@endsection

@push('scripts')
<script>
    async function fetchMe(){
      const token = localStorage.getItem('td_token');
      if(!token){ location.href = '/login'; return; }
      try{
        const res = await fetch('/api/user', { headers: { 'Authorization': 'Bearer ' + token, 'Accept':'application/json' }});
        const d = await res.json().catch(()=>({}));
        if(!res.ok){ document.body.insertAdjacentHTML('beforeend','<div class="max-w-5xl mx-auto p-4 text-red-600">Failed to fetch user: '+(d.message||res.status)+'</div>'); return; }
        document.body.insertAdjacentHTML('beforeend','<div class="max-w-5xl mx-auto p-4 mt-4 bg-white rounded shadow"><strong>User:</strong> <pre>'+JSON.stringify(d, null, 2)+'</pre></div>');
      }catch(err){ document.body.insertAdjacentHTML('beforeend','<div class="max-w-5xl mx-auto p-4 mt-4 text-red-600">Network error</div>'); }
    }
    fetchMe();

    document.getElementById('logoutBtn').addEventListener('click', async function(){
      const token = localStorage.getItem('td_token');
      if(!token){ location.href = '/login'; return; }
      try{
        const res = await fetch('/api/auth/logout', { method: 'POST', headers: { 'Authorization': 'Bearer ' + token, 'Accept':'application/json' }});
        // ignore response, clear token
        localStorage.removeItem('td_token');
        location.href = '/login';
      }catch(err){ localStorage.removeItem('td_token'); location.href = '/login'; }
    });
  </script>
@endpush