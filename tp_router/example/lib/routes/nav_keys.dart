import 'package:tp_router/tp_router.dart';

/// Navigator key for the main shell (bottom navigation).
class MainNavKey extends TpNavKey {
  const MainNavKey() : super('main');
}

class MainHomeNavKey extends TpNavKey {
  const MainHomeNavKey() : super('main', branch: 0);
}

class MainSettingNavKey extends TpNavKey {
  const MainSettingNavKey() : super('main', branch: 1);
}

class MainDashBoradNavKey extends TpNavKey {
  const MainDashBoradNavKey() : super('main', branch: 2);
}
