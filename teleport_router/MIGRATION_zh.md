# 迁移指南 (Migration Guide)

本指南将帮助你从 `go_router` 或 `auto_router` 迁移到 `teleport_router`。

---

## 1. 从 go_router 迁移

`teleport_router` 本身是基于 `go_router` 的包装，因此底层的能力是完全一致的，主要区别在于配置方式和 API。

### 配置路由表

*   **go_router**: 你需要手动维护一个巨大的 `GoRouter` 实例，手动解析 `state.pathParameters` 并传递给 Widget。

```dart
// go_router
final router = GoRouter(
  routes: [
    GoRoute(
      path: '/user/:id',
      builder: (context, state) => UserPage(
        id: int.parse(state.pathParameters['id']!),
        name: state.uri.queryParameters['name'],
      ),
    ),
  ],
);
```

*   **teleport_router**: 通过注解直接定义在 Widget 上，参数自动解析。

```dart
// teleport_router
@TeleportRoute(path: '/user/:id')
class UserPage extends StatelessWidget {
  final int id; // 自动从 :id 解析并转为 int
  final String? name; // 自动从 query 获取

  const UserPage({required this.id, this.name});
}

// 初始化时直接传入生成的路由表
final router = TeleportRouter(routes: teleportRoutes);
```

### 导航 API

*   **go_router**: 使用字符串路径。容易拼错，且无法强制传递必要的参数。

```dart
context.push('/user/42?name=Alice');
```

*   **teleport_router**: 使用生成的路由类。编译时检查参数，自动处理 URL 拼接。

```dart
UserRoute(id: 42, name: 'Alice').teleport(context);
```

### 重定向 (Redirect)

*   **go_router**: 全局闭包，需要手动解析 state 字符串。

*   **teleport_router**: 强类型实例访问。

```dart
// teleport_router
@TeleportRoute(path: '/profile', redirect: profileRedirect)
// ...
FutureOr<TeleportRouteData?> profileRedirect(BuildContext context, ProfileRoute route) {
  if (AuthService.isGuest) return const LoginRoute();
  return null;
}
```

---

## 2. 从 auto_router 迁移

`teleport_router` 的体验与 `auto_router` 类似，但更加轻量，且直接基于官方的 `go_router` 体系。

### 路由定义

*   **auto_router**: 需要 `@RoutePage()` 注解 Widget，然后在 `AppRouter` 类中再次手动声明所有的路由。
*   **teleport_router**: 只需一步 `@TeleportRoute`，不需要维护一个中央路由清单类。

### 参数解析

*   **auto_router**: 使用 `@PathParam('id')` 或 `AutoRouter` 特有的逻辑。
*   **teleport_router**: 默认遵循构造函数参数名匹配原则（Smart Match），可选 `@Path` 或 `@Query` 注解。

### 嵌套路由 (Shell Route)

*   **auto_router**: 使用 `AutoTabsRouter` 等特殊组件。
*   **teleport_router**: 使用标准的 `@TeleportShellRoute` 或 `@TeleportStatefulShellRoute`，生成后直接使用 `navigationShell` 控制。

---

## 总结

| 特性 | go_router | auto_router | teleport_router |
|---|---|---|---|
| **路由定义** | 手动 (Manual) | 注解 + 手动清单 | **注解 (Decentralized)** |
| **参数提取** | 手动解析 state | 自动 (需注解) | **自动 (智能匹配)** |
| **导航** | 字符串 (String-based) | 类 (Class-based) | **类 (Class-based)** |
| **底层实现** | 原生 | 自研封装 | **基于 go_router (原生兼容)** |
| **轻量级** | 高 | 低 | **极高** |
