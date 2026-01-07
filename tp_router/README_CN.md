# TpRouter

| Package | Version |
|---------|---------|
| [tp_router](https://pub.dev/packages/tp_router) | [![pub package](https://img.shields.io/pub/v/tp_router.svg)](https://pub.dev/packages/tp_router) |
| [tp_router_annotation](https://pub.dev/packages/tp_router_annotation) | [![pub package](https://img.shields.io/pub/v/tp_router_annotation.svg)](https://pub.dev/packages/tp_router_annotation) |
| [tp_router_generator](https://pub.dev/packages/tp_router_generator) | [![pub package](https://img.shields.io/pub/v/tp_router_generator.svg)](https://pub.dev/packages/tp_router_generator) |


一个简化、类型安全、注解驱动的 Flutter 路由库，基于 `go_router` 构建。

停止手动编写样板路由表。让 `tp_router` 为您处理一切，享受强类型和编译时安全。

## 特性

*   🚀 **注解驱动**: 直接在 Widget 上使用 `@TpRoute` 定义路由。
*   🛡️ **类型安全解析**: 自动从路径、查询参数或 extra 数据中提取 `int`, `double`, `bool`, `String` 和复杂对象。
*   🔄 **智能重定向**: 强类型的重定向机制。在导航前检查参数。
*   🐚 **Shell 路由 & 嵌套导航**: 完全支持 `ShellRoute` 和 `StatefulShellRoute` (IndexedStack)。
*   ⚡ **简单的导航 API**: 只需调用 `MyRoute().tp(context)`。
*   🎨 **页面配置**: 支持自定义转场动画、透明背景、全屏 Dialog 等配置。

---

## 安装

在 `pubspec.yaml` 中添加以下内容：

```yaml
dependencies:
  tp_router: ^0.1.0
  tp_router_annotation: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
  tp_router_generator: ^0.1.0
```

## 快速开始

### 1. 定义路由

使用 `@TpRoute` 注解您的 Widget。
构造函数参数会自动映射为路由参数！

```dart
// lib/pages/user_page.dart
import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';

@TpRoute(path: '/user/:id')
class UserPage extends StatelessWidget {
  // 自动从路径参数 ':id' 映射
  // 或者从查询参数 'id'，或者 extra 数据 'id'。
  final int id; 
  
  // 带有默认值的可选参数
  final String section; 

  const UserPage({
    required this.id,
    this.section = 'profile',
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Text('User $id - Section $section');
  }
}
```

### 2. 生成代码

运行 build runner 来生成路由表：

```bash
dart run build_runner build
```

这将生成 `lib/tp_router.gr.dart`（默认路径）。

### 3. 初始化 Router

在 `main.dart` 中，使用生成的路由列表初始化 `TpRouter`。

```dart
import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';
import 'tp_router.gr.dart'; // 导入生成的文件

void main() {
  final router = TpRouter(
    routes: tpRoutes, // 生成的路由列表
  );

  runApp(MaterialApp.router(
    routerConfig: router.routerConfig,
  ));
}
```

---

## 导航

使用生成的路由类进行导航。这是 100% 类型安全的。

```dart
// Push 一个新路由
UserPage(id: 42).tp(context);

// 替换当前路由
LoginPage().tp(context, replacement: true);

// 清空历史并跳转
HomePage().tp(context, clearHistory: true);

// 等待返回结果
final result = await SelectProfileRoute().tp<String>(context);
```

也可以 pop：
```dart
context.tpRouter.pop('Some Result');
```

---

## 功能详解

### 参数提取策略
TpRouter 智能地按以下顺序解析构造函数参数：
1.  **显式注解**: `@Path('id')` (强制路径参数) 或 `@Query('q')` (强制查询参数)。
2.  **Extra 数据**: 检查对象是否通过 parameters 传递（extra map）。
3.  **路径参数**: 检查 URL 路径是否包含该 key。
4.  **查询参数**: 检查 URL 查询字符串。

### 重定向 / 守卫 (Guards)

TpRouter 支持强大且类型安全的重定向系统。
您可以定义一个重定向函数或类，接收**完全实例化后的路由对象**。

**1. 定义重定向逻辑**
```dart
// 您可以直接访问 'route.id'！
FutureOr<TpRouteData?> checkUserAccess(BuildContext context, UserRoute route) {
  if (route.id == 999) {
    // 重定向到拦截页
    return const BlockedRoute();
  }
  return null; // 不重定向，继续访问
}
```

**2. 绑定到路由**
```dart
@TpRoute(path: '/user/:id', redirect: checkUserAccess)
class UserPage extends StatelessWidget { ... }
```

您也可以使用扩展自 `TpRedirect<T>` 的类，让代码更整洁：

```dart
class AuthRedirect extends TpRedirect<ProtectedRoute> {
  const AuthRedirect();
  @override
  FutureOr<TpRouteData?> handle(BuildContext context, ProtectedRoute route) {
    if (!AuthService.isLoggedIn) {
      return const LoginRoute();
    }
    return null;
  }
}

@TpRoute(path: '/protected', redirect: AuthRedirect)
class ProtectedPage extends StatelessWidget { ... }
```

### Shell 路由 (嵌套导航)

TpRouter 提供了一种强大且解耦的方式来定义 Shell 路由，使用 **Keys**。您不需要手动列出 children，只需要给 Shell 分配一个 `navigatorKey`，并使用 `parentNavigatorKey` 关联子路由。

这种方法保持了代码的模块化，非常适合大型应用！

#### 1. 定义 Shell 路由
给您的 Shell 布局分配一个唯一的 `navigatorKey`。

```dart
// Stateful Shell (例如：底部导航栏)
@TpShellRoute(
  navigatorKey: 'main', 
  isIndexedStack: true, // 保持每个分支的状态
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
        // 切换分支的辅助方法
        onTap: (index) => navigationShell.goBranch(index),
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
```

#### 2. 关联子路由
只需在属于该 Shell 的任何路由上添加 `parentNavigatorKey`。
对于 Stateful Shells (Tabs)，使用 `branchIndex` 将路由分配给特定的 Tab。

```dart
// Branch 0: Home
@TpRoute(path: '/', parentNavigatorKey: 'main', branchIndex: 0)
class HomePage extends StatelessWidget { ... }

// Branch 1: Settings
@TpRoute(path: '/settings', parentNavigatorKey: 'main', branchIndex: 1)
class SettingsPage extends StatelessWidget { ... }
```

#### 3. 嵌套 Shell (高级)
您甚至可以在一个 Shell 内嵌套另一个 Shell！只需将内部 Shell 视为外部 Shell 的子节点。

```dart
// 嵌在 'main' Shell 第3个分支内的 Shell
@TpShellRoute(
  navigatorKey: 'dashboard',   // 该 Shell 自己的 Key
  parentNavigatorKey: 'main',  // 父 Shell 的 Key
  branchIndex: 2,              // 放在 'main' 的第2个分支
)
class DashboardShell extends StatelessWidget { ... }

// 'dashboard' Shell 的子节点
@TpRoute(path: '/dashboard/stats', parentNavigatorKey: 'dashboard')
class StatsPage extends StatelessWidget { ... }
```

#### 4. 配置页面和转场
您可以像普通路由一样自定义 Shell 路由的页面行为、转场和 Observers。

```dart
@TpShellRoute(
  navigatorKey: 'modal_shell',
  parentNavigatorKey: 'root',
  // 让 Shell 背景透明 (例如用于 Dialog)
  opaque: false, 
  // 添加自定义转场
  transition: TpFadeTransition,
  transitionDuration: Duration(milliseconds: 300),
  // 添加 Observers
  observers: [MyObserver],
)
class ModalShellPage extends StatelessWidget { ... }
```

---

## 自定义配置

### 自定义输出路径

默认情况下，代码生成在 `lib/tp_router.gr.dart`。您可以在 `build.yaml` 中修改：

```yaml
targets:
  $default:
    builders:
      tp_router_generator:
        options:
          output: lib/router/route.gr.dart
```

---

## 迁移指南

考虑从 `go_router` 或 `auto_router` 迁移？查看我们的 [迁移指南](https://github.com/lwj1994/tp_router/blob/main/tp_router/MIGRATION.md).

## License

MIT
