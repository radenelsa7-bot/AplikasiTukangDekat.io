<?php

namespace Tests\Feature;

use App\Models\FinalPriceApproval;
use App\Models\Order;
use App\Models\Payment;
use App\Models\ProviderProfile;
use App\Models\ProviderCoverage;
use App\Models\ServiceCategory;
use App\Models\User;
use App\Models\ProviderService;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;
use Illuminate\Support\Facades\DB;

class PaymentStepFlowTest extends TestCase
{
    use RefreshDatabase;

    /**
     * Flow yang diuji:
     * - Customer create order -> DP dibuat
     * - Provider accept -> order ACCEPTED
     * - DP paid -> startWork boleh
     * - Provider startWork -> IN_PROGRESS
     * - Provider completeOrder -> COMPLETED + FinalPriceApproval PENDING
     * - Customer approve final -> FinalPriceApproval APPROVED + Payment FINAL dibuat
     * - Customer confirm FINAL -> payment PAID + order CLOSED
     */
    public function test_dp_to_final_approval_to_closed_flow(): void
    {
        // --- arrange: minimal wilayah coverage agar createOrder sukses ---
        $category = ServiceCategory::factory()->create();

        // Gunakan factory tabel wilayah yang sesuai di database test harness.
        // CoverageAreaRestrictionTest sebelumnya menandakan ada kebutuhan distabilkan factory; namun di sini kita tetap gunakan
        // struktur minimal yang dipakai oleh model wilayah.
        //
        // Jika tabel wilayah tidak bernama wilayah_kota/wilayah_kecamatan atau kolomnya berbeda,
        // maka mengikuti skema model existing di repo: 
        // - WilayahKota::table = wilayah_kota
        // - WilayahKecamatan::table = wilayah_kecamatan
        // Dengan kolom:
        // - wilayah_kecamatan: kota_id, name (kode_pos mungkin tidak ada di sqlite)
        $kota = DB::table('wilayah_kota')->insertGetId([
            'name' => 'Kota Test',
        ]);

        $kecamatanPayload = [
            'kota_id' => $kota,
            'name' => 'Kecamatan Test',
        ];

        // kode_pos bersifat opsional untuk test coverage
        try {
            $kecamatanPayload['kode_pos'] = '12345';
            $kecamatan = DB::table('wilayah_kecamatan')->insertGetId($kecamatanPayload);
        } catch (\Throwable $e) {
            // jika kolom kode_pos tidak ada di skema sqlite, buat tanpa kode_pos
            $kecamatan = DB::table('wilayah_kecamatan')->insertGetId([
                'kota_id' => $kota,
                'name' => 'Kecamatan Test',
            ]);
        }



        $customer = User::factory()->create(['role' => 'CUSTOMER']);
        $provider = User::factory()->create(['role' => 'PROVIDER']);

        // Provider profile + service
        $profile = ProviderProfile::create([
            'user_id' => $provider->id,
            'business_name' => 'PT Test',
            'is_verified' => true,
        ]);

        $service = ProviderService::factory()->create([
            'provider_profile_id' => $profile->id,
            'category_id' => $category->id,
        ]);

        ProviderCoverage::factory()->create([
            'provider_profile_id' => $profile->id,
            'kecamatan_id' => $kecamatan,
        ]);

        // sanity check role
        $this->assertSame('PROVIDER', $provider->fresh()->role);

        // /api/user returns currently authenticated user (sanctum)

        // 1) customer create order
        $estimated = 200000;

        $createResp = $this->actingAs($customer, 'sanctum')
            ->postJson('/api/orders', [
                'provider_id' => $provider->id,
                'category_id' => $category->id,
                'provider_service_id' => $service->id,
                'kota_id' => $kota,
                'kecamatan_id' => $kecamatan,
                'schedule_at' => now()->addDay()->format('Y-m-d H:i:s'),

                'address' => 'Jl. Test',
                'estimated_price' => $estimated,
                'notes' => 'tes',
                'status' => 'ACTIVE',

            ]);

        $createResp->assertStatus(201);
        $orderId = $createResp->json('data.id');
        $this->assertNotNull($orderId);

        $order = Order::with('payments')->findOrFail($orderId);
        $dpPayment = $order->payments->firstWhere('payment_type', 'DP');
        $this->assertNotNull($dpPayment);

        // 2) provider accept order

        $acceptResp = $this->actingAs($provider, 'sanctum')
            ->postJson('/api/orders/' . $orderId . '/respond', [
                'action' => 'accept',
                'reason' => 'ok',
            ]);
        $acceptResp->assertStatus(200);

        $order->refresh();
        $this->assertSame('ACCEPTED', $order->status);

        // 3) pay DP: set payment DP -> PAID via confirmPayment
        // (di flow ini, external midtrans check bisa fail; repo logic akan fallback markPaymentAsPaid)
        // Kita buat external_payment_id kosong agar simulation path langsung.
        $dpPayment->update([
            'external_payment_id' => $dpPayment->external_payment_id ?: 'PAY-DP-' . $dpPayment->id,
        ]);

        $dpConfirmResp = $this->actingAs($customer, 'sanctum')
            ->postJson('/api/payments/' . $dpPayment->id . '/confirm', []);
        $dpConfirmResp->assertStatus(200);

        $order->refresh();
        // order masih CREATED/ACCEPTED sampai provider startWork; startWork yang mengubah IN_PROGRESS

        // 4) provider startWork
        $startResp = $this->actingAs($provider, 'sanctum')
            ->postJson('/api/orders/' . $orderId . '/start-work', []);
        $startResp->assertStatus(200);

        $order->refresh();
        $this->assertSame('IN_PROGRESS', $order->status);

        // 5) provider complete order (final_price >= estimated)
        $finalPrice = 240000;
        $completeResp = $this->actingAs($provider, 'sanctum')
            ->postJson('/api/orders/' . $orderId . '/complete', [
                'final_price' => $finalPrice,
                'notes' => 'done',
            ]);
        $completeResp->assertStatus(200);

        $order->refresh();
        $this->assertSame('COMPLETED', $order->status);

        $approval = FinalPriceApproval::where('order_id', $orderId)->latest('id')->first();
        $this->assertNotNull($approval);
        $this->assertSame('PENDING', $approval->approval_status);

        // 6) customer approve final
        $approveResp = $this->actingAs($customer, 'sanctum')
            ->postJson('/api/orders/' . $orderId . '/final-price/approve', [
                'action' => 'approve',
            ]);
        $approveResp->assertStatus(200);

        $approval->refresh();
        $this->assertSame('APPROVED', $approval->approval_status);

        // payment FINAL dibuat UNPAID
        $finalPayment = Payment::where('order_id', $orderId)->where('payment_type', 'FINAL')->first();
        $this->assertNotNull($finalPayment);

        // 7) customer confirm FINAL -> CLOSED
        $finalPayment->refresh();
        $finalConfirmResp = $this->actingAs($customer, 'sanctum')
            ->postJson('/api/payments/' . $finalPayment->id . '/confirm', []);
        $finalConfirmResp->assertStatus(200);

        $order->refresh();
        $this->assertSame('CLOSED', $order->status);

        $finalPayment->refresh();
        $this->assertSame('PAID', $finalPayment->status);
    }
}
