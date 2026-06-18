# TODO - Perbaikan warning/issue `flutter analyze`

## Informasi yang didapat
- Issue berasal dari beberapa file:
  - `mobile/lib/app/theme/app_theme.dart`: penggunaan `background`/`onBackground` (deprecated) pada `ColorScheme`
  - `mobile/lib/features/home/catalog_page.dart`: style `withOpacity(...)` deprecated + lint `curly_braces_in_flow_control_structures` + kemungkinan formatting `if` tanpa blok
  - `mobile/lib/features/home/edit_profile_dialog.dart`: lint `invalid_use_of_visible_for_testing_member` + `invalid_use_of_protected_member` untuk member `state`, serta `use_build_context_synchronously` pada penggunaan `context` setelah await
  - `mobile/lib/features/home/home_page.dart`, `my_orders_page.dart`, `order_detail_page.dart`: `withOpacity` deprecated dan `use_build_context_synchronously`
  - `mobile/lib/shared/widgets/site_footer.dart`: `withOpacity` deprecated
  - `mobile/lib/main.dart`: import `features/auth/splash_page.dart` unused

## Plan (rencana edit)
1. `app_theme.dart`
   - Ganti penggunaan `background`/`onBackground` di `ColorScheme` dengan `surface`/`onSurface` (sesuai lint: `background` deprecated, gunakan `surface`).

2. `catalog_page.dart`
   - Perbaiki lint `curly_braces_in_flow_control_structures` dengan membungkus statement `if (...)` yang body-nya bukan block.
   - Ganti semua `color.withOpacity(x)` untuk kasus lint deprecated menjadi `color.withValues(alpha: x)` (atau gunakan pendekatan yang direkomendasikan analyzer).

3. `edit_profile_dialog.dart`
   - Perbaiki `use_build_context_synchronously`: pastikan semua akses `context` setelah `await` diproteksi dengan `if (!mounted)` atau `if (!context.mounted)` yang relevan.
   - Perbaiki lint `invalid_use_of_visible_for_testing_member` / `invalid_use_of_protected_member` dengan memastikan manipulasi `state` dilakukan melalui API yang benar milik `StateNotifier`/controller (bukan mengakses protected/terlihat-for-testing).

4. `home_page.dart`, `my_orders_page.dart`, `order_detail_page.dart`, `site_footer.dart`
   - Ganti `withOpacity` deprecated -> `.withValues(alpha: ...)`.
   - Untuk issue `use_build_context_synchronously` pada `home_page.dart` pastikan guard `mounted` dipakai pada `context` yang digunakan.

5. `main.dart`
   - Hapus import yang unused: `features/auth/splash_page.dart`.

6. Jalankan `flutter analyze` lagi sampai jumlah issue berkurang.

## Follow-up steps
- Jalankan:
  - `flutter analyze`
- Pastikan tidak ada error baru dan hanya tersisa issue yang tidak bisa dihilangkan tanpa perubahan besar.

