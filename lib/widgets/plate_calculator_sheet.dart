import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PlateCalculatorSheet extends StatefulWidget {
  final double? initialWeight;
  final Function(double)? onApply;

  const PlateCalculatorSheet({
    super.key,
    this.initialWeight,
    this.onApply,
  });

  @override
  State<PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<PlateCalculatorSheet> {
  double _barWeight = 20.0;
  
  // Available plates and their count of pairs (one on each side)
  final Map<double, int> _platesCount = {
    25.0: 0,
    20.0: 0,
    15.0: 0,
    10.0: 0,
    5.0: 0,
    2.5: 0,
    1.25: 0,
  };

  // Plate Colors
  final Map<double, Color> _plateColors = {
    25.0: const Color(0xFFE53935), // Red
    20.0: const Color(0xFF1E88E5), // Blue
    15.0: const Color(0xFFFDD835), // Yellow
    10.0: const Color(0xFF43A047), // Green
    5.0: const Color(0xFFEEEEEE),  // White / Light Gray
    2.5: const Color(0xFF757575),  // Gray
    1.25: const Color(0xFFBDBDBD), // Small Light Gray
  };

  @override
  void initState() {
    super.initState();
    if (widget.initialWeight != null && widget.initialWeight! > 0.0) {
      _calculatePlatesFromWeight(widget.initialWeight!);
    }
  }

  // Calculate plates to match target weight as closely as possible
  void _calculatePlatesFromWeight(double targetWeight) {
    double remaining = targetWeight - _barWeight;
    if (remaining <= 0) return;

    // Reset counts
    _platesCount.updateAll((key, value) => 0);

    // List of plate values sorted descending
    final plateValues = _platesCount.keys.toList()..sort((a, b) => b.compareTo(a));

    for (var plate in plateValues) {
      final double pairWeight = plate * 2;
      if (remaining >= pairWeight) {
        final int pairs = (remaining / pairWeight).floor();
        _platesCount[plate] = pairs;
        remaining -= pairs * pairWeight;
      }
    }
  }

  double get _totalWeight {
    double total = _barWeight;
    _platesCount.forEach((plate, pairs) {
      total += plate * 2 * pairs;
    });
    return total;
  }

  void _addPlate(double plate) {
    setState(() {
      _platesCount[plate] = (_platesCount[plate] ?? 0) + 1;
    });
  }

  void _removePlate(double plate) {
    if ((_platesCount[plate] ?? 0) > 0) {
      setState(() {
        _platesCount[plate] = _platesCount[plate]! - 1;
      });
    }
  }

  void _reset() {
    setState(() {
      _platesCount.updateAll((key, value) => 0);
    });
  }

  @override
  Widget build(BuildContext context) {
    final double total = _totalWeight;

    // Build the list of active plates in order for rendering on the barbell
    final List<double> loadedPlates = [];
    final sortedPlates = _platesCount.keys.toList()..sort((a, b) => b.compareTo(a));
    for (var plate in sortedPlates) {
      final count = _platesCount[plate] ?? 0;
      for (int i = 0; i < count; i++) {
        loadedPlates.add(plate);
      }
    }

    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Barbell Plate Calculator',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimary,
                ),
              ),
              TextButton(
                onPressed: _reset,
                child: const Text('Reset', style: TextStyle(color: AppTheme.error)),
              )
            ],
          ),
          const SizedBox(height: 20),

          // Barbell Visualizer
          Container(
            height: 100,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppTheme.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.border),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Horizontal Steel Bar
                Container(
                  height: 8,
                  width: double.infinity,
                  margin: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: BoxDecoration(
                    color: Colors.grey[400],
                    borderRadius: BorderRadius.circular(4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withAlpha(76),
                        blurRadius: 2,
                        offset: const Offset(0, 1),
                      ),
                    ],
                  ),
                ),
                
                // Barbell Sleeves Collars (Inner Stop)
                Positioned(
                  left: 80,
                  child: Container(
                    height: 24,
                    width: 6,
                    color: Colors.grey[600],
                  ),
                ),
                Positioned(
                  right: 80,
                  child: Container(
                    height: 24,
                    width: 6,
                    color: Colors.grey[600],
                  ),
                ),

                // Left Loaded Plates
                Positioned(
                  right: MediaQuery.of(context).size.width / 2 - 8 + 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: loadedPlates.reversed.map((p) => _buildPlateWidget(p, isLeft: true)).toList(),
                  ),
                ),

                // Center Bar Label
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.background,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    '${_barWeight % 1 == 0 ? _barWeight.toInt() : _barWeight} kg bar',
                    style: const TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                  ),
                ),

                // Right Loaded Plates
                Positioned(
                  left: MediaQuery.of(context).size.width / 2 - 8 + 10,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: loadedPlates.map((p) => _buildPlateWidget(p, isLeft: false)).toList(),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          // Total weight display
          Text(
            '${total % 1 == 0 ? total.toInt() : total} kg',
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: AppTheme.primary,
              letterSpacing: -1.0,
            ),
          ),
          const Text(
            'Total Weight (Bar + Plates)',
            style: TextStyle(fontSize: 11, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          // Barbell Weight Selector
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('Bar Weight: ', style: TextStyle(color: AppTheme.textSecondary, fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(width: 8),
              ...[20.0, 15.0, 10.0].map((w) {
                final isSelected = _barWeight == w;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text('${w % 1 == 0 ? w.toInt() : w} kg'),
                    selected: isSelected,
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surface,
                    checkmarkColor: Colors.black,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    onSelected: (val) {
                      if (val) {
                        setState(() {
                          _barWeight = w;
                        });
                      }
                    },
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 20),

          // Plate buttons grid
          const Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'TAP PLATES TO ADD A PAIR (Left & Right):',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 10, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 95,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: sortedPlates.map((plate) {
                final count = _platesCount[plate] ?? 0;
                final color = _plateColors[plate] ?? Colors.grey;
                final isDarkText = color == const Color(0xFFFDD835) || color == const Color(0xFFEEEEEE); // yellow or white
                
                return Container(
                  width: 70,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      // Plate Button
                      Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: () => _addPlate(plate),
                            child: Container(
                              width: 50,
                              height: 50,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.black.withAlpha(51),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withAlpha(76),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              alignment: Alignment.center,
                              child: Text(
                                '${plate % 1 == 0 ? plate.toInt() : plate}',
                                style: TextStyle(
                                  color: isDarkText ? Colors.black : Colors.white,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ),
                          // Count Badge
                          if (count > 0)
                            Positioned(
                              top: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: AppTheme.secondary,
                                  shape: BoxShape.circle,
                                ),
                                constraints: const BoxConstraints(
                                  minWidth: 18,
                                  minHeight: 18,
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'x$count',
                                  style: const TextStyle(
                                    color: Colors.black,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      // Remove control
                      if (count > 0)
                        InkWell(
                          onTap: () => _removePlate(plate),
                          borderRadius: BorderRadius.circular(4),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(4),
                              border: Border.all(color: AppTheme.border),
                            ),
                            child: const Text(
                              'REMOVE',
                              style: TextStyle(color: AppTheme.error, fontSize: 8, fontWeight: FontWeight.bold),
                            ),
                          ),
                        )
                      else
                        const SizedBox(height: 16),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),

          // Apply/Close buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.surface,
                    foregroundColor: AppTheme.textPrimary,
                    side: const BorderSide(color: AppTheme.border),
                  ),
                  child: const Text('Close'),
                ),
              ),
              if (widget.onApply != null) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      widget.onApply!(total);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primary,
                      foregroundColor: Colors.black,
                    ),
                    child: const Text('Apply Weight'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPlateWidget(double weight, {required bool isLeft}) {
    final color = _plateColors[weight] ?? Colors.grey;
    
    // Height & width based on plate size
    double height = 48;
    double width = 8;
    if (weight == 25.0) {
      height = 54;
      width = 9;
    } else if (weight == 20.0) {
      height = 52;
      width = 9;
    } else if (weight == 15.0) {
      height = 46;
      width = 8;
    } else if (weight == 10.0) {
      height = 40;
      width = 7;
    } else if (weight == 5.0) {
      height = 32;
      width = 6;
    } else if (weight == 2.5) {
      height = 24;
      width = 5;
    } else if (weight == 1.25) {
      height = 18;
      width = 4;
    }

    return Container(
      height: height,
      width: width,
      margin: EdgeInsets.only(
        left: isLeft ? 1 : 0,
        right: isLeft ? 0 : 1,
      ),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(51),
            blurRadius: 1,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
