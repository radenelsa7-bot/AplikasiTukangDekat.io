<section class="container py-5" id="layanan">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h2 class="fw-bold">Layanan Kami</h2>
    <a href="#" class="text-muted">Lihat Semua</a>
  </div>
  <div class="row g-4">
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
