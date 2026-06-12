import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/exercise.dart';
import '../providers/workout_provider.dart';
import '../providers/exercise_provider.dart';
import '../widgets/exercise_chart.dart';
import '../theme/app_theme.dart';

class ExerciseDetailScreen extends StatefulWidget {
  final Exercise exercise;

  const ExerciseDetailScreen({
    super.key,
    required this.exercise,
  });

  @override
  State<ExerciseDetailScreen> createState() => _ExerciseDetailScreenState();
}

class _ExerciseDetailScreenState extends State<ExerciseDetailScreen> {
  bool _showOneRepMax = false;

  @override
  Widget build(BuildContext context) {
    final exerciseProvider = Provider.of<ExerciseProvider>(context);
    final workoutProvider = Provider.of<WorkoutProvider>(context);

    // Get live exercise data (in case it was favorited on this screen)
    final exercise = exerciseProvider.exercises.firstWhere(
      (e) => e.id == widget.exercise.id,
      orElse: () => widget.exercise,
    );

    final history = workoutProvider.getExerciseHistory(exercise.id);

    // Calculate all-time PRs
    double allTimeMaxWeight = 0.0;
    double allTimeBest1RM = 0.0;

    for (var entry in history) {
      final log = entry.value;
      if (log.maxWeight > allTimeMaxWeight) {
        allTimeMaxWeight = log.maxWeight;
      }
      if (log.estimatedOneRepMax > allTimeBest1RM) {
        allTimeBest1RM = log.estimatedOneRepMax;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(exercise.name),
        actions: [
          IconButton(
            icon: Icon(
              exercise.isFavorite ? Icons.star : Icons.star_border,
              color: exercise.isFavorite ? AppTheme.primary : AppTheme.textSecondary,
            ),
            onPressed: () {
              exerciseProvider.toggleFavorite(exercise.id);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Exercise Details & Category badge
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppTheme.border),
                  ),
                  child: Text(
                    exercise.category,
                    style: const TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                if (exercise.isCustom)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withAlpha(30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.secondary.withAlpha(80)),
                    ),
                    child: const Text(
                      'Custom Exercise',
                      style: TextStyle(
                        color: AppTheme.secondary,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 20),

            // Personal Records Panel
            Row(
              children: [
                Expanded(
                  child: _buildPRCard(
                    'Max weight PR',
                    '${allTimeMaxWeight.toStringAsFixed(1)} kg',
                    Icons.emoji_events_outlined,
                    AppTheme.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildPRCard(
                    'Best Est. 1RM',
                    '${allTimeBest1RM.toStringAsFixed(1)} kg',
                    Icons.fitness_center_outlined,
                    AppTheme.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Progression Chart Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Progression Chart',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: -0.5,
                  ),
                ),
                // Toggle switch between Max Weight and 1RM
                Row(
                  children: [
                    Text(
                      _showOneRepMax ? 'Estimated 1RM' : 'Max Weight',
                      style: TextStyle(
                        color: _showOneRepMax ? AppTheme.secondary : AppTheme.primary,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Switch.adaptive(
                      value: _showOneRepMax,
                      activeThumbColor: AppTheme.secondary,
                      activeTrackColor: AppTheme.secondary.withAlpha(100),
                      inactiveThumbColor: AppTheme.primary,
                      inactiveTrackColor: AppTheme.primary.withAlpha(100),
                      onChanged: (val) {
                        setState(() {
                          _showOneRepMax = val;
                        });
                      },
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Performance Chart
            ExerciseChart(
              history: history,
              showOneRepMax: _showOneRepMax,
            ),
            const SizedBox(height: 24),

            // History Section
            const Text(
              'Performance History',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),

            if (history.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 32),
                alignment: Alignment.center,
                child: Text(
                  'No workout history recorded for this exercise.',
                  style: TextStyle(color: AppTheme.textSecondary, fontSize: 14),
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: history.length,
                itemBuilder: (context, index) {
                  // Show in reverse order (newest first)
                  final itemIndex = history.length - 1 - index;
                  final entry = history[itemIndex];
                  final date = entry.key;
                  final log = entry.value;

                  return Container(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: AppTheme.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              DateFormat('EEEE, MMM dd, yyyy').format(date),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimary,
                              ),
                            ),
                            Text(
                              'Volume: ${log.totalVolume.toStringAsFixed(0)} kg',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Divider(),
                        const SizedBox(height: 8),
                        ...List.generate(log.sets.length, (setIdx) {
                          final set = log.sets[setIdx];
                          final est1RM = set.weight * (1 + (set.reps / 30.0));
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Set ${setIdx + 1}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  exercise.hasUnilateralWeights
                                      ? 'L: ${set.weightLeft != null ? (set.weightLeft! % 1 == 0 ? set.weightLeft!.toInt().toString() : set.weightLeft!.toString()) : "0"} / R: ${set.weightRight != null ? (set.weightRight! % 1 == 0 ? set.weightRight!.toInt().toString() : set.weightRight!.toString()) : "0"} kg x ${set.reps} reps'
                                      : '${set.weight % 1 == 0 ? set.weight.toInt().toString() : set.weight.toString()} kg x ${set.reps} reps',
                                  style: const TextStyle(
                                    color: AppTheme.textPrimary,
                                    fontSize: 13,
                                  ),
                                ),
                                Text(
                                  'Est. 1RM: ${est1RM.toStringAsFixed(1)} kg',
                                  style: TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                },
              ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPRCard(String title, String val, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            val,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
