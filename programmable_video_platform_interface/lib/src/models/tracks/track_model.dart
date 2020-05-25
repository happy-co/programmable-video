/// Base model that a plugin implementation can use to construct a Track.
///
/// Other track models can extend this model to implement various kinds of Tracks.
class TrackModel {
  final String name;
  final bool enabled;

  const TrackModel({this.name, this.enabled});

  factory TrackModel.fromEventChannelMap(Map<String, dynamic> map) {
    return TrackModel(enabled: map['enabled'], name: map['name']);
  }

  @override
  String toString() {
    return '{ name: $name, enabled: $enabled }';
  }

  /// Create map from properties.
  Map<String, Object> toMap() {
    return <String, Object>{'enable': enabled, 'name': name};
  }
}
