<?php

namespace App\Http\Controllers\Admin;

use App\Http\Controllers\Controller;
use App\Models\ProviderPayout;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use App\Jobs\SendProviderPayoutJob;
use App\Models\ProviderPayoutAttempt;
use App\Traits\ApiResponse;

class ProviderPayoutController extends Controller
{
  use ApiResponse;
  public function index(Request $request)
  {
    $user = Auth::user();
    if (!$user || !in_array($user->role, ['TREASURER', 'ADMIN'])) {
      abort(403);
    }
    $perPage = (int) ($request->get('per_page', 20));
    $payouts = ProviderPayout::with('provider')->latest()->paginate($perPage);
    return view('admin.treasurer.provider_payouts', compact('payouts'));
  }

  public function detail(Request $request, $id)
  {
    $user = Auth::user();
    if (!$user || !in_array($user->role, ['TREASURER', 'ADMIN'])) {
      abort(403);
    }

    $p = ProviderPayout::with('attempts','provider')->findOrFail($id);
    return view('admin.treasurer.provider_payout_detail', compact('p'));
  }

  // Process single payout (mock)
  public function send(Request $request, $id)
  {
    $user = Auth::user();
    if (!$user || !in_array($user->role, ['TREASURER', 'ADMIN'])) {
      return $this->forbidden('Only admin and treasurer can process payouts.');
    }

    $p = ProviderPayout::findOrFail($id);
    if ($p->status !== 'PENDING') {
      return $this->error('Payout is not in pending status.', 400, 'PAYOUT_NOT_PENDING');
    }

    // read force_fail option from request
    $forceFail = (bool) ($request->input('force_fail') ?? false);

    // Dispatch job with option
    SendProviderPayoutJob::dispatch($p->id, ['force_fail' => $forceFail]);
    return $this->success(['id' => $p->id, 'force_fail' => $forceFail], 'Payout dispatched');
  }

  // Batch send
  public function sendBatch(Request $request)
  {
    $user = Auth::user();
    if (!$user || !in_array($user->role, ['TREASURER', 'ADMIN'])) {
      return $this->forbidden('Only admin and treasurer can process payouts.');
    }

    $ids = $request->input('ids', []);
    if (empty($ids) || !is_array($ids)) {
      return $this->validationError(['ids' => ['No payout IDs provided.']]);
    }

    $results = [];
    foreach ($ids as $id) {
      $p = ProviderPayout::find($id);
      if (!$p) {
        $results[$id] = 'not_found';
        continue;
      }
      if ($p->status !== 'PENDING') {
        $results[$id] = 'not_pending';
        continue;
      }

      $forceFail = (bool) ($request->input('force_fail') ?? false);
      SendProviderPayoutJob::dispatch($p->id, ['force_fail' => $forceFail]);
      $results[$id] = ['status' => 'dispatched', 'force_fail' => $forceFail];
    }

    return $this->success(['results' => $results], 'Batch dispatch completed');
  }

  public function retry(Request $request, $id)
  {
    $user = Auth::user();
    if (!$user || !in_array($user->role, ['TREASURER', 'ADMIN'])) {
      return $this->forbidden('Only admin and treasurer can retry payouts.');
    }

    $p = ProviderPayout::findOrFail($id);
    // allow retry only if FAILED
    if ($p->status !== 'FAILED') {
      return $this->error('Only failed payouts can be retried.', 400, 'INVALID_PAYOUT_STATUS');
    }

    // reset to PENDING so job can process it
    $p->status = 'PENDING';
    $p->error_message = null;
    $p->transaction_reference = null;
    $p->save();

    // dispatch with option to not force fail
    SendProviderPayoutJob::dispatch($p->id, ['force_fail' => false]);
    return $this->success(['id' => $p->id], 'Payout retry dispatched');
  }
}
