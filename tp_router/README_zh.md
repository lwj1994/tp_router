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
*   🗑️ **智能路由移除**：使用优雅的 **Pending Pop** 策略，命令式地移除路由（即使是后台路由）。
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

TpRouter 提供了一种强大且解耦的方式来定义 Shell 路由，通过使用 **Key**。不需要手动列出子路由，只需给 Shell 分配一个 `navigatorKey`，并使用 `parentNavigatorKey` 关联子路由。

这种方法让代码更整洁、模块化，非常适合复杂的应用！

#### 1. 定义 Shell 路由
为你的 Shell 布局分配一个唯一的 `navigatorKey`。

```dart
// 有状态 Shell (例如: 底部导航栏)
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
          BottomNavigationBarItem(icon: Icon(Icons.home), label: '首页'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: '设置'),
        ],
      ),
    );
  }
}
```

#### 2. 关联子路由
只需在属于 Shell 的路由中添加 `parentNavigatorKey`。
对于有状态 Shell (Tabs)，使用 `branchIndex` 将路由分配到特定的 Tab。

```dart
// 分支 0: 首页
@TpRoute(path: '/', parentNavigatorKey: 'main', branchIndex: 0)
class HomePage extends StatelessWidget { ... }

// 分支 1: 设置
@TpRoute(path: '/settings', parentNavigatorKey: 'main', branchIndex: 1)
class SettingsPage extends StatelessWidget { ... }
```

#### 3. 嵌套 Shell (进阶)
你甚至可以在一个 Shell 中嵌套另一个 Shell！只需将内部 Shell 视为外部 Shell 的子路由。

```dart
// 位于 'main' Shell 第 3 个分支中的 Shell
@TpShellRoute(
  navigatorKey: 'dashboard',   // 该 Shell 自己的 Key
  parentNavigatorKey: 'main',  // 父级 Shell 的 Key
  branchIndex: 2,              // 放置在 'main' 的第 2 个分支中
)
class DashboardShell extends StatelessWidget { ... }

// 嵌套 'dashboard' Shell 的子路由
@TpRoute(path: '/dashboard/stats', parentNavigatorKey: 'dashboard')
class StatsPage extends StatelessWidget { ... }
```

---

### 高级路由管理 (智能移除)

由于 `go_router` 的声明式和基于 URL 的架构，命令式移除路由（例如：从堆栈中间移除一个页面）通常受到严格限制。

TpRouter 通过智能的 **Pending Pop (延迟弹出)** 策略克服了这一限制：

1.  **顶部路由**：如果路由位于栈顶，它会被立即弹出 (Pop)。
2.  **后台路由**：它会被内部标记为“待移除”。为了不破坏 URL 的一致性，TpRouter 不会强行修改 `go_router` 堆栈，而是选择等待。
3.  **自动跳过**：当用户最终回退导航，且被标记的路由重新显示时，TpRouter 会**自动且立即地弹出它**。

这种机制在严格遵守 `go_router` 约束的同时，为用户创造了无缝的“删除”体验。

**示例：**

```dart
// 1. 移除特定的路由实例
// (根据路由名称和参数匹配)
context.tpRouter.removeRoute(LoginRoute());

// 2. 根据逻辑移除 (状态清理)
// 示例：移除所有与已删除订单相关的屏幕
final deletedCount = context.tpRouter.removeWhere((data) {
  return data.pathParams['orderId'] == '12345';
});

// 3. 移除所有弹窗或特定模式
context.tpRouter.removeWhere((data) {
  return data.fullPath.contains('/dialog/');
});
```

此功能与 `TpRouteObserver` 完全集成，确保存源清理和状态一致性。

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
