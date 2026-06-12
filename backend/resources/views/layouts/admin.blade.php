@extends('layouts.base')

@section('body_class', 'hold-transition sidebar-mini layout-fixed')

@push('head')
    @vite(['resources/css/admin.css'])
@endpush

@push('scripts')
    @vite(['resources/js/admin.js'])
@endpush

@section('header')
    @include('partials.admin_header')
@endsection

@section('footer')
    @include('partials.admin_footer')
@endsection

@section('content')
<div class="wrapper">
    @include('partials.admin_sidebar')

    <div class="content-wrapper">
        <section class="content-header">
            <div class="container-fluid py-3">
                <div class="row mb-2">
                    <div class="col-sm-6">
                        <h1 class="m-0 text-gray-900">@yield('page_title', 'Admin Panel')</h1>
                    </div>
                </div>
            </div>
        </section>

        <section class="content">
            <div class="container-fluid">
                @yield('admin_content')
            </div>
        </section>
    </div>
</div>
@endsection
