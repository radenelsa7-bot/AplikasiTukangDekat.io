<?php

use Illuminate\Foundation\Application;
use Illuminate\Foundation\Configuration\Exceptions;
use Illuminate\Foundation\Configuration\Middleware;
use Illuminate\Console\Scheduling\Schedule;
use Illuminate\Http\Exceptions\ThrottleRequestsException;

return Application::configure(basePath: dirname(__DIR__))
    ->withRouting(
        web: __DIR__ . '/../routes/web.php',
        api: __DIR__ . '/../routes/api.php',
        commands: __DIR__ . '/../routes/console.php',
        health: '/up',
    )
    ->withMiddleware(function (Middleware $middleware): void {
        $middleware->alias([
            'role' => App\Http\Middleware\CheckRole::class,
        ]);
    })
    ->withSchedule(function (Schedule $schedule): void {
        $schedule->command('payouts:process')->dailyAt('01:00')->withoutOverlapping();
        $schedule->command('payouts:process-pending --limit=25')->everyFiveMinutes()->withoutOverlapping();
        $schedule->command('payouts:alert --since=60')->everyTenMinutes()->withoutOverlapping();
    })
    ->withExceptions(function (Exceptions $exceptions): void {
        $exceptions->shouldRenderJsonWhen(function ($request, $exception) {
            return $request->is('api/*');
        });

        $exceptions->renderable(function (ThrottleRequestsException $exception, $request) {
            return response()->json(
                [
                    'message' => 'Too Many Requests',
                    'errors' => [
                        'code' => 'TOO_MANY_REQUESTS',
                        'details' => 'You have exceeded the allowed request rate.',
                    ],
                ],
                429,
                $exception->getHeaders()
            );
        });
    })->create();
