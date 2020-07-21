/// Base model that a plugin implementation can use to construct a Track.
///
/// Other track models can extend this model to implement various kinds of Tracks.
abstract class TrackModel {
  final String name;
  final bool enabled;

  const TrackModel({
    this.name,
    this.enabled,
  });

  @override
  String toString() {
    return '{ name: $name, enabled: $enabled }';
  }

  /// Create map from properties.
  Map<String, Object> toMap() {
    return <String, Object>{'enable': enabled, 'name': name};
  }
}
