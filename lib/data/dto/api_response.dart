class ApiResponse<T> {
  const ApiResponse({required this.data, this.meta = const {}});

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Object? data) parse,
  ) {
    return ApiResponse(
      data: parse(json['data']),
      meta: (json['meta'] as Map?)?.cast<String, dynamic>() ?? const {},
    );
  }

  final T data;
  final Map<String, dynamic> meta;

  DateTime? get serverTime =>
      DateTime.tryParse(meta['server_time'] as String? ?? '');
}

List<T> parseList<T>(Object? data, T Function(Map<String, dynamic>) fromJson) {
  if (data is! List) return const [];
  return data
      .whereType<Map>()
      .map((item) => fromJson(item.cast<String, dynamic>()))
      .toList(growable: false);
}
