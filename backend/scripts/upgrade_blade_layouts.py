import re
from pathlib import Path

BASE_DIR = Path(__file__).resolve().parent.parent
VIEW_DIR = BASE_DIR / 'resources' / 'views'

LAYOUT_FILES = {
    'layouts/base.blade.php': "...",
    'layouts/admin.blade.php': "...",
    'layouts/customer.blade.php': "...",
    'partials/admin_header.blade.php': "...",
    'partials/admin_footer.blade.php': "...",
    'partials/customer_header.blade.php': "...",
    'partials/customer_footer.blade.php': "...",
}

TARGET_FILES = {
    'welcome.blade.php': 'customer',
    'auth/login.blade.php': 'customer',
    'auth/register.blade.php': 'customer',
    'app/dashboard.blade.php': 'admin',
    'admin/treasurer/provider_payouts.blade.php': 'admin',
    'admin/treasurer/provider_payout_detail.blade.php': 'admin',
    'admin/treasurer/report_standalone.blade.php': 'admin',
    'admin/treasurer/report.blade.php': 'admin',
}

HEAD_TEMPLATE = '''<!doctype html>
<html lang="{{ str_replace('_', '-', app()->getLocale()) }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <meta name="csrf-token" content="{{ csrf_token() }}">
    <title>@yield('title', config('app.name', 'TukangDekat'))</title>

    @if (file_exists(public_path('build/manifest.json')) || file_exists(public_path('hot')))
        @vite(['resources/css/app.css', 'resources/js/app.js'])
    @else
        <script src="https://cdn.tailwindcss.com"></script>
    @endif

    <style>
        body {
            font-family: Inter, ui-sans-serif, system-ui, -apple-system, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
        }
    </style>
    @stack('head')
</head>
<body class="bg-slate-50 text-slate-900 min-h-screen">
    @yield('header')

    <main class="min-h-[calc(100vh-10rem)]">
        @yield('content')
    </main>

    @yield('footer')

    @stack('scripts')
</body>
</html>
'''

ADMIN_LAYOUT = '''@extends('layouts.base')

@section('header')
    @include('partials.admin_header')
@endsection

@section('footer')
    @include('partials.admin_footer')
@endsection

@section('content')
    @yield('content')
@endsection
'''

CUSTOMER_LAYOUT = '''@extends('layouts.base')

@section('header')
    @include('partials.customer_header')
@endsection

@section('footer')
    @include('partials.customer_footer')
@endsection

@section('content')
    @yield('content')
@endsection
'''

ADMIN_HEADER = '''<header class="bg-slate-950 text-white shadow-sm">
    <div class="max-w-6xl mx-auto px-4 py-4 flex flex-wrap items-center justify-between gap-3">
        <a href="/dashboard" class="text-lg font-semibold tracking-tight">TukangDekat Admin</a>
        <nav class="flex flex-wrap items-center gap-2 text-sm text-slate-200">
            <a href="/dashboard" class="rounded-md px-3 py-2 hover:bg-slate-800">Dashboard</a>
            <a href="/admin/treasurer/provider-payouts" class="rounded-md px-3 py-2 hover:bg-slate-800">Payouts</a>
            <a href="/admin/treasurer/report" class="rounded-md px-3 py-2 hover:bg-slate-800">Laporan</a>
            <a href="/" class="rounded-md px-3 py-2 bg-orange-600 text-white hover:bg-orange-500">Front Home</a>
        </nav>
    </div>
</header>
'''

ADMIN_FOOTER = '''<footer class="bg-slate-950 text-slate-300 border-t border-slate-800">
    <div class="max-w-6xl mx-auto px-4 py-5 flex flex-col gap-3 sm:flex-row sm:justify-between sm:items-center text-sm">
        <span>© {{ date('Y') }} TukangDekat. All rights reserved.</span>
        <span class="text-slate-500">Admin dashboard with payment reporting and payout control.</span>
    </div>
</footer>
'''

CUSTOMER_HEADER = '''<header class="bg-white border-b border-slate-200 shadow-sm">
    <div class="max-w-6xl mx-auto px-4 py-4 flex flex-wrap items-center justify-between gap-3">
        <a href="/" class="text-lg font-semibold text-slate-900">TukangDekat</a>
        <nav class="flex flex-wrap items-center gap-3 text-sm text-slate-700">
            <a href="/login" class="hover:text-slate-900">Login</a>
            <a href="/register" class="rounded-md px-3 py-2 bg-orange-600 text-white hover:bg-orange-500">Register</a>
        </nav>
    </div>
</header>
'''

CUSTOMER_FOOTER = '''<footer class="bg-white border-t border-slate-200 text-slate-600">
    <div class="max-w-6xl mx-auto px-4 py-5 flex flex-col gap-3 sm:flex-row sm:justify-between sm:items-center text-sm">
        <span>© {{ date('Y') }} TukangDekat. Designed for simple order and payment flows.</span>
        <span class="text-slate-500">Fast, clean, and consistent customer experience.</span>
    </div>
</footer>
'''


def ensure_layout_files():
    templates = {
        'layouts/base.blade.php': HEAD_TEMPLATE,
        'layouts/admin.blade.php': ADMIN_LAYOUT,
        'layouts/customer.blade.php': CUSTOMER_LAYOUT,
        'partials/admin_header.blade.php': ADMIN_HEADER,
        'partials/admin_footer.blade.php': ADMIN_FOOTER,
        'partials/customer_header.blade.php': CUSTOMER_HEADER,
        'partials/customer_footer.blade.php': CUSTOMER_FOOTER,
    }
    for relative_path, content in templates.items():
        path = VIEW_DIR / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        if not path.exists() or path.read_text(encoding='utf-8') != content:
            path.write_text(content, encoding='utf-8')
            print(f'Updated layout file: {relative_path}')


def normalize_title(title: str) -> str:
    title = title.strip()
    title = title.replace("\n", " ").strip()
    title = re.sub(r"\s+", " ", title)
    return title or 'TukangDekat'


def title_literal(title: str) -> str:
    return title.replace("'", "\\'")


def extract_title(content: str) -> str:
    match = re.search(r"<title>(.*?)</title>", content, flags=re.I|re.S)
    if match:
        return normalize_title(match.group(1))
    return 'TukangDekat'


def extract_body_html(content: str) -> str:
    body_match = re.search(r"<body[^>]*>(.*?)</body>", content, flags=re.I|re.S)
    if not body_match:
        return None
    body_html = body_match.group(1).strip()
    scripts = re.findall(r"<script\b.*?</script>", body_html, flags=re.I|re.S)
    body_html = re.sub(r"<script\b.*?</script>", "", body_html, flags=re.I|re.S).strip()
    return body_html, '\n\n'.join(scripts).strip()


def extract_scripts_from_content(content: str) -> str:
    scripts = re.findall(r"<script\b.*?</script>", content, flags=re.I|re.S)
    return '\n\n'.join(scripts).strip()


def rewrite_file(path: Path, layout: str):
    raw = path.read_text(encoding='utf-8')
    if "@extends('layouts." in raw:
        print(f'Skipping already migrated file: {path.relative_to(BASE_DIR)}')
        return

    if '<html' in raw.lower() or '<!doctype html>' in raw.lower():
        title = extract_title(raw)
        body_html, scripts = extract_body_html(raw)
        if body_html is None:
            print(f'Could not parse body for {path.relative_to(BASE_DIR)}; skipping')
            return
        output_lines = [f"@extends('layouts.{layout}')", '', f"@section('title', '{title_literal(title)}')", '', "@section('content')", body_html, '@endsection']
        if scripts:
            output_lines += ['', "@push('scripts')", scripts, '@endpush']
        path.write_text('\n'.join(output_lines), encoding='utf-8')
        print(f'Migrated {path.relative_to(BASE_DIR)} to {layout} layout')
        return

    if "@extends('welcome')" in raw:
        updated = raw.replace("@extends('welcome')", f"@extends('layouts.{layout}')")
        if "@section('title'" not in updated:
            updated = updated.replace("@extends('layouts.%s')" % layout,
                                      f"@extends('layouts.{layout}')\n@section('title', '{title_literal(layout.title() + ' Dashboard')}')")
        scripts = extract_scripts_from_content(updated)
        if scripts and "@push('" not in updated and "@section('scripts')" not in updated:
            # move scripts to stack if they appear after last @endsection
            updated = re.sub(r"(</script>\s*)+$", '', updated, flags=re.I)
            updated += "\n\n@push('scripts')\n" + scripts + "\n@endpush\n"
        path.write_text(updated, encoding='utf-8')
        print(f'Converted extends for {path.relative_to(BASE_DIR)}')
        return

    print(f'No migration rule for {path.relative_to(BASE_DIR)}')


def main():
    ensure_layout_files()
    for relative_path, layout in TARGET_FILES.items():
        file_path = VIEW_DIR / relative_path
        if not file_path.exists():
            print(f'Missing target file: {relative_path}')
            continue
        rewrite_file(file_path, layout)

if __name__ == '__main__':
    main()
