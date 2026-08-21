class Snapshot<T> {
  const Snapshot({required this.value, required this.isStale, this.fetchedAt});

  const Snapshot.fresh(this.value, {this.fetchedAt}) : isStale = false;

  const Snapshot.cached(this.value, {this.fetchedAt}) : isStale = true;

  final T value;
  final bool isStale;
  final DateTime? fetchedAt;
}
