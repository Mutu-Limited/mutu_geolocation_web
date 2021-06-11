import 'package:geocoding/geocoding.dart';

import 'geocoding_config_interface.dart';
import 'geocoding_web.dart';

class GeocodingConfig implements GeocodingConfigInterface {
  @override
  set apiKey(String key) {
    final geocodingWebPlugin = GeocodingPlatform.instance;
    if (geocodingWebPlugin is GeocodingWebPlugin) {
      geocodingWebPlugin.apiKey = key;
    }
  }
}
