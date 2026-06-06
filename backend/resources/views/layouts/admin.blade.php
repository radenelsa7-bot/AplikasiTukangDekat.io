@extends('layouts.base')

@section('header')
    @include('partials.admin_header')
@endsection

@section('footer')
    @include('partials.admin_footer')
@endsection

@section('content')
    @yield('content')
@endsection
