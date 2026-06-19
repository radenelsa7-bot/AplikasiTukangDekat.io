<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Console\Scheduling\Schedule;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        api: __DIR__ . '/../routes/api.php',
        commands: __DIR__ . '/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        // 1. Mengatasi error proxy dengan metode bawaan Laravel modern
        $middleware->trustProxies(at: '*');

        // 2. Menggabungkan alias lama ('role') dengan alias peran baru
        $middleware->alias([
            'role'           => \App\Http\Middleware\CheckRole::class,
            'role.customer'  => \App\Http\Middleware\EnsureCustomerRole::class,
            'role.provider'  => \App\Http\Middleware\EnsureProviderRole::class,
            'role.admin'     => \App\Http\Middleware\EnsureAdminRole::class,
            'role.treasurer' => \App\Http\Middleware\EnsureTreasurerRole::class,
        ]);
    })
    ->withSchedule(function (Schedule $schedule): void {
        // Jadwal pemrosesan payout bawaan milikmu tetap dipertahankan
        $schedule->command('payouts:process')->dailyAt('01:00')->withoutOverlapping();
        $schedule->command('payouts:process-pending --limit=25')->everyFiveMinutes()->withoutOverlapping();
        $schedule->command('payouts:alert --since=60')->everyTenMinutes()->withoutOverlapping();
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        //
    })->create();
