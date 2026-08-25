/// Pagination metadata shared across paginated endpoints. Defined here so any
/// repository can return it without duplicating the parser.
class PaginationMeta {
  final int currentPage;
  final int lastPage;
  final int perPage;
  final int total;
  final int? from;
  final int? to;
  const PaginationMeta({
    required this.currentPage,
    required this.lastPage,
    required this.perPage,
    required this.total,
    this.from,
    this.to,
  });

  bool get hasNext => currentPage < lastPage;

  factory PaginationMeta.fromResponse(Map<String, dynamic>? meta) {
    if (meta == null) {
      return const PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: 0,
        total: 0,
      );
    }
    return PaginationMeta(
      currentPage: (meta['current_page'] as num?)?.toInt() ?? 1,
      lastPage: (meta['last_page'] as num?)?.toInt() ?? 1,
      perPage: (meta['per_page'] as num?)?.toInt() ?? 15,
      total: (meta['total'] as num?)?.toInt() ?? 0,
      from: (meta['from'] as num?)?.toInt(),
      to: (meta['to'] as num?)?.toInt(),
    );
  }

  factory PaginationMeta.fromInnerData(Map<String, dynamic>? data) {
    // Used when the controller wraps the array under `data.data` and meta
    // sits next to it (Laravel paginator style).
    if (data == null) {
      return const PaginationMeta(
        currentPage: 1,
        lastPage: 1,
        perPage: 0,
        total: 0,
      );
    }
    final inner = data['data'];
    if (inner is List) {
      // nothing — array already extracted
    }
    return PaginationMeta.fromResponse(
      data['meta'] is Map
          ? Map<String, dynamic>.from(data['meta'] as Map)
          : null,
    );
  }
}
