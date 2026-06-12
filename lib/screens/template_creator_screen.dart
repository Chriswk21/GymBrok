import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise.dart';
import '../theme/app_theme.dart';

class TemplateCreatorScreen extends StatefulWidget {
  const TemplateCreatorScreen({super.key});

  @override
  State<TemplateCreatorScreen> createState() => _TemplateCreatorScreenState();
}

class _TemplateCreatorScreenState extends State<TemplateCreatorScreen> {
  final TextEditingController _nameController = TextEditingController();
  final List<Exercise> _selectedExercises = [];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addExercise(Exercise exercise) {
    if (_selectedExercises.any((e) => e.id == exercise.id)) return;
    setState(() {
      _selectedExercises.add(exercise);
    });
  }

  void _removeExercise(int index) {
    setState(() {
      _selectedExercises.removeAt(index);
    });
  }

  void _saveTemplate(WorkoutProvider provider) async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a template name.')),
      );
      return;
    }
    if (_selectedExercises.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one exercise.')),
      );
      return;
    }

    await provider.createTemplate(name, _selectedExercises);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Template "$name" saved!')),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Template'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: AppTheme.primary),
            onPressed: () => _saveTemplate(workoutProvider),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Template Name',
              style: TextStyle(color: AppTheme.textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                hintText: 'e.g. Chest & Triceps Day',
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Exercises',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                TextButton.icon(
                  onPressed: () => _showAddExerciseSheet(context),
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Exercise'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: _selectedExercises.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.format_list_bulleted, color: AppTheme.textSecondary.withAlpha(100), size: 48),
                          const SizedBox(height: 12),
                          const Text(
                            'No exercises added to this template yet.',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                          ),
                        ],
                      ),
                    )
                  : ReorderableListView.builder(
                      itemCount: _selectedExercises.length,
                      onReorder: (oldIndex, newIndex) {
                        setState(() {
                          if (newIndex > oldIndex) {
                            newIndex -= 1;
                          }
                          final item = _selectedExercises.removeAt(oldIndex);
                          _selectedExercises.insert(newIndex, item);
                        });
                      },
                      itemBuilder: (context, index) {
                        final exercise = _selectedExercises[index];
                        return Card(
                          key: ValueKey(exercise.id),
                          margin: const EdgeInsets.symmetric(vertical: 4),
                          child: ListTile(
                            leading: ReorderableDragStartListener(
                              index: index,
                              child: const Icon(Icons.drag_handle, color: AppTheme.textSecondary),
                            ),
                            title: Text(exercise.name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                            subtitle: Text(exercise.category, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                            trailing: IconButton(
                              icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                              onPressed: () => _removeExercise(index),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddExerciseSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.75,
          maxChildSize: 0.95,
          minChildSize: 0.5,
          expand: false,
          builder: (context, scrollController) {
            return _AddExerciseBottomSheet(
              scrollController: scrollController,
              onExerciseSelected: (exercise) {
                _addExercise(exercise);
              },
              selectedExerciseIds: _selectedExercises.map((e) => e.id).toList(),
            );
          },
        );
      },
    );
  }
}

class _AddExerciseBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final Function(Exercise) onExerciseSelected;
  final List<String> selectedExerciseIds;

  const _AddExerciseBottomSheet({
    required this.scrollController,
    required this.onExerciseSelected,
    required this.selectedExerciseIds,
  });

  @override
  State<_AddExerciseBottomSheet> createState() => _AddExerciseBottomSheetState();
}

class _AddExerciseBottomSheetState extends State<_AddExerciseBottomSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _searchQuery = '';
  final List<Exercise> _tempSelectedExercises = [];

  final List<String> _categories = [
    'All',
    'Chest',
    'Back',
    'Legs',
    'Shoulders',
    'Bicep',
    'Tricep',
    'Core',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _showAddCustomExerciseDialog(BuildContext context, ExerciseProvider exerciseProvider) {
    final nameController = TextEditingController();
    String selectedCat = _selectedCategory == 'All' ? 'Chest' : _selectedCategory;
    bool hasUnilateral = false;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Text(
                'Add Custom Exercise',
                style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Exercise Name',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      hintText: 'e.g. Incline Cable Press',
                    ),
                    style: const TextStyle(color: AppTheme.textPrimary),
                    textCapitalization: TextCapitalization.words,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Muscle Category',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.background,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedCat,
                        dropdownColor: AppTheme.surface,
                        isExpanded: true,
                        iconEnabledColor: AppTheme.primary,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        items: _categories
                            .where((c) => c != 'All')
                            .map((cat) => DropdownMenuItem(
                                  value: cat,
                                  child: Text(cat),
                                ))
                            .toList(),
                        onChanged: (val) {
                          if (val != null) {
                            setDialogState(() {
                              selectedCat = val;
                            });
                          }
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Track Left/Right Weights',
                            style: TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 2),
                          Text(
                            'For dumbbells, single arms/legs',
                            style: TextStyle(color: AppTheme.textSecondary, fontSize: 10),
                          ),
                        ],
                      ),
                      Switch(
                        value: hasUnilateral,
                        activeThumbColor: AppTheme.primary,
                        onChanged: (val) {
                          setDialogState(() {
                            hasUnilateral = val;
                          });
                        },
                      ),
                    ],
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final navigator = Navigator.of(context);
                    final name = nameController.text;
                    if (name.trim().isNotEmpty) {
                      final newExercise = await exerciseProvider.addCustomExercise(
                        name,
                        selectedCat,
                        hasUnilateralWeights: hasUnilateral,
                      );
                      if (newExercise != null) {
                        widget.onExerciseSelected(newExercise);
                      }
                      navigator.pop(); // Close dialog
                      navigator.pop(); // Close bottom sheet
                    }
                  },
                  child: const Text('Add'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);
    final filteredExercises = exerciseProvider.searchExercises(
      _searchQuery,
      category: _selectedCategory,
    );

    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.border,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Select Exercises',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                ),
                IconButton(
                  icon: const Icon(Icons.add, color: AppTheme.primary),
                  tooltip: 'Create Custom Exercise',
                  onPressed: () => _showAddCustomExerciseDialog(context, exerciseProvider),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: TextField(
              controller: _searchController,
              onChanged: (val) {
                setState(() {
                  _searchQuery = val;
                });
              },
              decoration: const InputDecoration(
                hintText: 'Search exercises...',
                prefixIcon: Icon(Icons.search, color: AppTheme.textSecondary),
                contentPadding: EdgeInsets.symmetric(vertical: 10),
              ),
              style: const TextStyle(color: AppTheme.textPrimary),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: FilterChip(
                    selected: isSelected,
                    label: Text(cat, style: const TextStyle(fontSize: 12)),
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : AppTheme.textPrimary,
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                    ),
                    selectedColor: AppTheme.primary,
                    backgroundColor: AppTheme.surface,
                    checkmarkColor: Colors.black,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppTheme.primary : AppTheme.border,
                      ),
                    ),
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    },
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: filteredExercises.isEmpty
                ? const Center(
                    child: Text('No exercises found', style: TextStyle(color: AppTheme.textSecondary)),
                  )
                : ListView.builder(
                    controller: widget.scrollController,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    itemCount: filteredExercises.length,
                    itemBuilder: (context, index) {
                      final exercise = filteredExercises[index];
                      final isAdded = widget.selectedExerciseIds.contains(exercise.id);
                      final isTempSelected = _tempSelectedExercises.any((e) => e.id == exercise.id);

                      return ListTile(
                        title: Text(exercise.name, style: const TextStyle(fontSize: 14)),
                        subtitle: Text(exercise.category, style: const TextStyle(fontSize: 11, color: AppTheme.textSecondary)),
                        trailing: isAdded
                            ? const Icon(Icons.check_circle, color: AppTheme.primary)
                            : Icon(
                                isTempSelected ? Icons.check_box : Icons.check_box_outline_blank,
                                color: isTempSelected ? AppTheme.primary : AppTheme.textSecondary,
                              ),
                        onTap: isAdded
                            ? null
                            : () {
                                setState(() {
                                  if (isTempSelected) {
                                    _tempSelectedExercises.removeWhere((e) => e.id == exercise.id);
                                  } else {
                                    _tempSelectedExercises.add(exercise);
                                  }
                                });
                              },
                      );
                    },
                  ),
          ),
          if (_tempSelectedExercises.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: ElevatedButton(
                onPressed: () {
                  for (var ex in _tempSelectedExercises) {
                    widget.onExerciseSelected(ex);
                  }
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Add ${_tempSelectedExercises.length} Exercises',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
