<?php

namespace App\Providers;

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
        // Force HTTPS in production environment
        if ($this->app->environment('production')) {
            \Illuminate\Support\Facades\URL::forceScheme('https');
            
            // Trust proxies for HTTPS headers from load balancers
            \Illuminate\Support\Facades\Request::setTrustedProxies(
                ['*'],
                \Illuminate\Http\Request::HEADER_X_FORWARDED_ALL
            );
        }
        // Register route middleware aliases for role enforcement
        if ($this->app->has('router')) {
            $router = $this->app->make('router');
            $router->aliasMiddleware('role.customer', \App\Http\Middleware\EnsureCustomerRole::class);
            $router->aliasMiddleware('role.provider', \App\Http\Middleware\EnsureProviderRole::class);
            $router->aliasMiddleware('role.admin', \App\Http\Middleware\EnsureAdminRole::class);
            $router->aliasMiddleware('role.treasurer', \App\Http\Middleware\EnsureTreasurerRole::class);
        }
    }
}
