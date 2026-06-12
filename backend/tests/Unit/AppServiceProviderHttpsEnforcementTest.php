<?php

namespace Tests\Unit;

use App\Providers\AppServiceProvider;
use Illuminate\Foundation\Application;
use Illuminate\Support\Facades\URL;
use PHPUnit\Framework\TestCase;

class AppServiceProviderHttpsEnforcementTest extends TestCase
{
    public function test_https_scheme_is_forced_in_production_environment(): void
    {
        $app = $this->createMock(Application::class);
        $app->expects($this->any())
            ->method('environment')
            ->willReturn(true);

        $provider = new AppServiceProvider($app);

        URL::shouldReceive('forceScheme')
            ->with('https')
            ->once();

        $provider->boot();
    }

    public function test_https_can_be_forced_explicitly_via_env(): void
    {
        $app = $this->createMock(Application::class);
        $app->expects($this->any())
            ->method('environment')
            ->willReturn(false);

        putenv('FORCE_HTTPS=true');
        $provider = new AppServiceProvider($app);

        URL::shouldReceive('forceScheme')
            ->with('https')
            ->once();

        $provider->boot();

        putenv('FORCE_HTTPS=false');
    }
}
