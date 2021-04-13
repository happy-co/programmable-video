@JS()
library map;

import 'package:js/js.dart';

@JS()
class Map<K, V> {
  /// Returns an [Iterator] of all the key value pairs in the [Map]
  ///
  /// The [Iterator] returns the key value pairs as a [List<dynamic>].
  /// The [List] always contains two elements. The first is the key and the second is the value.
  @JS('prototype.entries')
  external Iterator<List<dynamic>> entries();

  @JS('prototype.keys')
  external Iterator<K> keys();

  @JS('prototype.values')
  external Iterator<V> values();

  external factory Map();
}

@JS()
class Iterator<T> {
  external IteratorValue<T> next();

  external factory Iterator();
}

@JS()
class IteratorValue<T> {
  external T get value;
  external bool get done;

  external factory IteratorValue();
}

List<T> iteratorToList<T, V>(
  Iterator<V> iterator,
  T Function(V value) mapper,
) {
  final list = <T>[];
  var result = iterator.next();
  while (!result.done) {
    list.add(
      mapper(result.value),
    );

    result = iterator.next();
  }
  return list;
}
