@extends('layouts.base')

@section('header')
    @include('partials.customer_header')
@endsection

@section('footer')
    @include('partials.customer_footer')
@endsection

@section('content')
    @yield('content')
@endsection
