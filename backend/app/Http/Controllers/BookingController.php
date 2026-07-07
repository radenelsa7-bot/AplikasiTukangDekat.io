<?php

namespace App\Http\Controllers;

use App\Http\Requests\BookingRequest;
use App\Models\Booking;
use Illuminate\Http\Request;

class BookingController extends Controller
{
    public function store(BookingRequest $request)
    {
        $data = $request->validated();
        $booking = Booking::create($data);

        if (request()->wantsJson() || request()->ajax()) {
            return response()->json(['success' => true, 'id' => $booking->id]);
        }

        return redirect()->back()->with('status', 'Booking berhasil dikirim. Kami akan menghubungi Anda.');
    }
}
