# TpRouter

| Package | Version |
|---------|---------|
| [tp_router](https://pub.dev/packages/tp_router) | [![pub package](https://img.shields.io/pub/v/tp_router.svg)](https://pub.dev/packages/tp_router) |
| [tp_router_annotation](https://pub.dev/packages/tp_router_annotation) | [![pub package](https://img.shields.io/pub/v/tp_router_annotation.svg)](https://pub.dev/packages/tp_router_annotation) |
| [tp_router_generator](https://pub.dev/packages/tp_router_generator) | [![pub package](https://img.shields.io/pub/v/tp_router_generator.svg)](https://pub.dev/packages/tp_router_generator) |

**Flutter 的极简、类型安全、注解驱动路由库。**

TpRouter 让你告别手动维护路由表。通过简单的 `NavKey` 关联机制，它可以自动生成包含复杂嵌套结构的完整路由树。

## ✨ 核心特性

*   **🗝️ NavKey 驱动关联**: 告别嵌套地狱。只需告诉路由 "我的父级是 `MainNavKey`"，它们就会自动关联，生成正确的嵌套结构。
*   **📐 类型安全导航**: 使用 `UserRoute(id: 1).tp()` 代替容易出错的字符串 `context.go('/user/1')`。
*   **🐚 声明式 Shell**: 纯注解定义 App 布局（如底部导航栏、抽屉）。
*   **🧩 智能代码生成**: 自动处理参数传递、返回值等待、深度链接等繁琐逻辑。

---

## 🛠️ 安装

在 `pubspec.yaml` 中添加：

```yaml
dependencies:
  tp_router: ^0.1.0
  tp_router_annotation: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
  tp_router_generator: ^0.1.0
```

运行生成器：
```bash
dart run build_runner build
```

---

## 🚀 快速开始

### 1. 定义 NavKeys
**NavKeys 是 TpRouter 的核心。** 它们是导航器的唯一标识，也是父子路由之间的桥梁。

创建文件 `lib/routes/nav_keys.dart`:

```dart
import 'package:tp_router/tp_router.dart';

// 主 Shell 的 Key (例如底部导航栏)
class MainNavKey extends TpNavKey {
  const MainNavKey() : super('main');
}

// 分支 Key (如果你使用 IndexedStack 做多 Tab 切换，推荐定义)
class HomeNavKey extends TpNavKey {
  const HomeNavKey() : super('main', branch: 0);
}

class SettingsNavKey extends TpNavKey {
  const SettingsNavKey() : super('main', branch: 1);
}
```

### 2. 定义布局 (Shells)
使用 `@TpShellRoute` 标记你的容器 Widget（例如带 `BottomNavigationBar` 的页面）。
**将其绑定到一个 Key** (`MainNavKey`)。

```dart
@TpShellRoute(
  navigatorKey: MainNavKey, // <--- 绑定 Key
  isIndexedStack: true,     // 启用有状态的嵌套导航 (每个 Tab 保持状态)
  branchKeys: [HomeNavKey, SettingsNavKey], // <--- 定义分支 Key 顺序
)
class MainShellPage extends StatelessWidget {
  final TpStatefulNavigationShell navigationShell;
  const MainShellPage({required this.navigationShell, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        // 使用 .tp(index) 切换分支
        onTap: (index) => navigationShell.tp(index),
        items: [/* ... */],
      ),
    );
  }
}
```

### 3. 定义路由并关联父级
只需给页面添加注解。
*   **要嵌套页面？** 将 `parentNavigatorKey` 设置为 Shell 的 Key。
*   **普通页面？** 省略 Key 即可。

```dart
// 标准路由
@TpRoute(path: '/login')
class LoginPage extends StatelessWidget { ... }

// 嵌套路由 (MainShellPage 的子路由)
@TpRoute(
  path: '/home',
  isInitial: true,
  parentNavigatorKey: HomeNavKey, // <--- 自动关联到 MainShell 的第 0 个分支！
)
class HomePage extends StatelessWidget { ... }

// 另一个嵌套路由
@TpRoute(
  path: '/settings',
  parentNavigatorKey: SettingsNavKey, // <--- 关联到 MainShell 的第 1 个分支
)
class SettingsPage extends StatelessWidget { ... }
```

### 4. 初始化
将生成的 `tpRoutes` 传给 `TpRouter`。

```dart
void main() {
  final router = TpRouter(
    routes: tpRoutes, // build_runner 生成的
  );

  runApp(MaterialApp.router(
    routerConfig: router.routerConfig,
  ));
}
```

---

## 🧭 导航

### 类型安全导航
生成器会为每个注解的 Widget 生成对应的 `Route` 类。

```dart
// 打开页面
UserRoute(id: 123).tp();

// 等待返回值
final result = await SelectProfileRoute().tp<String>();

// 替换当前路由
LoginRoute().tp(replacement: true);
```



## ⚙️ 进阶功能

### 路由守卫与重定向 (Guards)
需要保护页面？使用 `redirect`。

```dart
class AuthGuard extends TpRedirect<ProtectedRoute> {
  @override
  FutureOr<TpRouteData?> handle(BuildContext context, ProtectedRoute route) {
    if (!isLoggedIn) return const LoginRoute();
    return null; // 允许进入
  }
}

@TpRoute(path: '/protected', redirect: AuthGuard)
class ProtectedPage extends StatelessWidget { ... }
```

### 生命周期拦截 (onExit)
拦截返回按钮（例如：未保存的更改）。

```dart
class UnsavedChangesGuard extends TpOnExit<EditorRoute> {
  @override
  FutureOr<bool> onExit(BuildContext context, EditorRoute route) async {
    return await showDialog(...) ?? false;
  }
}
```

---

## 📝 配置

在 `build.yaml` 中自定义输出路径：

```yaml
targets:
  $default:
    builders:
      tp_router_generator:
        options:
          output: lib/routes/route.gr.dart # 自定义输出路径
```
