<!doctype html>
<html>
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Register - TukangDekat</title>
  <script src="https://cdn.tailwindcss.com"></script>
</head>
<body class="bg-gray-50 min-h-screen flex items-center justify-center">
  <div class="w-full max-w-md p-6 bg-white rounded shadow">
    <h1 class="text-xl font-bold mb-4">Register</h1>
    <div id="alert" class="hidden mb-3 text-sm"></div>
    <form id="regForm" class="space-y-3">
      <div>
        <label class="block text-sm">Name</label>
        <input id="name" type="text" class="w-full border p-2 rounded" required>
      </div>
      <div>
        <label class="block text-sm">Email</label>
        <input id="email" type="email" class="w-full border p-2 rounded" required>
      </div>
      <div>
        <label class="block text-sm">Password</label>
        <input id="password" type="password" class="w-full border p-2 rounded" required>
      </div>
      <div>
        <label class="block text-sm">Phone</label>
        <input id="phone" type="text" class="w-full border p-2 rounded" placeholder="0812xxxx" required>
      </div>
      <div>
        <label class="block text-sm">Role</label>
        <select id="role" class="w-full border p-2 rounded">
          <option value="CUSTOMER">CUSTOMER</option>
          <option value="PROVIDER">PROVIDER</option>
        </select>
      </div>
      <div class="flex items-center justify-between">
        <button type="submit" class="px-4 py-2 bg-green-600 text-white rounded">Create account</button>
        <a href="{{ route('login') }}" class="text-sm text-blue-600">Login</a>
      </div>
    </form>
    <div class="mt-4 text-sm text-gray-600">This registers via API for development use; adjust fields to match your API.</div>
  </div>

  <script>
    const alertEl = document.getElementById('alert');
    function showAlert(msg, ok=true){ alertEl.classList.remove('hidden'); alertEl.textContent = msg; alertEl.className = ok? 'mb-3 text-sm text-green-700':'mb-3 text-sm text-red-700'; }

    document.getElementById('regForm').addEventListener('submit', async function(e){
      e.preventDefault();
      const payload = {
        name: document.getElementById('name').value,
        email: document.getElementById('email').value,
        password: document.getElementById('password').value,
        role: document.getElementById('role').value,
        phone: document.getElementById('phone').value
      };
      try{
        const res = await fetch('/api/auth/register', { method: 'POST', headers: {'Content-Type':'application/json','Accept':'application/json'}, body: JSON.stringify(payload) });
        const d = await res.json().catch(()=>({}));
        if (!res.ok) return showAlert(d.message || 'Register failed', false);
        showAlert('Account created. You can now login.', true);
        setTimeout(()=> location.href = '/login', 800);
      }catch(err){ showAlert(err.message || 'Network error', false); }
    });
  </script>
</body>
</html>
