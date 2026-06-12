import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:gymbrok/widgets/plate_calculator_sheet.dart';

void main() {
  Widget buildTestableWidget(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: child,
      ),
    );
  }

  Finder findTotalWeightText(String text) {
    return find.byWidgetPredicate((widget) =>
        widget is Text &&
        widget.data == text &&
        widget.style?.fontSize == 36);
  }

  testWidgets('PlateCalculatorSheet default layout and interaction', (WidgetTester tester) async {
    // Build PlateCalculatorSheet with initial weight of 20.0 (only the bar)
    await tester.pumpWidget(buildTestableWidget(const PlateCalculatorSheet()));

    // Verify it displays the title
    expect(find.text('Barbell Plate Calculator'), findsOneWidget);

    // Verify default total weight is 20 kg
    expect(findTotalWeightText('20 kg'), findsOneWidget);

    // Find the 25 kg plate button by searching for the text "25"
    // ChoiceChips or plate buttons might have other values. Let's find the circle plate button.
    // The plate button is a Text widget inside a GestureDetector/Container, with size 14 style.
    final plate25Button = find.byWidgetPredicate((widget) =>
        widget is Text &&
        widget.data == '25' &&
        widget.style?.fontSize == 14);
    expect(plate25Button, findsOneWidget);

    // Tap 25 kg plate button to add a pair
    await tester.tap(plate25Button);
    await tester.pump();

    // The new weight should be 20 (bar) + 50 (two 25kg plates) = 70 kg
    expect(findTotalWeightText('70 kg'), findsOneWidget);

    // Tap 10 kg plate button to add a pair
    final plate10Button = find.byWidgetPredicate((widget) =>
        widget is Text &&
        widget.data == '10' &&
        widget.style?.fontSize == 14);
    expect(plate10Button, findsOneWidget);
    await tester.tap(plate10Button);
    await tester.pump();

    // The new weight should be 70 + 20 = 90 kg
    expect(findTotalWeightText('90 kg'), findsOneWidget);

    // Find and tap the "Reset" button
    final resetButton = find.text('Reset');
    expect(resetButton, findsOneWidget);
    await tester.tap(resetButton);
    await tester.pump();

    // Weight should go back to 20 kg
    expect(findTotalWeightText('20 kg'), findsOneWidget);
  });

  testWidgets('PlateCalculatorSheet auto-calculation from initial weight', (WidgetTester tester) async {
    // Initial weight of 85 kg (20 kg bar + 65 kg plates: 25*2 + 5*2 + 2.5*2)
    await tester.pumpWidget(buildTestableWidget(const PlateCalculatorSheet(
      initialWeight: 85.0,
    )));

    // Verify it calculates 85 kg
    expect(findTotalWeightText('85 kg'), findsOneWidget);

    // Verify that the count of 25kg plates displays "x1"
    expect(find.text('x1'), findsWidgets);
  });

  testWidgets('PlateCalculatorSheet bar weight switching', (WidgetTester tester) async {
    await tester.pumpWidget(buildTestableWidget(const PlateCalculatorSheet()));

    // Default 20 kg bar
    expect(findTotalWeightText('20 kg'), findsOneWidget);

    // Switch bar weight to 15 kg
    // Find the ChoiceChip text "15 kg"
    final bar15Chip = find.byWidgetPredicate((widget) =>
        widget is Text &&
        widget.data == '15 kg');
    expect(bar15Chip, findsOneWidget);
    await tester.tap(bar15Chip);
    await tester.pump();

    // New weight should be 15 kg
    expect(findTotalWeightText('15 kg'), findsOneWidget);
  });
}
