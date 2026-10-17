import 'dart:js_interop';

@JS('isGoogleMapsLoaded')
external bool? _isGoogleMapsLoaded();

bool isGoogleMapsAvailable() {
  try {
    return _isGoogleMapsLoaded() ?? false;
  } catch (_) {
    return false;
  }
}
