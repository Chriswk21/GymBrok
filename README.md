# GymBrok - Offline Gym Tracker

GymBrok is a modern, offline-first gym tracking application built using Flutter. It features a premium dark theme with vibrant neon green accents. All workout data is persisted locally using Hive.

## Key Features

- **Exercise Library**: Seeded with 60+ common exercises. Customize or star favorites.
- **Unilateral Tracking**: Optional split columns for Left & Right side weight tracking.
- **Workout Templates**: Create templates or save active sessions to repeat routines easily.
- **Multi-Select Exercises**: Add multiple exercises to templates or active sessions at once.
- **Calorie Tracker**: Log daily calories and set progression targets on the dashboard.
- **Body Weight Tracker**: Track body weight log entries over time.
- **JSON Backup/Restore**: Export your entire app state to JSON or import it to restore your data.
- **Barbell Plate Calculator**: Automatically calculate plate configurations for any target weight.

## How to Run

1. **Prerequisites**: Ensure you have [Flutter SDK](https://docs.flutter.dev/get-started/install) installed on your machine.
2. **Clone & Setup**:
   ```bash
   git clone https://github.com/Chriswk21/GymBrok.git
   cd GymBrok
   flutter pub get
   ```
3. **Run the App**:
   ```bash
   flutter run
   ```
4. **Run Tests**:
   ```bash
   flutter test
   ```

## Release APK

The compiled release APK is located at:
- **Path**: `build/app/outputs/flutter-apk/app-release.apk`
