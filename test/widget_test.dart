import 'package:flutter_test/flutter_test.dart';
import 'package:iloilo_planner/main.dart';
import 'package:iloilo_planner/splash_screen.dart';

void main() {
  testWidgets('app launches to the IloiloPlanner splash screen', (
    tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.bySemanticsLabel('Loading IloiloPlanner'), findsOneWidget);
  });
}
