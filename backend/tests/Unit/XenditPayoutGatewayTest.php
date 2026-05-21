<?php

namespace Tests\Unit;

use App\Services\Payout\XenditPayoutGateway;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class XenditPayoutGatewayTest extends TestCase
{
    public function test_send_success_returns_transaction_reference()
    {
        Http::fakeSequence()
            ->push(json_encode(['id' => 'tx-1']), 200);

        $gateway = new XenditPayoutGateway('test_key', 'https://api.test');

        $res = $gateway->send(['amount' => 10000, 'bank_code' => 'MANDIRI', 'account_number' => '000111222333']);

        $this->assertTrue($res['success']);
        $this->assertSame('tx-1', $res['transaction_reference']);
    }

    public function test_validation_error_then_sanitized_form_fallback_succeeds()
    {
        // Sequence: first call -> 422 validation error (account_holder_name disallowed)
        // second call -> 422 validation error again
        // third call -> 200 success
        $validationBody = json_encode([
            'error_code' => 'API_VALIDATION_ERROR',
            'errors' => [
                ['message' => '\"account_holder_name\" is not allowed', 'path' => ['account_holder_name']]
            ]
        ]);

        Http::fakeSequence()
            ->push($validationBody, 422)
            ->push($validationBody, 422)
            ->push(json_encode(['id' => 'tx-2']), 200);

        $gateway = new XenditPayoutGateway('test_key', 'https://api.test');

        $res = $gateway->send(['amount' => 20000, 'bank_code' => 'MANDIRI', 'account_number' => '000111222333', 'account_holder_name' => 'Provider Name']);

        $this->assertTrue($res['success']);
        $this->assertSame('tx-2', $res['transaction_reference']);
    }

    public function test_request_forbidden_returns_error_meta()
    {
        Http::fakeSequence()
            ->push(json_encode(['error_code' => 'REQUEST_FORBIDDEN_ERROR', 'message' => 'forbidden']), 403);

        $gateway = new XenditPayoutGateway('test_key', 'https://api.test');

        $res = $gateway->send(['amount' => 5000, 'bank_code' => 'MANDIRI', 'account_number' => '000111222333']);

        $this->assertFalse($res['success']);
        $this->assertArrayHasKey('meta', $res);
        $this->assertSame('REQUEST_FORBIDDEN_ERROR', data_get($res, 'meta.error_code'));
    }
}
