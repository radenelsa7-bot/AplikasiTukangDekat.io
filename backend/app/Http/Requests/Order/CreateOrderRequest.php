<?php

namespace App\Http\Requests\Order;

use App\Models\ProviderProfile;
use App\Models\User;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class CreateOrderRequest extends FormRequest
{
    public function authorize(): bool
    {
        return $this->user()?->role === 'CUSTOMER';
    }

    protected function prepareForValidation(): void
    {
        $providerId = $this->input('provider_id');
        if (!is_numeric($providerId)) {
            return;
        }

        $existingProviderUser = User::where('id', (int) $providerId)
            ->where('role', 'PROVIDER')
            ->first();
        if ($existingProviderUser) {
            return;
        }

        // Backward compatibility: some older clients may still send provider_profile.id.
        // Normalize that to the actual provider user_id so validation and order assignment stay consistent.
        $providerProfile = ProviderProfile::with('user')->find((int) $providerId);
        if ($providerProfile?->user && $providerProfile->user->role === 'PROVIDER') {
            $this->merge([
                'provider_id' => $providerProfile->user->id,
            ]);
        }
    }

    public function rules(): array
    {
        return [
            'provider_id' => [
                'required',
                'integer',
                Rule::exists('users', 'id')->where('role', 'PROVIDER'),
            ],
            'provider_service_id' => 'nullable|exists:provider_services,id',
            'category_id' => 'required|exists:service_categories,id',
            'kota_id' => 'required|integer|exists:wilayah_kota,id',
            'kecamatan_id' => 'required|integer|exists:wilayah_kecamatan,id',
            'schedule_at' => 'required|date_format:Y-m-d H:i:s|after:now',
            'address' => 'required|string|max:500',
            'customer_latitude' => 'nullable|numeric|between:-90,90',
            'customer_longitude' => 'nullable|numeric|between:-180,180',
            'notes' => 'nullable|string|max:1000',
            'damage_level' => 'nullable|in:LIGHT,MEDIUM,HEAVY',
            'damage_description' => 'nullable|string|max:1000',
            'estimated_price_min' => 'nullable|integer|min:1|max:100000000',
            'estimated_price_max' => 'nullable|integer|min:1|max:100000000|gte:estimated_price_min',
            'estimated_price' => 'required|integer|min:1|max:100000000',
            'attachment_urls' => 'nullable|array|max:5',
            'attachment_urls.*' => 'required|url|max:2048',
            'damage_photos' => 'nullable|array|max:5',
            'damage_photos.*' => 'image|mimes:jpg,jpeg,png|max:4096',
        ];
    }

    public function messages(): array
    {
        return [
            'provider_id.required' => 'Provider is required.',
            'provider_id.exists' => 'The selected provider does not exist or is not a valid provider.',
            'category_id.required' => 'Service category is required.',
            'category_id.exists' => 'The selected service category does not exist.',
            'schedule_at.required' => 'Schedule time is required.',
            'schedule_at.date_format' => 'Schedule time must be in format Y-m-d H:i:s.',
            'schedule_at.after' => 'Schedule time must be in the future.',
            'address.required' => 'Address is required.',
            'estimated_price.required' => 'Estimated price is required.',
            'estimated_price.min' => 'Estimated price must be at least 1.',
            'estimated_price.max' => 'Estimated price cannot exceed 100,000,000.',
            'files.array' => 'Lampiran gambar harus berupa daftar file.',
            'files.*.file' => 'Setiap lampiran harus berupa file gambar.',
            'files.*.mimes' => 'Gambar hanya boleh berformat JPG atau PNG.',
            'files.*.max' => 'Ukuran setiap gambar maksimal 5 MB.',
        ];
    }
}
