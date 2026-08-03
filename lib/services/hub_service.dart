/// Compatibility export for older imports.
///
/// The real AppsHub service lives in:
/// lib/features/hub/data/hub_service.dart
///
/// Keep this file so old imports do not accidentally use a duplicate service
/// without the X-APP-TOKEN header.
export '../features/hub/data/hub_service.dart';
