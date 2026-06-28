<section class="py-5 bg-light" id="booking">
  <div class="container">
    <div class="row g-4 align-items-start">
      <div class="col-lg-6" data-anim="fade-right">
        <div class="card p-4 shadow-sm">
          <h4 class="fw-bold">Pesan Tukang Sekarang</h4>
          <form class="mt-3" id="bookingForm">
            @csrf
            <div class="mb-3"><label class="form-label">Nama</label><input name="name" class="form-control" required></div>
            <div class="mb-3"><label class="form-label">Nomor HP</label><input name="phone" class="form-control" required></div>
            <div class="mb-3"><label class="form-label">Kota</label><input name="city" class="form-control" required></div>
            <div class="mb-3"><label class="form-label">Jenis Layanan</label>
              <select name="service" class="form-select">
                <option>Tukang Bangunan</option>
                <option>Tukang AC</option>
                <option>Tukang Listrik</option>
                <option>Plumbing</option>
              </select>
            </div>
            <div class="mb-3"><label class="form-label">Jadwal</label><input type="date" name="schedule" class="form-control"></div>
            <div class="mb-3"><label class="form-label">Catatan</label><textarea name="notes" class="form-control" rows="3"></textarea></div>
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
