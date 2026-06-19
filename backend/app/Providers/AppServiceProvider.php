<?php

namespace App\Providers;

use Illuminate\Support\Facades\URL;
use Illuminate\Support\ServiceProvider;
use App\Services\Payout\PayoutGatewayInterface;
use App\Services\Payout\XenditPayoutGateway;
use App\Services\Payout\MockPayoutGateway;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        // Bind payout gateway implementation based on environment
        $this->app->singleton(PayoutGatewayInterface::class, function ($app) {
            $configured = config('payout.gateway', env('PAYOUT_GATEWAY', 'mock'));

            if ($configured === 'xendit') {
                $xenditKey = env('XENDIT_API_KEY');
                return new XenditPayoutGateway($xenditKey, env('XENDIT_BASE_URL', 'https://api.xendit.co'));
            }

            // Default to mock gateway
            return new MockPayoutGateway();
        });
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Force HTTPS jika berada di env production, staging, atau FORCE_HTTPS bernilai true
        if (env('FORCE_HTTPS', false) || $this->app->environment(['production', 'staging'])) {
            URL::forceScheme('https');
        }
    }
}
