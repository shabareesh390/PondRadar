import 'dart:js_interop';

@JS('isGoogleMapsLoaded')
external bool? _isGoogleMapsLoaded();

/// Checks window.isGoogleMapsLoaded set in web/index.html after Maps JS loads.
bool isGoogleMapsAvailable() {
  try {
    return _isGoogleMapsLoaded() ?? false;
  } catch (_) {
    return false;
  }
}
