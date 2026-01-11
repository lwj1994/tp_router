import 'package:teleport_router/teleport_router.dart';

/// Navigator key for the main shell (bottom navigation).
class MainNavKey extends TeleportNavKey {
  const MainNavKey() : super('main');
}

class MainHomeNavKey extends TeleportNavKey {
  const MainHomeNavKey() : super('main', branch: 0);
}

class MainSettingNavKey extends TeleportNavKey {
  const MainSettingNavKey() : super('main', branch: 1);
}

class MainDashBoradNavKey extends TeleportNavKey {
  const MainDashBoradNavKey() : super('main', branch: 2);
}
