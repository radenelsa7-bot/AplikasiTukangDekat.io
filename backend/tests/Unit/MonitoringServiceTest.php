<?php

namespace Tests\Unit;

use Tests\TestCase;
use App\Services\MonitoringService;

class MonitoringServiceTest extends TestCase
{
    public function test_alert_severity_returns_none_below_threshold()
    {
        $service = new class extends MonitoringService {
            public function failedPayoutsCount(int $windowMinutes = null): int
            {
                return 1;
            }
        };

        config(['monitoring.payout_failure_alert_threshold' => 3]);
        config(['monitoring.payout_failure_critical_threshold' => 5]);

        $this->assertSame('none', $service->alertSeverity(60));
    }

    public function test_alert_severity_returns_warning_when_threshold_is_reached()
    {
        $service = new class extends MonitoringService {
            public function failedPayoutsCount(int $windowMinutes = null): int
            {
                return 3;
            }
        };

        config(['monitoring.payout_failure_alert_threshold' => 3]);
        config(['monitoring.payout_failure_critical_threshold' => 5]);

        $this->assertSame('warning', $service->alertSeverity(60));
    }

    public function test_alert_severity_returns_critical_when_critical_threshold_is_exceeded()
    {
        $service = new class extends MonitoringService {
            public function failedPayoutsCount(int $windowMinutes = null): int
            {
                return 8;
            }
        };

        config(['monitoring.payout_failure_alert_threshold' => 3]);
        config(['monitoring.payout_failure_critical_threshold' => 5]);

        $this->assertSame('critical', $service->alertSeverity(60));
    }
}
