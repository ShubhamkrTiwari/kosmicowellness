import 'package:flutter/material.dart';
import '../models/filter_options.dart';

class FilterBottomSheet extends StatefulWidget {
  final FilterOptions initialOptions;

  const FilterBottomSheet({super.key, required this.initialOptions});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late String _tempSortBy;
  late double _tempMinPrice;
  late double _tempMaxPrice;
  late double _tempMinRating;

  final List<String> _sortOptions = [
    'Popularity',
    'Price: Low to High',
    'Price: High to Low',
    'Newest'
  ];

  @override
  void initState() {
    super.initState();
    _tempSortBy = widget.initialOptions.sortBy;
    _tempMinPrice = widget.initialOptions.minPrice;
    _tempMaxPrice = widget.initialOptions.maxPrice;
    _tempMinRating = widget.initialOptions.minRating;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filter & Sort',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempSortBy = 'Popularity';
                    _tempMinPrice = 0.0;
                    _tempMaxPrice = 5000.0;
                    _tempMinRating = 0.0;
                  });
                  debugPrint('DEBUG: Filter Reset to defaults');
                },
                style: TextButton.styleFrom(foregroundColor: Colors.red),
                child: const Text('Reset All'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Sort By
          const Text('Sort By', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: _sortOptions.map((option) {
              final isSelected = _tempSortBy == option;
              return ChoiceChip(
                label: Text(option),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) setState(() => _tempSortBy = option);
                },
                selectedColor: colorScheme.primary,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : colorScheme.onSurface,
                  fontSize: 12,
                ),
              );
            }).toList(),
          ),
          
          const SizedBox(height: 24),
          
          // Price Range
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Price Range', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                '₹${_tempMinPrice.round()} - ₹${_tempMaxPrice.round()}',
                style: TextStyle(color: colorScheme.primary, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          RangeSlider(
            values: RangeValues(_tempMinPrice, _tempMaxPrice),
            min: 0,
            max: 5000,
            divisions: 50,
            activeColor: colorScheme.primary,
            inactiveColor: colorScheme.primary.withValues(alpha: 0.1),
            onChanged: (values) {
              setState(() {
                _tempMinPrice = values.start;
                _tempMaxPrice = values.end;
              });
            },
          ),
          
          const SizedBox(height: 24),
          
          // Rating
          const Text('Minimum Rating', style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: List.generate(5, (index) {
                final ratingValue = index.toDouble();
                final isSelected = _tempMinRating == ratingValue;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: InkWell(
                    onTap: () => setState(() => _tempMinRating = ratingValue),
                    borderRadius: BorderRadius.circular(10),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: isSelected ? colorScheme.primary : colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isSelected ? colorScheme.primary : colorScheme.primary.withValues(alpha: 0.1),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '${index.toInt()}+',
                            style: TextStyle(
                              color: isSelected ? Colors.white : colorScheme.onSurface,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                          const SizedBox(width: 2),
                          Icon(
                            Icons.star,
                            size: 12,
                            color: isSelected ? Colors.white : Colors.amber,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(
                  context,
                  FilterOptions(
                    sortBy: _tempSortBy,
                    minPrice: _tempMinPrice,
                    maxPrice: _tempMaxPrice,
                    minRating: _tempMinRating,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Text('Apply Filters', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
