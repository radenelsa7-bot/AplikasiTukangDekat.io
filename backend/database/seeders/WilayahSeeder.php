<?php

namespace Database\Seeders;

use App\Models\WilayahKecamatan;
use App\Models\WilayahKota;
use Illuminate\Database\Seeder;

class WilayahSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        $regions = [
            'Jakarta Pusat' => ['Gambir', 'Tanah Abang', 'Menteng', 'Senen'],
            'Jakarta Barat' => ['Cengkareng', 'Grogol Petamburan', 'Kembangan', 'Kalideres'],
            'Jakarta Selatan' => ['Kebayoran Baru', 'Setiabudi', 'Pancoran', 'Tebet'],
            'Jakarta Timur' => ['Cakung', 'Duren Sawit', 'Jatinegara', 'Makasar'],
            'Jakarta Utara' => ['Kelapa Gading', 'Tanjung Priok', 'Penjaringan', 'Koja'],
            'Bandung' => ['Coblong', 'Sukajadi', 'Bandung Wetan', 'Cicendo'],
            'Bekasi' => ['Bekasi Barat', 'Bekasi Selatan', 'Bekasi Utara', 'Bekasi Timur'],
            'Tangerang' => ['Ciledug', 'Karawaci', 'Cipondoh', 'Tangerang'],
            'Depok' => ['Beji', 'Cimanggis', 'Pancoran Mas', 'Sukmajaya'],
            'Bogor' => ['Bogor Barat', 'Bogor Tengah', 'Bogor Selatan', 'Bogor Utara'],
        ];

        foreach ($regions as $cityName => $districts) {
            $city = WilayahKota::where('name', $cityName)->first();
            if (!$city) {
                continue;
            }

            foreach ($districts as $districtName) {
                WilayahKecamatan::updateOrCreate(
                    [
                        'kota_id' => $city->id,
                        'name' => $districtName,
                    ],
                    []
                );
            }
        }
    }
}
