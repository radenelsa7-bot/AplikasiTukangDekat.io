/// Conditional export: uses io implementation on non-web platforms,
/// and stub (web) implementation on web platforms.
library;
export 'download_helper_io.dart' if (dart.library.html) 'download_helper_stub.dart';