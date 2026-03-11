import 'package:flutter_test/flutter_test.dart';
import 'package:panthers_crossfit_club/main.dart';
import 'package:panthers_crossfit_club/data/repositories/member_repository.dart';

void main() {
  testWidgets('Login screen smoke test', (WidgetTester tester) async {
    final memberRepository = MemberRepository();
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(PanthersApp(memberRepository: memberRepository));

    // Verify that our login screen is shown.
    expect(find.text('PANTHERS CLUB'), findsOneWidget);
    expect(find.text('Connexion Athlète'), findsOneWidget);
  });
}
