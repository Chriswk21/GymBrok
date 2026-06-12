import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../providers/exercise_provider.dart';
import '../models/exercise.dart';
import '../models/workout_set.dart';
import '../models/exercise_log.dart';
import '../theme/app_theme.dart';
import '../widgets/plate_calculator_sheet.dart';

class ActiveWorkoutScreen extends StatelessWidget {
  const ActiveWorkoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<WorkoutProvider>(
      builder: (context, provider, child) {
        final session = provider.activeSession;
        if (session == null) {
          return const Scaffold(
            body: Center(child: Text('No active workout session.')),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Active Workout'),
            actions: [
              TextButton(
                onPressed: () => _showCancelConfirmation(context, provider),
                child: const Text(
                  'Cancel',
                  style: TextStyle(color: AppTheme.error, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          body: Column(
            children: [
              // Session Stats Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                color: AppTheme.surface,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Total Volume',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${session.totalVolume.toStringAsFixed(0)} kg',
                          style: const TextStyle(
                            color: AppTheme.primary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text(
                          'Exercises Logged',
                          style: TextStyle(color: AppTheme.textSecondary, fontSize: 11, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${session.exerciseLogs.length}',
                          style: const TextStyle(
                            color: AppTheme.textPrimary,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Exercises Log List
              Expanded(
                child: session.exerciseLogs.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fitness_center, color: AppTheme.textSecondary.withAlpha(100), size: 64),
                            const SizedBox(height: 16),
                            const Text(
                              'No exercises added yet.',
                              style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _showAddExerciseSheet(context, provider),
                              child: const Text('Add Exercise'),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: session.exerciseLogs.length,
                        itemBuilder: (context, index) {
                          final log = session.exerciseLogs[index];
                          return _ExerciseLogCard(
                            key: ValueKey(log.exerciseId),
                            log: log,
                            provider: provider,
                          );
                        },
                      ),
              ),
            ],
          ),
          bottomNavigationBar: session.exerciseLogs.isEmpty
              ? null
              : SafeArea(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: const BoxDecoration(
                      color: AppTheme.background,
                      border: Border(top: BorderSide(color: AppTheme.border)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showAddExerciseSheet(context, provider),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.surfaceLight,
                              foregroundColor: AppTheme.textPrimary,
                            ),
                            child: const Text('Add Exercise'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => _showFinishConfirmation(context, provider),
                            child: const Text('Finish Workout'),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        );
      },
    );
  }

  void _showAddExerciseSheet(BuildContext context, WorkoutProvider workoutProvider) {
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
              workoutProvider: workoutProvider,
            );
          },
        );
      },
    );
  }

  void _showCancelConfirmation(BuildContext context, WorkoutProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text('Cancel Workout?'),
        content: const Text(
          'Are you sure you want to discard this workout? All sets and progress logged in this session will be permanently deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Keep Working', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.cancelActiveWorkout();
              Navigator.pop(context); // Pop dialog
              Navigator.pop(context); // Pop active workout screen
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
  }

  void _showFinishConfirmation(BuildContext context, WorkoutProvider provider) {
    final templateNameController = TextEditingController();
    bool saveAsTemplate = false;

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppTheme.surface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(color: AppTheme.border),
              ),
              title: const Text('Finish Workout'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Congratulations on finishing your workout! Ready to log these gains?', style: TextStyle(fontSize: 14)),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Checkbox(
                        value: saveAsTemplate,
                        activeColor: AppTheme.primary,
                        checkColor: Colors.black,
                        onChanged: (val) {
                          setDialogState(() {
                            saveAsTemplate = val ?? false;
                          });
                        },
                      ),
                      const Expanded(
                        child: Text(
                          'Save this routine as a template',
                          style: TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                        ),
                      ),
                    ],
                  ),
                  if (saveAsTemplate) ...[
                    const SizedBox(height: 8),
                    TextField(
                      controller: templateNameController,
                      decoration: const InputDecoration(
                        hintText: 'e.g. Chest Day Routine',
                      ),
                      style: const TextStyle(color: AppTheme.textPrimary),
                      textCapitalization: TextCapitalization.words,
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    final tempName = templateNameController.text.trim();
                    if (saveAsTemplate && tempName.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Please enter a template name.')),
                      );
                      return;
                    }
                    
                    if (saveAsTemplate) {
                      await provider.saveActiveWorkoutAsTemplate(tempName);
                    }
                    await provider.finishActiveWorkout();
                    
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext); // Pop dialog
                    }
                    if (context.mounted) {
                      Navigator.pop(context); // Pop active workout screen
                    }
                  },
                  child: const Text('Finish'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ExerciseLogCard extends StatelessWidget {
  final ExerciseLog log;
  final WorkoutProvider provider;

  const _ExerciseLogCard({
    super.key,
    required this.log,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    // Determine if the exercise requires unilateral L/R inputs
    final exerciseProvider = Provider.of<ExerciseProvider>(context, listen: false);
    final exercise = exerciseProvider.exercises.firstWhere(
      (e) => e.id == log.exerciseId,
      orElse: () => Exercise(id: log.exerciseId, name: log.exerciseName, category: log.category),
    );
    final isUnilateral = exercise.hasUnilateralWeights;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        log.exerciseName,
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimary),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (isUnilateral)
                        const Text(
                          'Unilateral weights (Left / Right separated)',
                          style: TextStyle(fontSize: 10, color: AppTheme.secondary, fontWeight: FontWeight.bold),
                        ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
                  onPressed: () {
                    provider.removeExerciseFromActiveWorkout(log.exerciseId);
                  },
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Table Header
            Row(
              children: [
                const SizedBox(width: 30, child: Text('SET', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold))),
                if (isUnilateral) ...[
                  const Expanded(child: Center(child: Text('L (kg)', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)))),
                  const Expanded(child: Center(child: Text('R (kg)', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)))),
                ] else ...[
                  const Expanded(child: Center(child: Text('WEIGHT (kg)', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)))),
                ],
                const Expanded(child: Center(child: Text('REPS', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)))),
                const SizedBox(width: 48, child: Center(child: Text('DONE', style: TextStyle(fontSize: 10, color: AppTheme.textSecondary, fontWeight: FontWeight.bold)))),
              ],
            ),
            const SizedBox(height: 4),

            // Sets List
            ...List.generate(log.sets.length, (setIndex) {
              final set = log.sets[setIndex];
              return _WorkoutSetRow(
                key: ValueKey('${log.exerciseId}_set_$setIndex'),
                exerciseId: log.exerciseId,
                setIndex: setIndex,
                set: set,
                provider: provider,
                isUnilateral: isUnilateral,
              );
            }),

            const SizedBox(height: 8),
            // Add Set Button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () {
                    provider.addSetToExercise(log.exerciseId);
                  },
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Set', style: TextStyle(fontSize: 12)),
                ),
                if (log.sets.length > 1)
                  TextButton.icon(
                    onPressed: () {
                      provider.removeSetFromExercise(log.exerciseId, log.sets.length - 1);
                    },
                    icon: const Icon(Icons.remove, size: 16, color: AppTheme.error),
                    label: const Text('Remove Set', style: TextStyle(fontSize: 12, color: AppTheme.error)),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _WorkoutSetRow extends StatefulWidget {
  final String exerciseId;
  final int setIndex;
  final WorkoutSet set;
  final WorkoutProvider provider;
  final bool isUnilateral;

  const _WorkoutSetRow({
    super.key,
    required this.exerciseId,
    required this.setIndex,
    required this.set,
    required this.provider,
    required this.isUnilateral,
  });

  @override
  State<_WorkoutSetRow> createState() => _WorkoutSetRowState();
}

class _WorkoutSetRowState extends State<_WorkoutSetRow> {
  // Standard weight controller
  late TextEditingController _weightController;
  
  // Unilateral weight controllers
  late TextEditingController _weightLeftController;
  late TextEditingController _weightRightController;
  
  late TextEditingController _repsController;

  String _formatWeight(double val) {
    if (val == 0.0) return '';
    return val % 1 == 0 ? val.toInt().toString() : val.toString();
  }

  String _formatUnilateralWeight(double? val) {
    if (val == null || val == 0.0) return '';
    return val % 1 == 0 ? val.toInt().toString() : val.toString();
  }

  @override
  void initState() {
    super.initState();
    _weightController = TextEditingController(
      text: _formatWeight(widget.set.weight),
    );
    _weightLeftController = TextEditingController(
      text: _formatUnilateralWeight(widget.set.weightLeft),
    );
    _weightRightController = TextEditingController(
      text: _formatUnilateralWeight(widget.set.weightRight),
    );
    _repsController = TextEditingController(
      text: widget.set.reps == 0 ? '' : widget.set.reps.toString(),
    );
  }

  @override
  void didUpdateWidget(covariant _WorkoutSetRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync values if they changed externally
    if (!widget.isUnilateral) {
      if (widget.set.weight != oldWidget.set.weight && double.tryParse(_weightController.text) != widget.set.weight) {
        _weightController.text = _formatWeight(widget.set.weight);
      }
    } else {
      if (widget.set.weightLeft != oldWidget.set.weightLeft && double.tryParse(_weightLeftController.text) != widget.set.weightLeft) {
        _weightLeftController.text = _formatUnilateralWeight(widget.set.weightLeft);
      }
      if (widget.set.weightRight != oldWidget.set.weightRight && double.tryParse(_weightRightController.text) != widget.set.weightRight) {
        _weightRightController.text = _formatUnilateralWeight(widget.set.weightRight);
      }
    }

    if (widget.set.reps != oldWidget.set.reps && int.tryParse(_repsController.text) != widget.set.reps) {
      _repsController.text = widget.set.reps == 0 ? '' : widget.set.reps.toString();
    }
  }

  @override
  void dispose() {
    _weightController.dispose();
    _weightLeftController.dispose();
    _weightRightController.dispose();
    _repsController.dispose();
    super.dispose();
  }

  void _onFieldsChanged() {
    final int reps = int.tryParse(_repsController.text) ?? 0;
    
    if (widget.isUnilateral) {
      final double left = double.tryParse(_weightLeftController.text) ?? 0.0;
      final double right = double.tryParse(_weightRightController.text) ?? 0.0;
      widget.provider.updateSet(
        widget.exerciseId,
        widget.setIndex,
        reps: reps,
        weightLeft: left,
        weightRight: right,
      );
    } else {
      final double weight = double.tryParse(_weightController.text) ?? 0.0;
      widget.provider.updateSet(
        widget.exerciseId,
        widget.setIndex,
        reps: reps,
        weight: weight,
      );
    }
  }

  void _openPlateCalculator(BuildContext context, {required bool isLeft}) {
    double initialWeight = 0.0;
    if (widget.isUnilateral) {
      if (isLeft) {
        initialWeight = double.tryParse(_weightLeftController.text) ?? 0.0;
      } else {
        initialWeight = double.tryParse(_weightRightController.text) ?? 0.0;
      }
    } else {
      initialWeight = double.tryParse(_weightController.text) ?? 0.0;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return PlateCalculatorSheet(
          initialWeight: initialWeight,
          onApply: (calculatedWeight) {
            setState(() {
              final formattedWeight = calculatedWeight % 1 == 0 
                  ? calculatedWeight.toInt().toString() 
                  : calculatedWeight.toString();
                  
              if (widget.isUnilateral) {
                if (isLeft) {
                  _weightLeftController.text = formattedWeight;
                } else {
                  _weightRightController.text = formattedWeight;
                }
              } else {
                _weightController.text = formattedWeight;
              }
              _onFieldsChanged();
            });
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final fillColour = widget.set.isDone 
        ? AppTheme.primary.withAlpha(20) 
        : Colors.transparent;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
        decoration: BoxDecoration(
          color: fillColour,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            // Set number
            SizedBox(
              width: 30,
              child: Text(
                '${widget.setIndex + 1}',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: widget.set.isDone ? AppTheme.primary : AppTheme.textSecondary,
                ),
              ),
            ),
            
            // Weight inputs (Dual for unilateral, single otherwise)
            if (widget.isUnilateral) ...[
              // Left weight input
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _weightLeftController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(left: 12),
                        filled: true,
                        fillColor: widget.set.isDone ? AppTheme.background : AppTheme.surfaceLight,
                        hintText: 'L',
                        suffixIcon: widget.set.isDone
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.calculate_outlined, size: 14, color: AppTheme.primary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _openPlateCalculator(context, isLeft: true),
                              ),
                      ),
                      onChanged: (value) => _onFieldsChanged(),
                      enabled: !widget.set.isDone,
                    ),
                  ),
                ),
              ),
              // Right weight input
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _weightRightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(left: 12),
                        filled: true,
                        fillColor: widget.set.isDone ? AppTheme.background : AppTheme.surfaceLight,
                        hintText: 'R',
                        suffixIcon: widget.set.isDone
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.calculate_outlined, size: 14, color: AppTheme.primary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _openPlateCalculator(context, isLeft: false),
                              ),
                      ),
                      onChanged: (value) => _onFieldsChanged(),
                      enabled: !widget.set.isDone,
                    ),
                  ),
                ),
              ),
            ] else ...[
              // Standard weight input
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: SizedBox(
                    height: 38,
                    child: TextField(
                      controller: _weightController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.only(left: 12),
                        filled: true,
                        fillColor: widget.set.isDone ? AppTheme.background : AppTheme.surfaceLight,
                        hintText: '0',
                        suffixIcon: widget.set.isDone
                            ? null
                            : IconButton(
                                icon: const Icon(Icons.calculate_outlined, size: 14, color: AppTheme.primary),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _openPlateCalculator(context, isLeft: false),
                              ),
                      ),
                      onChanged: (value) => _onFieldsChanged(),
                      enabled: !widget.set.isDone,
                    ),
                  ),
                ),
              ),
            ],

            // Reps input
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: SizedBox(
                  height: 38,
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 13, color: AppTheme.textPrimary),
                    decoration: InputDecoration(
                      contentPadding: EdgeInsets.zero,
                      filled: true,
                      fillColor: widget.set.isDone ? AppTheme.background : AppTheme.surfaceLight,
                      hintText: '0',
                    ),
                    onChanged: (value) => _onFieldsChanged(),
                    enabled: !widget.set.isDone,
                  ),
                ),
              ),
            ),

            // Done check container
            SizedBox(
              width: 48,
              child: Center(
                child: InkWell(
                  onTap: () {
                    final int reps = int.tryParse(_repsController.text) ?? 0;
                    if (widget.isUnilateral) {
                      final double left = double.tryParse(_weightLeftController.text) ?? 0.0;
                      final double right = double.tryParse(_weightRightController.text) ?? 0.0;
                      widget.provider.updateSet(
                        widget.exerciseId,
                        widget.setIndex,
                        reps: reps,
                        weightLeft: left,
                        weightRight: right,
                        isDone: !widget.set.isDone,
                      );
                    } else {
                      final double weight = double.tryParse(_weightController.text) ?? 0.0;
                      widget.provider.updateSet(
                        widget.exerciseId,
                        widget.setIndex,
                        reps: reps,
                        weight: weight,
                        isDone: !widget.set.isDone,
                      );
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: widget.set.isDone ? AppTheme.primary : Colors.transparent,
                      border: Border.all(
                        color: widget.set.isDone ? AppTheme.primary : AppTheme.textSecondary,
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: widget.set.isDone
                        ? const Icon(Icons.check, color: Colors.black, size: 16)
                        : null,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddExerciseBottomSheet extends StatefulWidget {
  final ScrollController scrollController;
  final WorkoutProvider workoutProvider;

  const _AddExerciseBottomSheet({
    required this.scrollController,
    required this.workoutProvider,
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
                        widget.workoutProvider.addExerciseToActiveWorkout(newExercise);
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
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Add Exercise',
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
          
          // Search input
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

          // Categories filtering
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

          // Exercises List
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
                      final isAdded = widget.workoutProvider.activeSession!.exerciseLogs
                          .any((log) => log.exerciseId == exercise.id);
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
                    widget.workoutProvider.addExerciseToActiveWorkout(ex);
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
