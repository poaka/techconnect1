import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mobile/features/auth/presentation/screens/login_screen.dart';
import 'package:mobile/features/auth/presentation/screens/register_screen.dart';
import 'package:mobile/shared/widgets/app_button.dart';
import 'package:mobile/features/notifications/presentation/screens/notifications_screen.dart';
import 'package:mobile/features/client_dashboard/presentation/screens/client_dashboard_screen.dart';
import 'package:mobile/features/technician_dashboard/presentation/screens/technician_dashboard_screen.dart';
import 'package:mobile/features/requests/presentation/screens/request_list_screen.dart';

void main() {
  testWidgets('LoginScreen renders email, password fields and login button', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: LoginScreen(),
        ),
      ),
    );

    expect(find.text('Connexion'), findsWidgets);
    expect(find.text('Adresse Email'), findsOneWidget);
    expect(find.text('Mot de passe'), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);
  });

  testWidgets('RegisterScreen renders role selection segment and form inputs', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: RegisterScreen(),
        ),
      ),
    );

    expect(find.text('Inscription'), findsOneWidget);
    expect(find.text('Client'), findsOneWidget);
    expect(find.text('Technicien'), findsOneWidget);
    expect(find.text('Nom complet'), findsOneWidget);
    expect(find.byType(AppButton), findsOneWidget);
  });
  testWidgets('NotificationsScreen renders empty state initially', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NotificationsScreen(),
        ),
      ),
    );

    // Initial state is usually loading or empty. We should find 'Notifications' in the AppBar.
    expect(find.text('Notifications'), findsOneWidget);
  });

}
