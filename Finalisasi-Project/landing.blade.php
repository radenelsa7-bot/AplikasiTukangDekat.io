<!doctype html>
<html lang="id">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width,initial-scale=1">
  <title>Tukang Dekat — Temukan Tukang Profesional Terdekat</title>
  <link rel="preconnect" href="https://fonts.googleapis.com">
  <link rel="preconnect" href="https://fonts.gstatic.com" crossorigin>
  <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@300;400;600;700&display=swap" rel="stylesheet">
  <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/css/bootstrap.min.css" rel="stylesheet">
  <link rel="stylesheet" href="/assets/landing.css">
  <meta name="description" content="Tukang Dekat - Temukan tukang profesional terdekat untuk kebutuhan rumah dan bangunan dengan cepat, aman, dan terpercaya.">
</head>
<body class="bg-light">
  <header class="sticky-top bg-white shadow-sm">
    <nav class="navbar navbar-expand-lg container py-3">
      <a class="navbar-brand d-flex align-items-center gap-2" href="#">
        <div class="brand-mark" aria-hidden="true"></div>
        <div>
          <div class="h5 mb-0 fw-bold text-dark">Tukang Dekat</div>
          <small class="text-muted">Temukan Tukang Profesional Terdekat</small>
        </div>
      </a>
      <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#navMenu">
        <span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="navMenu">
        <ul class="navbar-nav ms-auto me-3 align-items-lg-center">
          <li class="nav-item"><a class="nav-link" href="#">Beranda</a></li>
          <li class="nav-item"><a class="nav-link" href="#layanan">Layanan</a></li>
          <li class="nav-item"><a class="nav-link" href="#cara-kerja">Cara Kerja</a></li>
          <li class="nav-item"><a class="nav-link" href="#mitra">Mitra</a></li>
          <li class="nav-item"><a class="nav-link" href="#testimoni">Testimoni</a></li>
          <li class="nav-item"><a class="nav-link" href="#faq">FAQ</a></li>
          <li class="nav-item"><a class="nav-link" href="#kontak">Kontak</a></li>
        </ul>
        <div class="d-flex">
          <a href="#booking" class="btn btn-primary me-2">Cari Tukang</a>
        </div>
      </div>
    </nav>
  </header>

  <main>
    <!-- Hero -->
    <section class="container py-5">
      <div class="row align-items-center">
        <div class="col-lg-6" data-anim="fade-up">
          <span class="badge bg-success-subtle text-success mb-3">Jasa Profesional Terpercaya</span>
          <h1 class="display-5 fw-bold lh-sm">Temukan Tukang Profesional<br>Dekat Lokasi Anda</h1>
          <p class="lead text-muted">Platform yang membantu Anda menemukan tukang terpercaya untuk berbagai kebutuhan rumah, kantor, dan bangunan dengan cepat dan aman.</p>
          <div class="d-flex gap-2 mt-4">
            <a href="#booking" class="btn btn-primary btn-lg">Cari Tukang</a>
            <a href="#mitra" class="btn btn-outline-secondary btn-lg">Gabung Menjadi Mitra</a>
          </div>
        </div>
        <div class="col-lg-6 text-center position-relative" data-anim="float">
          <div class="hero-illustration mx-auto" aria-hidden="true">
            <!-- abstract shapes and technician illustrations (placeholders) -->
            <svg width="420" height="320" viewBox="0 0 420 320" fill="none" xmlns="http://www.w3.org/2000/svg">
              <rect x="0" y="0" width="420" height="320" rx="16" fill="#F8FAFC" />
              <g transform="translate(20,20)">
                <circle cx="60" cy="60" r="48" fill="#0E7490" opacity="0.12" />
                <rect x="140" y="40" width="140" height="160" rx="12" fill="#F97316" opacity="0.08" />
                <g>
                  <rect x="30" y="140" width="80" height="10" rx="5" fill="#1E293B" opacity="0.06" />
                </g>
              </g>
            </svg>
          </div>
        </div>
      </div>
    </section>

    <!-- Partners -->
    <section class="py-4 border-top">
      <div class="container text-center" id="mitra">
        <div class="d-flex gap-4 flex-wrap justify-content-center align-items-center">
          <span class="partner">Tukang Bersertifikat</span>
          <span class="partner">Vendor Material</span>
          <span class="partner">Developer</span>
          <span class="partner">Kontraktor</span>
          <span class="partner">UMKM</span>
          <span class="partner">Perusahaan Properti</span>
        </div>
      </div>
    </section>

    <!-- About -->
    <section class="container py-5">
      <div class="row g-4 align-items-center">
        <div class="col-md-6" data-anim="fade-right">
          <img src="/assets/icon-construction.svg" alt="Tukang sedang bekerja" class="img-fluid rounded shadow-sm" style="max-width:420px;" />
        </div>
        <div class="col-md-6" data-anim="fade-left">
          <h2 class="fw-bold">Kami Menghubungkan Anda dengan Tukang Terbaik</h2>
          <ul class="list-unstyled mt-3">
            <li class="mb-2">✅ Tukang Terverifikasi</li>
            <li class="mb-2">✅ Harga Transparan</li>
            <li class="mb-2">✅ Pengerjaan Cepat</li>
            <li class="mb-2">✅ Garansi Layanan</li>
            <li class="mb-2">✅ Dukungan Customer Service</li>
          </ul>
          <a href="#" class="btn btn-outline-primary mt-3">Pelajari Lebih Lanjut</a>
        </div>
      </div>
    </section>

    <!-- Stats -->
    <section class="py-5 text-white" style="background:var(--primary);">
      <div class="container">
        <div class="row text-center gy-4">
          <div class="col-md-3">
            <h3 class="display-6 fw-bold counter" data-target="15000">0</h3>
            <p class="mb-0">Pengguna Aktif</p>
          </div>
          <div class="col-md-3">
            <h3 class="display-6 fw-bold counter" data-target="5000">0</h3>
            <p class="mb-0">Mitra Tukang</p>
          </div>
          <div class="col-md-3">
            <h3 class="display-6 fw-bold">98%</h3>
            <p class="mb-0">Pelanggan Puas</p>
          </div>
          <div class="col-md-3">
            <h3 class="display-6 fw-bold counter" data-target="50">0</h3>
            <p class="mb-0">Kota Terjangkau</p>
          </div>
        </div>
      </div>
    </section>

    <!-- Services -->
    <section class="container py-5" id="layanan">
      <div class="d-flex justify-content-between align-items-center mb-4">
        <h2 class="fw-bold">Layanan Kami</h2>
        <a href="#" class="text-muted">Lihat Semua</a>
      </div>
      <div class="row g-4">
        <!-- Example service card -->
        @php
          $services = ['Tukang Bangunan','Tukang AC','Tukang Listrik','Tukang Ledeng','Tukang Cat','Renovasi Rumah','Cleaning Service','Furniture','Kanopi','CCTV'];
        @endphp
        @foreach($services as $s)
        <div class="col-sm-6 col-md-4 col-lg-3">
          <div class="card service-card h-100" data-anim="zoom-in">
            <div class="card-body text-center">
              <div class="icon-placeholder mb-3" aria-hidden="true"></div>
              <h5 class="card-title">{{ $s }}</h5>
              <p class="text-muted small">Profesional berpengalaman untuk kebutuhan Anda.</p>
            </div>
          </div>
        </div>
        @endforeach
      </div>
    </section>

    <!-- Why choose -->
    <section class="py-5 bg-white">
      <div class="container">
        <div class="row g-4 align-items-center">
          <div class="col-lg-6" data-anim="fade-right">
            <div class="row g-2">
              <div class="col-6"><img src="/assets/portfolio1.jpg" class="img-fluid rounded shadow-sm" alt=""></div>
              <div class="col-6"><img src="/assets/portfolio2.jpg" class="img-fluid rounded shadow-sm" alt=""></div>
              <div class="col-6 mt-2"><img src="/assets/portfolio3.jpg" class="img-fluid rounded shadow-sm" alt=""></div>
              <div class="col-6 mt-2"><img src="/assets/portfolio4.jpg" class="img-fluid rounded shadow-sm" alt=""></div>
            </div>
          </div>
          <div class="col-lg-6" data-anim="fade-left">
            <h3 class="fw-bold">Mengapa Memilih Tukang Dekat?</h3>
            <ul class="list-unstyled mt-3">
              <li class="mb-2">Tukang Terverifikasi</li>
              <li class="mb-2">Harga Transparan</li>
              <li class="mb-2">Booking Mudah</li>
              <li class="mb-2">Respon Cepat</li>
              <li class="mb-2">Garansi Pekerjaan</li>
              <li class="mb-2">Customer Support</li>
            </ul>
          </div>
        </div>
      </div>
    </section>

    <!-- How it works -->
    <section class="container py-5" id="cara-kerja">
      <h2 class="fw-bold text-center mb-4">Cara Kerja</h2>
      <div class="row g-4 justify-content-center">
        <div class="col-md-3 text-center" data-anim="fade-up">
          <div class="step p-4 rounded shadow-sm">1<br><strong>Cari Layanan</strong></div>
        </div>
        <div class="col-md-3 text-center" data-anim="fade-up">
          <div class="step p-4 rounded shadow-sm">2<br><strong>Pilih Tukang</strong></div>
        </div>
        <div class="col-md-3 text-center" data-anim="fade-up">
          <div class="step p-4 rounded shadow-sm">3<br><strong>Pekerjaan Selesai</strong></div>
        </div>
      </div>
    </section>

    <!-- Booking -->
    <section class="py-5 bg-light" id="booking">
      <div class="container">
        <div class="row g-4 align-items-start">
          <div class="col-lg-6" data-anim="fade-right">
            <div class="card p-4 shadow-sm">
              <h4 class="fw-bold">Pesan Tukang Sekarang</h4>
              <form class="mt-3" id="bookingForm">
                <div class="mb-3"><label class="form-label">Nama</label><input class="form-control" required></div>
                <div class="mb-3"><label class="form-label">Nomor HP</label><input class="form-control" required></div>
                <div class="mb-3"><label class="form-label">Kota</label><input class="form-control" required></div>
                <div class="mb-3"><label class="form-label">Jenis Layanan</label><select class="form-select"><option>Tukang Bangunan</option></select></div>
                <div class="mb-3"><label class="form-label">Jadwal</label><input type="date" class="form-control"></div>
                <div class="mb-3"><label class="form-label">Catatan</label><textarea class="form-control" rows="3"></textarea></div>
                <button type="submit" class="btn btn-primary">Pesan Sekarang</button>
              </form>
            </div>
          </div>
          <div class="col-lg-6" data-anim="fade-left">
            <div class="card p-4 shadow-sm">
              <h5 class="fw-bold">Testimoni Pelanggan</h5>
              <blockquote class="blockquote mb-0 mt-3">
                <p>"Cepat dan profesional. Tukang Dekat membantu menyelesaikan renovasi rumah saya dengan baik."</p>
                <footer class="blockquote-footer">Rina, Jakarta</footer>
              </blockquote>
            </div>
          </div>
        </div>
      </div>
    </section>

    <!-- Portfolio -->
    <section class="container py-5">
      <h2 class="fw-bold mb-4">Portofolio</h2>
      <div class="row g-3">
        @for($i=1;$i<=6;$i++)
            <div class="col-sm-6 col-md-4">
          <div class="card portfolio-card overflow-hidden">
            <img src="/assets/icon-construction.svg" class="card-img-top" alt="Project">
            <div class="card-body">
              <h5 class="card-title">Contoh Project {{$i}}</h5>
              <p class="small text-muted">Renovasi, instalasi, dan perbaikan profesional.</p>
            </div>
          </div>
        </div>
        @endfor
      </div>
    </section>

    <!-- FAQ -->
    <section class="py-5 bg-white" id="faq">
      <div class="container">
        <h2 class="fw-bold mb-4">FAQ</h2>
        <div class="accordion" id="faqAcc">
          @for($i=1;$i<=6;$i++)
          <div class="accordion-item">
            <h2 class="accordion-header" id="heading{{$i}}">
              <button class="accordion-button collapsed" type="button" data-bs-toggle="collapse" data-bs-target="#collapse{{$i}}">Pertanyaan {{$i}} ?</button>
            </h2>
            <div id="collapse{{$i}}" class="accordion-collapse collapse" data-bs-parent="#faqAcc">
              <div class="accordion-body">Jawaban singkat dan jelas untuk pertanyaan {{$i}}.</div>
            </div>
          </div>
          @endfor
        </div>
      </div>
    </section>

    <!-- Articles -->
    <section class="container py-5">
      <h2 class="fw-bold mb-4">Artikel</h2>
      <div class="row g-4">
        @foreach(['Tips Memilih Tukang','Cara Renovasi Rumah','Estimasi Biaya Bangunan'] as $a)
        <div class="col-md-4">
          <div class="card h-100">
            <img src="/assets/article-placeholder.jpg" class="card-img-top" alt="">
            <div class="card-body">
              <h5 class="card-title">{{ $a }}</h5>
              <p class="small text-muted">Ringkasan singkat artikel yang membantu pengguna.</p>
            </div>
          </div>
        </div>
        @endforeach
      </div>
    </section>

    <!-- Footer -->
    <footer class="py-5 bg-dark text-light">
      <div class="container">
        <div class="row">
          <div class="col-md-3">
            <h5 class="fw-bold">Tentang</h5>
            <p class="small text-muted">Tukang Dekat membantu Anda menemukan tukang profesional terdekat dengan mudah.</p>
          </div>
          <div class="col-md-3">
            <h5 class="fw-bold">Layanan</h5>
            <ul class="list-unstyled small text-muted"><li>Tukang Bangunan</li><li>AC & Listrik</li><li>Plumbing</li></ul>
          </div>
          <div class="col-md-3">
            <h5 class="fw-bold">Perusahaan</h5>
            <ul class="list-unstyled small text-muted"><li>Mitra</li><li>Karir</li><li>Kontak</li></ul>
          </div>
          <div class="col-md-3">
            <h5 class="fw-bold">Kontak</h5>
            <p class="small text-muted">support@tukangdekat.id<br>+62 811-xxx-xxxx</p>
          </div>
        </div>
        <div class="text-center mt-4 small text-muted">© {{ date('Y') }} Tukang Dekat. Semua hak dilindungi.</div>
      </div>
    </footer>
  </main>

  <script src="https://cdn.jsdelivr.net/npm/bootstrap@5.3.0/dist/js/bootstrap.bundle.min.js"></script>
  <script src="/assets/landing.js"></script>
</body>
</html>
