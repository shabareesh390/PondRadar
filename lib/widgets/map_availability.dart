// Conditional export to detect Google Maps availability on web vs native.
export 'map_availability_stub.dart'
    if (dart.library.js_interop) 'map_availability_web.dart';
