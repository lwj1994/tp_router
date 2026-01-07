# TpRouter

| Package | Version |
|---------|---------|
| [tp_router](https://pub.dev/packages/tp_router) | [![pub package](https://img.shields.io/pub/v/tp_router.svg)](https://pub.dev/packages/tp_router) |
| [tp_router_annotation](https://pub.dev/packages/tp_router_annotation) | [![pub package](https://img.shields.io/pub/v/tp_router_annotation.svg)](https://pub.dev/packages/tp_router_annotation) |
| [tp_router_generator](https://pub.dev/packages/tp_router_generator) | [![pub package](https://img.shields.io/pub/v/tp_router_generator.svg)](https://pub.dev/packages/tp_router_generator) |


一个基于 `go_router` 构建的，简化、类型安全且由注解驱动的 Flutter 路由库。

别再手动编写繁琐的路由表了。让 `tp_router` 为你处理一切，享受强类型和编译时安全带来的便利。

## 特性

*   🚀 **注解驱动**：直接在你的 Widget 上使用 `@TpRoute` 定义路由。
*   🛡️ **类型安全解析**：自动从路径 (Path)、查询参数 (Query) 或额外数据 (Extra) 中提取 `int`, `double`, `bool`, `String` 以及复杂对象。
*   🔄 **智能重定向**：强类型的重定向机制。在导航前检查强类型参数。
*   🐚 **Shell 路由与嵌套导航**：全面支持 `ShellRoute` 和 `StatefulShellRoute` (IndexedStack)。
*   ⚡ **简单的导航 API**：只需调用 `MyRoute().tp(context)`。

---

## 安装

在你的 `pubspec.yaml` 中添加以下内容：

```yaml
dependencies:
  tp_router: ^0.0.1
  tp_router_annotation: ^0.0.1

dev_dependencies:
  build_runner: ^2.4.0
  tp_router_generator: ^0.0.1
```

## 快速开始

### 1. 定义你的路由

使用 `@TpRoute` 注解你的 Widget 类。
构造函数中的参数会自动映射为路由参数！

```dart
// lib/pages/user_page.dart
import 'package:flutter/material.dart';
import 'package:tp_router/tp_router.dart';

@TpRoute(path: '/user/:id')
class UserPage extends StatelessWidget {
  // 自动从路径参数 ':id' 映射
  // 或者从查询参数 'id'，亦或是 extra 中的 'id'
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
    return Text('用户 $id - 区域 $section');
  }
}
```

### 2. 生成代码

运行 build runner 来生成路由表：

```bash
dart run build_runner build
```

这将会生成 `lib/tp_router.gr.dart` (默认路径)。

### 3. 初始化路由

在你的 `main.dart` 中，使用生成的路由表列表来初始化 `TpRouter`。

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
// 推送新路由 (Push)
UserPage(id: 42).tp(context);

// 替换当前路由 (Replace)
LoginPage().tp(context, replacement: true);

// 清除历史并进入新路由 (Clear history / Go)
HomePage().tp(context, clearHistory: true);

// 等待返回值 (Wait for result)
final result = await SelectProfileRoute().tp<String>(context);
```

你也可以弹出路由：
```dart
context.tpRouter.pop('Some Result');
```

---

## 功能详解

### 参数提取策略
TpRouter 会按照以下顺序智能解析构造函数参数：
1.  **显式注解**：`@Path('id')` (强制从 Path 获取) 或 `@Query('q')` (强制从 Query 获取)。
2.  **额外数据 (Extra)**：检查对象是否通过 `extra` 传递。
3.  **路径参数 (Path Params)**：检查 URL 路径中是否包含该 key。
4.  **查询参数 (Query Params)**：检查 URL 查询字符串。

### 重定向 / 守卫 (Guards)

TpRouter 支持强大且类型安全的重定向系统。
你可以定义一个重定向函数或类，通过它接收**完全实例化好的路由对象**。

**1. 定义重定向逻辑**
```dart
// 你可以直接访问 'route.id'！
FutureOr<TpRouteData?> checkUserAccess(BuildContext context, UserRoute route) {
  if (route.id == 999) {
    // 重定向到拦截页
    return const BlockedRoute();
  }
  return null; // 不重定向，继续进入页面
}
```

**2. 绑定到路由**
```dart
@TpRoute(path: '/user/:id', redirect: checkUserAccess)
class UserPage extends StatelessWidget { ... }
```

你也可以通过继承 `TpRedirect<T>` 类来更清晰地组织代码。

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

使用 `@TpShellRoute` 或 `@TpStatefulShellRoute` 来实现嵌套导航（例如底部导航栏）。

```dart
@TpStatefulShellRoute(
  branches: [
    [HomeRoute],
    [SettingsRoute],
  ],
)
class MainShellPage extends StatelessWidget {
  final TpStatefulNavigationShell navigationShell;
  
  const MainShellPage({required this.navigationShell});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navigationShell.currentIndex,
        onTap: (index) => navigationShell.goBranch(index),
        items: [ ... ],
      ),
    );
  }
}
```

---

## 配置

### 自定义输出路径

默认情况下，代码生成于 `lib/tp_router.gr.dart`。你可以在 `build.yaml` 中自定义此路径：

```yaml
targets:
  $default:
    builders:
      tp_router_generator:tp_router:
        options:
          output: lib/routes/app_routes.dart
```

---

## 迁移指南

正在考虑从 `go_router` 或 `auto_router` 切换？查看我们的[迁移指南](https://github.com/lwj1994/tp_router/blob/main/tp_router/MIGRATION_zh.md)。

## 许可证
