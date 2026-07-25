class FilterOptions {
  final String sortBy;
  final double minPrice;
  final double maxPrice;
  final double minRating;

  FilterOptions({
    required this.sortBy,
    required this.minPrice,
    required this.maxPrice,
    required this.minRating,
  });

  FilterOptions copyWith({
    String? sortBy,
    double? minPrice,
    double? maxPrice,
    double? minRating,
  }) {
    return FilterOptions(
      sortBy: sortBy ?? this.sortBy,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      minRating: minRating ?? this.minRating,
    );
  }
}
