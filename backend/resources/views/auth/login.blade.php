@extends('layouts.customer')

@section('title', 'Login - TukangDekat')

@section('content')
<div class="min-h-[calc(100vh-10rem)] flex items-center justify-center py-10">
  <div class="w-full max-w-md p-6 bg-white rounded shadow">
    <h1 class="text-xl font-bold mb-4">Login</h1>
    <div id="alert" class="hidden mb-3 text-sm"></div>
    <form id="loginForm" class="space-y-3">
      <div>
        <label class="block text-sm">Email</label>
        <input id="email" type="email" class="w-full border p-2 rounded" required>
      </div>
      <div>
        <label class="block text-sm">Password</label>
        <input id="password" type="password" class="w-full border p-2 rounded" required>
      </div>
      <div class="flex items-center justify-between">
        <button type="submit" class="px-4 py-2 bg-blue-600 text-white rounded">Login</button>
        <a href="{{ route('register') }}" class="text-sm text-blue-600">Register</a>
      </div>
    </form>
    <div class="mt-4 text-sm text-gray-600">This form submits to the API and will display the token on success for development verification.</div>
  </div>
</div>
@endsection

@push('scripts')
<script>
    const alertEl = document.getElementById('alert');
    function showAlert(msg, ok=true){ alertEl.classList.remove('hidden'); alertEl.textContent = msg; alertEl.className = ok? 'mb-3 text-sm text-green-700':'mb-3 text-sm text-red-700'; }

    document.getElementById('loginForm').addEventListener('submit', async function(e){
      e.preventDefault();
      const email = document.getElementById('email').value;
      const password = document.getElementById('password').value;
      try{
        const res = await fetch('/api/auth/login', {
          method: 'POST', headers: {'Content-Type':'application/json','Accept':'application/json'}, body: JSON.stringify({email,password})
        });
        const d = await res.json().catch(()=>({}));
        if (!res.ok) return showAlert(d.message || 'Login failed', false);
        // show token for dev verification and persist for dashboard
        const token = d.token || d.access_token || (d.data && d.data.token) || null;
        if(token) localStorage.setItem('td_token', token);
        showAlert('Login OK.', true);
        // redirect to dashboard (UI-only)
        setTimeout(()=> location.href = '/dashboard', 400);
      }catch(err){ showAlert(err.message || 'Network error', false); }
    });
  </script>
@endpush