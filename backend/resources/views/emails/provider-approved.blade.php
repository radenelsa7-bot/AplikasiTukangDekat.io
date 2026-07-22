<![CDATA[<!DOCTYPE html>
<html lang="id">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <style>
        body {
            margin: 0;
            padding: 0;
            background-color: #f4f7fc;
            font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif;
        }
        .email-container {
            max-width: 600px;
            margin: 30px auto;
            background: #ffffff;
            border-radius: 16px;
            overflow: hidden;
            box-shadow: 0 8px 30px rgba(0,0,0,0.08);
        }
        .header {
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            padding: 40px 30px;
            text-align: center;
        }
        .header h1 {
            margin: 0;
            color: #ffffff;
            font-size: 28px;
            font-weight: 700;
            letter-spacing: 0.5px;
        }
        .header .subtitle {
            color: rgba(255,255,255,0.85);
            font-size: 16px;
            margin-top: 8px;
        }
        .badge {
            display: inline-block;
            background: rgba(255,255,255,0.2);
            color: #ffffff;
            padding: 6px 20px;
            border-radius: 50px;
            font-size: 14px;
            margin-top: 12px;
            font-weight: 600;
        }
        .body-content {
            padding: 40px 30px;
            color: #333333;
        }
        .body-content h2 {
            color: #1e293b;
            font-size: 22px;
            margin-top: 0;
        }
        .body-content p {
            line-height: 1.7;
            font-size: 16px;
            color: #475569;
        }
        .highlight-box {
            background: #eef2ff;
            border-left: 4px solid #2563eb;
            padding: 16px 20px;
            border-radius: 8px;
            margin: 24px 0;
        }
        .highlight-box p {
            margin: 0;
            color: #1e293b;
        }
        .btn-login {
            display: inline-block;
            background: linear-gradient(135deg, #2563eb, #1d4ed8);
            color: #ffffff !important;
            text-decoration: none;
            padding: 14px 36px;
            border-radius: 50px;
            font-size: 16px;
            font-weight: 600;
            margin: 20px 0 8px;
            box-shadow: 0 4px 14px rgba(37, 99, 235, 0.35);
        }
        .footer {
            background: #f8fafc;
            padding: 24px 30px;
            text-align: center;
            border-top: 1px solid #e2e8f0;
        }
        .footer p {
            margin: 4px 0;
            font-size: 13px;
            color: #94a3b8;
        }
        .footer a {
            color: #2563eb;
            text-decoration: none;
        }
    </style>
</head>
<body>
    <div class="email-container">
        <div class="header">
            <h1>🎉 Selamat Datang di TukangDekat!</h1>
            <div class="subtitle">Akun Provider Anda telah diverifikasi</div>
            <div class="badge">✓ AKTIF</div>
        </div>

        <div class="body-content">
            <h2>Halo, {{ $providerName }}!</h2>
            <p>
                Kami dengan senang hati menginformasikan bahwa pendaftaran akun Provider Anda 
                atas nama <strong>{{ $businessName }}</strong> telah <strong>disetujui</strong> dan 
                status akun Anda kini <strong>AKTIF</strong>.
            </p>

            <div class="highlight-box">
                <p>
                    ✅ Anda sekarang dapat menerima pesanan dari pelanggan di wilayah Anda.<br>
                    ✅ Mulai tawarkan jasa terbaik Anda melalui aplikasi TukangDekat.<br>
                    ✅ Pantau dan kelola pesanan langsung dari dashboard Provider.
                </p>
            </div>

            <p style="text-align: center;">
                <a href="{{ $appUrl }}/login" class="btn-login">Login ke Aplikasi</a>
            </p>
            <p style="text-align: center; font-size: 14px; color: #64748b;">
                Klik tombol di atas untuk masuk dan mulai menggunakan akun Anda.
            </p>
        </div>

        <div class="footer">
            <p>&copy; 2026 TukangDekat. All rights reserved.</p>
            <p>
                Jika Anda memiliki pertanyaan, hubungi kami di 
                <a href="mailto:support@tukangdekat.com">support@tukangdekat.com</a>
            </p>
            <p style="font-size: 11px; color: #cbd5e1;">
                Email ini dikirim secara otomatis. Harap tidak membalas email ini.
            </p>
        </div>
    </div>
</body>
</html>
]]>