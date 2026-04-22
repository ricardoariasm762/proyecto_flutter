import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:ride_match/core/localization/language_controller.dart';
import 'package:ride_match/screens/home/widgets/ride_card.dart';

void main() {
  testWidgets('RideCard shows destination title (not DB name)', (
    WidgetTester tester,
  ) async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    final ride = <String, dynamic>{
      'id': 123,
      'origin_lat': 4.7110,
      'origin_lng': -74.0721,
      'dest_lat': null,
      'dest_lng': null,
      'status': 'waiting',
    };

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => LanguageController()),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: RideCard(
              ride: ride,
              members: 1,
              seatsLeft: 4,
              totalFare: 10000,
              splitFare: 10000,
            ),
          ),
        ),
      ),
    );

    await tester.pump();
    expect(find.textContaining('Ruta #'), findsNothing);
  });
}
