import 'package:arunika_app/data/models/response/app_notification.dart';
import 'package:arunika_app/data/repositories/notification_repository.dart';
import 'package:arunika_app/presentation/screens/notification/notification_bloc.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockNotificationRepository extends Mock
    implements NotificationRepository {}

final _unread = AppNotification(
  id: 'n-1',
  title: 'Selamat!',
  body: 'Lencana diperoleh',
  type: 'badge',
  isRead: false,
  createdAt: DateTime(2026, 4, 1),
);

final _read = AppNotification(
  id: 'n-2',
  title: 'Pembayaran berhasil',
  body: 'Berhasil berlangganan',
  type: 'payment',
  isRead: true,
  createdAt: DateTime(2026, 4, 2),
);

void main() {
  late MockNotificationRepository repo;

  setUp(() {
    repo = MockNotificationRepository();
  });

  group('NotificationBloc', () {
    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationLoaded on LoadNotifications success',
      build: () => NotificationBloc(repository: repo),
      setUp: () {
        when(
          () => repo.getNotifications(),
        ).thenAnswer((_) async => [_unread, _read]);
      },
      act: (bloc) => bloc.add(LoadNotifications()),
      expect: () => [
        NotificationLoading(),
        NotificationLoaded([_unread, _read]),
      ],
    );

    blocTest<NotificationBloc, NotificationState>(
      'emits NotificationError on LoadNotifications failure',
      build: () => NotificationBloc(repository: repo),
      setUp: () {
        when(() => repo.getNotifications()).thenThrow(Exception('error'));
      },
      act: (bloc) => bloc.add(LoadNotifications()),
      expect: () => [NotificationLoading(), isA<NotificationError>()],
    );

    blocTest<NotificationBloc, NotificationState>(
      'updates notification to read on MarkNotificationRead',
      build: () => NotificationBloc(repository: repo),
      setUp: () {
        when(() => repo.markRead(any())).thenAnswer((_) async {});
      },
      seed: () => NotificationLoaded([_unread, _read]),
      act: (bloc) => bloc.add(const MarkNotificationRead('n-1')),
      expect: () => [
        predicate<NotificationState>((s) {
          if (s is! NotificationLoaded) return false;
          final n = s.notifications.firstWhere((n) => n.id == 'n-1');
          return n.isRead == true;
        }),
      ],
    );
  });
}
