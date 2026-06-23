import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../providers/workout_provider.dart';
import '../models/workout_session.dart';
import '../models/exercise_log.dart';
import '../models/workout_set.dart';
import '../theme/app_theme.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout History'),
      ),
      body: Consumer<WorkoutProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator(color: AppTheme.primary));
          }

          final history = provider.history;

          if (history.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, color: AppTheme.textSecondary.withAlpha(100), size: 64),
                  const SizedBox(height: 16),
                  const Text(
                    'No workouts logged yet.',
                    style: TextStyle(color: AppTheme.textSecondary, fontSize: 15),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your completed sessions will show up here.',
                    style: TextStyle(color: AppTheme.textSecondary.withAlpha(150), fontSize: 13),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
            itemCount: history.length,
            itemBuilder: (context, index) {
              final session = history[index];
              return _HistorySessionCard(
                session: session,
                provider: provider,
              );
            },
          );
        },
      ),
    );
  }
}

class _HistorySessionCard extends StatelessWidget {
  final WorkoutSession session;
  final WorkoutProvider provider;

  const _HistorySessionCard({
    required this.session,
    required this.provider,
  });

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('EEEE, MMM dd • h:mm a').format(session.date);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ExpansionTile(
        backgroundColor: Colors.transparent,
        collapsedBackgroundColor: Colors.transparent,
        title: Text(
          dateStr,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: AppTheme.textPrimary,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            '${session.exerciseLogs.length} exercises • ${session.totalCompletedSets} sets',
            style: const TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                const Text(
                  'VOLUME',
                  style: TextStyle(fontSize: 9, color: AppTheme.textSecondary, fontWeight: FontWeight.bold),
                ),
                Text(
                  '${session.totalVolume.toStringAsFixed(0)} kg',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primary,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppTheme.primary, size: 20),
              onPressed: () => _showEditWorkoutBottomSheet(context),
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: AppTheme.error, size: 20),
              onPressed: () => _showDeleteConfirmation(context),
            ),
          ],
        ),
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            alignment: Alignment.topLeft,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 12),
                ...session.exerciseLogs.map((log) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          log.exerciseName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: AppTheme.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        // Horizontal list of sets
                        Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: List.generate(log.sets.length, (setIdx) {
                            final set = log.sets[setIdx];
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: AppTheme.surfaceLight,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppTheme.border),
                              ),
                              child: Text(
                                (set.weightLeft != null && set.weightRight != null)
                                    ? 'Set ${setIdx + 1}: L ${set.weightLeft! % 1 == 0 ? set.weightLeft!.toInt() : set.weightLeft} / R ${set.weightRight! % 1 == 0 ? set.weightRight!.toInt() : set.weightRight} kg x ${set.reps}'
                                    : 'Set ${setIdx + 1}: ${set.weight % 1 == 0 ? set.weight.toInt() : set.weight} kg x ${set.reps}',
                                style: const TextStyle(
                                  fontSize: 10,
                                  color: AppTheme.textPrimary,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: AppTheme.border),
        ),
        title: const Text('Delete Workout?'),
        content: const Text(
          'Are you sure you want to permanently delete this session from your history?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
          ),
          ElevatedButton(
            onPressed: () {
              provider.deleteWorkoutFromHistory(session.id);
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.error, foregroundColor: Colors.white),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showEditWorkoutBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.background,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return _EditWorkoutBottomSheet(
          session: session,
          provider: provider,
        );
      },
    );
  }
}

class _EditWorkoutBottomSheet extends StatefulWidget {
  final WorkoutSession session;
  final WorkoutProvider provider;

  const _EditWorkoutBottomSheet({
    required this.session,
    required this.provider,
  });

  @override
  State<_EditWorkoutBottomSheet> createState() => _EditWorkoutBottomSheetState();
}

class _EditWorkoutBottomSheetState extends State<_EditWorkoutBottomSheet> {
  // Structure: exerciseIndex -> setIndex -> controllerType -> controller
  final Map<int, Map<int, Map<String, TextEditingController>>> _controllers = {};

  @override
  void initState() {
    super.initState();
    for (int i = 0; i < widget.session.exerciseLogs.length; i++) {
      final log = widget.session.exerciseLogs[i];
      _controllers[i] = {};
      for (int j = 0; j < log.sets.length; j++) {
        final set = log.sets[j];
        _controllers[i]![j] = {};
        
        final isUnilateral = set.weightLeft != null && set.weightRight != null;
        if (isUnilateral) {
          _controllers[i]![j]!['weightLeft'] = TextEditingController(
            text: set.weightLeft! % 1 == 0 ? set.weightLeft!.toInt().toString() : set.weightLeft!.toString(),
          );
          _controllers[i]![j]!['weightRight'] = TextEditingController(
            text: set.weightRight! % 1 == 0 ? set.weightRight!.toInt().toString() : set.weightRight!.toString(),
          );
        } else {
          _controllers[i]![j]!['weight'] = TextEditingController(
            text: set.weight % 1 == 0 ? set.weight.toInt().toString() : set.weight.toString(),
          );
        }
        _controllers[i]![j]!['reps'] = TextEditingController(
          text: set.reps.toString(),
        );
      }
    }
  }

  @override
  void dispose() {
    for (var exerciseMap in _controllers.values) {
      for (var setMap in exerciseMap.values) {
        for (var controller in setMap.values) {
          controller.dispose();
        }
      }
    }
    super.dispose();
  }

  void _saveChanges() {
    try {
      final List<ExerciseLog> updatedLogs = [];
      for (int i = 0; i < widget.session.exerciseLogs.length; i++) {
        final log = widget.session.exerciseLogs[i];
        final List<WorkoutSet> updatedSets = [];
        
        for (int j = 0; j < log.sets.length; j++) {
          final set = log.sets[j];
          final isUnilateral = set.weightLeft != null && set.weightRight != null;
          
          double weight = 0.0;
          double? weightLeft;
          double? weightRight;
          
          if (isUnilateral) {
            weightLeft = double.tryParse(_controllers[i]![j]!['weightLeft']!.text) ?? 0.0;
            weightRight = double.tryParse(_controllers[i]![j]!['weightRight']!.text) ?? 0.0;
            weight = weightLeft + weightRight;
          } else {
            weight = double.tryParse(_controllers[i]![j]!['weight']!.text) ?? 0.0;
          }
          
          final reps = int.tryParse(_controllers[i]![j]!['reps']!.text) ?? 0;
          
          updatedSets.add(set.copyWith(
            weight: weight,
            reps: reps,
            weightLeft: weightLeft,
            weightRight: weightRight,
          ));
        }
        
        updatedLogs.add(log.copyWith(sets: updatedSets));
      }
      
      final updatedSession = widget.session.copyWith(exerciseLogs: updatedLogs);
      widget.provider.updateWorkoutInHistory(updatedSession);
      
      Navigator.pop(context);
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Workout history updated successfully!'),
          backgroundColor: AppTheme.primary,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating history: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Edit Workout Session',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppTheme.textSecondary),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.builder(
                itemCount: widget.session.exerciseLogs.length,
                itemBuilder: (context, i) {
                  final log = widget.session.exerciseLogs[i];
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text(
                          log.exerciseName,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primary,
                          ),
                        ),
                      ),
                      ...List.generate(log.sets.length, (j) {
                        final set = log.sets[j];
                        final isUnilateral = set.weightLeft != null && set.weightRight != null;
                        
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Text(
                                'Set ${j + 1}',
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.textSecondary,
                                ),
                              ),
                              const SizedBox(width: 16),
                              if (isUnilateral) ...[
                                Expanded(
                                  child: TextFormField(
                                    controller: _controllers[i]![j]!['weightLeft'],
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Left (kg)',
                                      labelStyle: TextStyle(fontSize: 11),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _controllers[i]![j]!['weightRight'],
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Right (kg)',
                                      labelStyle: TextStyle(fontSize: 11),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ] else ...[
                                Expanded(
                                  child: TextFormField(
                                    controller: _controllers[i]![j]!['weight'],
                                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                    decoration: const InputDecoration(
                                      labelText: 'Weight (kg)',
                                      labelStyle: TextStyle(fontSize: 11),
                                      contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    ),
                                    style: const TextStyle(fontSize: 13),
                                  ),
                                ),
                              ],
                              const SizedBox(width: 12),
                              SizedBox(
                                width: 70,
                                child: TextFormField(
                                  controller: _controllers[i]![j]!['reps'],
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    labelText: 'Reps',
                                    labelStyle: TextStyle(fontSize: 11),
                                    contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  ),
                                  style: const TextStyle(fontSize: 13),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 12),
                      const Divider(),
                    ],
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: _saveChanges,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
