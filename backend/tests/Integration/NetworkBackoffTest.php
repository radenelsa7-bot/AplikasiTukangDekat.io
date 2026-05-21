<?php

namespace Tests\Integration;

use Tests\TestCase;

class NetworkBackoffTest extends TestCase
{
    public function setUp(): void
    {
        parent::setUp();
    }

    public function test_retries_on_5xx_then_succeeds()
    {
        \Illuminate\Support\Facades\Http::fakeSequence()
            ->push(['message' => 'server error'], 500)
            ->push(['id' => 'tx_123'], 200);

        $gateway = new \App\Services\Payout\XenditPayoutGateway('test_key', 'https://api.xendit.test');
        $res = $gateway->send(['amount' => 10000, 'account_number' => '0000000000']);

        $this->assertTrue($res['success']);
        $this->assertEquals('tx_123', $res['transaction_reference']);
        \Illuminate\Support\Facades\Http::assertSentCount(2);
    }

    public function test_retries_on_connection_exception_then_succeeds()
    {
        $called = 0;
        \Illuminate\Support\Facades\Http::fake(function ($request) use (&$called) {
            $called++;
            if ($called === 1) {
                throw new \Illuminate\Http\Client\ConnectionException('connection failed');
            }
            return \Illuminate\Support\Facades\Http::response(['id' => 'tx_456'], 200);
        });

        $gateway = new \App\Services\Payout\XenditPayoutGateway('test_key', 'https://api.xendit.test');
        $res = $gateway->send(['amount' => 5000, 'account_number' => '1111111111']);

        $this->assertTrue($res['success']);
        $this->assertEquals('tx_456', $res['transaction_reference']);
        $this->assertGreaterThanOrEqual(2, $called);
    }
}
