@JS()
library js_map;

import 'package:js/js.dart';

@JS('Map')
class JSMap<K, V> {
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

  external int get size;

  external factory JSMap();
}

extension Interop<K, V> on JSMap<K, V> {
  Map<K, V> toDartMap() {
    final returnMap = <K, V>{};

    final jsKeys = keys();
    final jsValues = values();

    var nextKey = jsKeys.next();
    var nextValue = jsValues.next();

    while (!nextKey.done) {
      returnMap[nextKey.value] = nextValue.value;
      nextKey = jsKeys.next();
      nextValue = jsValues.next();
    }

    return returnMap;
  }
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

void iteratorForEach<V>(
  Iterator<V> iterator,
  bool Function(V value) mapper,
) {
  var result = iterator.next();
  while (!result.done) {
    final earlyBreak = mapper(result.value);
    if (earlyBreak) break;
    result = iterator.next();
  }
}
