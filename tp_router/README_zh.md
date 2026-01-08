# TpRouter 🚀

| Package | Version |
|---------|---------|
| [tp_router](https://pub.dev/packages/tp_router) | [![pub package](https://img.shields.io/pub/v/tp_router.svg)](https://pub.dev/packages/tp_router) |
| [tp_router_annotation](https://pub.dev/packages/tp_router_annotation) | [![pub package](https://img.shields.io/pub/v/tp_router_annotation.svg)](https://pub.dev/packages/tp_router_annotation) |
| [tp_router_generator](https://pub.dev/packages/tp_router_generator) | [![pub package](https://img.shields.io/pub/v/tp_router_generator.svg)](https://pub.dev/packages/tp_router_generator) |

家人们，谁还在手写路由表啊？😩 Flutter 路由本身就够让人头大了，用 GoRouter 还要写一堆配置，简直心累！💔

**TpRouter 来救命了！** 🎉 它能根据你的 `NavKey` 自动生成复杂的嵌套路由表，而且 API 简洁到爆，简直是强迫症福音！✨

## 🌟 为什么必须用它？

*   🚀 **全自动生成路由表**：只需加个注解 `@TpRoute`，不管是简单的页面，还是复杂的 BottomNavigationBar 嵌套，全部自动搞定！再也不用写又臭又长的路由配置了！
*   💎 **API 简洁又优雅**：告别字符串跳转！类型安全，如丝般顺滑~
    *   `UserRoute(id: 1).tp(context)` 👈 就像调用函数一样简单
    *   `MainNavKey().tp(UserRoute(id: 1))` 👈 指定导航栈跳转，精准打击
*   🐚 **NavKey 驱动嵌套**：UI 解耦神器！定义 Shell 和子路由只需要关联同一个 `NavKey`，逻辑清晰，代码清爽！
*   🗑️ **优雅移除路由**：GoRouter 不支持移除中间的路由？TpRouter 支持！独特的 **Pending Pop** 策略，想删哪页删哪页，不管它藏得多深！😎

---

## 📦 极速上车 (Installation)

在 `pubspec.yaml` 里加上这几行：

```yaml
dependencies:
  tp_router: ^0.1.0
  tp_router_annotation: ^0.1.0

dev_dependencies:
  build_runner: ^2.4.0
  tp_router_generator: ^0.1.0
```

跑一下生成器：
```bash
dart run build_runner build
```

---

## 1. ⚡️ 快速开始

### 定义路由
在 Widget 上加个注解，构造函数参数直接映射成路由参数，简直不要太智能！🧠

```dart
@TpRoute(path: '/user/:id')
class UserPage extends StatelessWidget {
  final int id; 
  const UserPage({required this.id, super.key});
  
  @override
  Widget build(BuildContext context) => Text('User $id');
}
```

### 初始化
把生成的 `tpRoutes` 塞给 `TpRouter`，完事！✅

```dart
// main.dart
final router = TpRouter(routes: tpRoutes);

runApp(MaterialApp.router(
  routerConfig: router.routerConfig,
));
```

---

## 2. 🧭 导航系统 (Navigation)

TpRouter 提供了两种超好用的导航姿势：**Context 自动挡** 和 **Key 也就手动挡**。

### Context 自动挡 (推荐新手) 🚗
最简单的方式，它会自动向上查找最近的导航器。

```dart
// 跳转新页面
UserRoute(id: 42).tp(context);

// 替换当前页面
LoginRoute().tp(context, replacement: true);

// 清空历史跳转（比如登录后）
HomeRoute().tp(context, clearHistory: true);

// 返回
context.tpRouter.pop();
```

### Key 手动挡 (高手必备) 🏎️
使用 **TpNavKey**，在任何地方（哪怕是 ViewModel 里）都能精准控制导航，类型安全，重构也不怕！

1. **定义一个 Key**：
```dart
class MainNavKey extends TpNavKey {
  const MainNavKey() : super('main');
}
```

2. **用 Key 搞事情**：
```dart
// 在 'main' 这个导航栈里跳转
MainNavKey().tp(UserRoute(id: 42));

// 从 'main' 导航栈弹出
MainNavKey().pop();

// 甚至可以检查能不能返回
bool safe = MainNavKey().canPop;

// 高级返回：直到找到这页为止
MainNavKey().popUntil((route, data) => data?.routeName == UserRoute.kName);
```

---

## 3. 🐚 嵌套路由 & Shell (Shell Navigation)

搞定 BottomNavigationBar 这种复杂的嵌套 UI，用 **Shell Routes** 简直太轻松了！

### 定义外壳 (Shell)
把壳子和 `Key` 绑定起来。

```dart
@TpShellRoute(
  navigatorKey: MainNavKey, // 上面定义的那个 Key
  isIndexedStack: true,     // 保持 Tab 状态必备！
)
class MainShellPage extends StatelessWidget {
  final TpStatefulNavigationShell navigationShell;
  // ... 这里写 BottomNavigationBar，用 navigationShell 控制切换
}
```

### 往壳子里装页面
只需要指定 `parentNavigatorKey`，它就自动进去了！

```dart
// 首页，放在第 0 个 Tab
@TpRoute(path: '/home', parentNavigatorKey: MainNavKey, branchIndex: 0)
class HomePage extends StatelessWidget { ... }

// 设置页，放在第 1 个 Tab
@TpRoute(path: '/settings', parentNavigatorKey: MainNavKey, branchIndex: 1)
class SettingsPage extends StatelessWidget { ... }
```

---

## 4. 🔥 进阶大招

### 路由管理 (Route Management)
强势移除页面！

```dart
// 移除某个特定的路由实例
context.tpRouter.removeRoute(myRouteData);

// 批量移除（比如关掉所有弹窗）
context.tpRouter.removeWhere((data) => data.fullPath.contains('/dialog'));
```

### 路由守卫 (Guards)
类型安全的拦截器，未登录不让进！🛑

```dart
class AuthGuard extends TpRedirect<ProtectedRoute> {
  @override
  FutureOr<TpRouteData?> handle(BuildContext context, ProtectedRoute route) {
    if (!loggedIn) return const LoginRoute(); // 去登录
    return null; // 放行
  }
}

@TpRoute(path: '/protected', redirect: AuthGuard)
class ProtectedPage extends StatelessWidget { ... }
```

### 退出拦截 (onExit)
用户要滑走？挽留一下！🙏

```dart
class UnsavedChangesGuard extends TpOnExit<EditorRoute> {
  @override
  FutureOr<bool> onExit(BuildContext context, EditorRoute route) async {
    return await showDialog(...) ?? false; // 弹窗确认
  }
}

@TpRoute(path: '/edit', onExit: UnsavedChangesGuard)
class EditorPage extends StatelessWidget { ... }
```

---

## ⚙️ 配置 (Configuration)

想改生成文件的路径？在 `build.yaml` 里安排：

```yaml
targets:
  $default:
    builders:
      tp_router_generator:
        options:
          output: lib/routes.gr.dart # 比如改到这里
```

## 📚 迁移指南
从 GoRouter 或 AutoRouter 迁移过来？看这里 [MIGRATION.md](MIGRATION.md)。

---

家人们，这么好用的轮子，还不赶紧 star 起来？🌟
