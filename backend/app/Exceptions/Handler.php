<?php

namespace App\Exceptions;

use Throwable;
use Illuminate\Foundation\Exceptions\Handler as ExceptionHandler;

class Handler extends ExceptionHandler
{
    /**
     * Report or log an exception.
     */
    public function report(Throwable $exception)
    {
        // Kirim ke Sentry jika terkonfigurasi
        if (app()->bound('sentry') && env('SENTRY_LARAVEL_DSN')) {
            try {
                app('sentry')->captureException($exception);
            } catch (\Throwable $_) {
                // jangan ganggu flow jika Sentry gagal
            }
        }

        parent::report($exception);
    }
}
