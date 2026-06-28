@extends('layouts.customer')

@section('title', 'Tukang Dekat - Temukan Tukang Profesional Terdekat')

@section('content')
  @include('partials.landing.header')
  @include('partials.landing.hero')
  @include('partials.landing.services')
  @include('partials.landing.booking_form')
  @include('partials.landing.footer')
@endsection
