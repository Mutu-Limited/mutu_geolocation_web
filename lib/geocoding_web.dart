import 'dart:async';

import 'package:flutter_web_plugins/flutter_web_plugins.dart';
import 'package:geocoding_platform_interface/geocoding_platform_interface.dart';
import 'package:geocoding_web/geocoding/geocoding_result.dart';

import 'geocoding/geocoding.dart';
import 'geocoding/geocoding_response.dart';
import 'models/lat_lon.dart';

/// The web implementation of [GeocodingPlatform].
///
/// This class implements the `package:geocoding` functionality for the web.
class GeocodingWebPlugin extends GeocodingPlatform {
  String? _apiKey;
  late Geocoding _geocoding;

  /// Registers this class as the default instance of [GeocodingPlatform].
  static void registerWith(Registrar registrar) {
    GeocodingPlatform.instance = GeocodingWebPlugin();
  }

  set apiKey(String key) {
    _apiKey = key;
  }

  @override
  Future<List<Location>> locationFromAddress(
    String address, {
    String? localeIdentifier,
  }) {
    throw UnimplementedError(
        'locationFromAddress() has not been implementated.');
  }

  @override
  Future<List<Placemark>> placemarkFromCoordinates(
    double latitude,
    double longitude, {
    String? localeIdentifier,
  }) async {
    if (_apiKey == null || (_apiKey != null && _apiKey!.isEmpty)) {
      throw Exception(
          "API key is not available. Please use apiKey setting to set API key.");
    }
    _geocoding = Geocoding(_apiKey!);

    final placemarks = <Placemark>[];
    final geocodingResponse =
        await _geocoding.getReverse(LatLon(latitude, longitude));
    if (geocodingResponse != null) {
      _errorChecking(geocodingResponse);
    }
    if (geocodingResponse != null && geocodingResponse.results != null) {
      for (var geoResult in geocodingResponse.results!) {
        final locationName = _findLocationName(geoResult);
        final postalCode = _findPostalcode(geoResult);
        final locality = _findLocality(geoResult);
        final country = _findCountry(geoResult);
        final placemark = Placemark(
            name: locationName,
            postalCode: postalCode,
            locality: locality,
            country: country);
        placemarks.add(placemark);
      }
    }
    return placemarks;
  }

  void _errorChecking(GeocodingResponse response) {
    if (response.status == "OVER_DAILY_LIMIT") {
      throw Exception(
          "Daily limit is crossed for Reverse geocoding or API key is invalid");
    } else if (response.status == "OVER_QUERY_LIMIT") {
      throw Exception("Query limit is crossed for Reverse geocoding");
    } else if (response.status == "REQUEST_DENIED" ||
        response.status == "INVALID_REQUEST") {
      throw Exception("Request denied or Invalid request.");
    } else if (response.status == "UNKNOWN_ERROR") {
      throw Exception("Unknown server error occured. User may try again.");
    }
  }

  String _findLocationName(GeocodingResult geocodingResult) {
    return geocodingResult.formattedAddress ?? "No Name";
  }

  String _findPostalcode(GeocodingResult geocodingResult) {
    return _findProperty(geocodingResult, "postal_code");
  }

  String _findLocality(GeocodingResult geocodingResult) {
    return _findProperty(geocodingResult, "locality");
  }

  String _findCountry(GeocodingResult geocodingResult) {
    return _findProperty(geocodingResult, "country");
  }

  String _findProperty(GeocodingResult geocodingResult, String propName) {
    String propValue = "";
    if (geocodingResult.addressComponents != null) {
      for (var addressComp in geocodingResult.addressComponents!) {
        final foundedPropValue = addressComp.types
            ?.firstWhere((element) => element == propName, orElse: () => "");
        if (foundedPropValue != null && foundedPropValue.length > 0) {
          propValue = addressComp.longName ?? "";
          break;
        }
      }
    }
    return propValue;
  }
}
