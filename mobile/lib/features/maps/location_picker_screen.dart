export 'osm_location_picker_screen.dart';

// Backward compatibility: nama kelas lama masih diharapkan ada.
// Di `osm_location_picker_screen.dart` kita memiliki `OsmLocationPickerScreen`
// dan `LocationResult`.
import 'osm_location_picker_screen.dart';

class LocationPickerScreen extends OsmLocationPickerScreen {
  const LocationPickerScreen({
    super.key,
    super.initialLat,
    super.initialLng,
    super.initialAddress,
  });
}





