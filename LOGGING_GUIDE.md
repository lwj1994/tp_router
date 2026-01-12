# TeleportRouter 日志系统指南

## 概述

TeleportRouter 内置了一个强大的日志系统 `LogUtil`，用于调试路由导航和参数传递。

## 启用日志

在创建 `TeleportRouter` 时设置 `enableLogging: true`：

```dart
void main() {
  final router = TeleportRouter(
    routes: generatedRoutes,
    enableLogging: true,  // 启用调试日志
  );

  runApp(MaterialApp.router(
    routerConfig: router.routerConfig,
  ));
}
```

## 日志输出示例

### 初始化日志

```
────────────────────────────────────────────────────────────
📌 TeleportRouter Initialization
────────────────────────────────────────────────────────────
ℹ️ [12:34:56.789] [TeleportRouter] [Info] Registering 15 routes
ℹ️ [12:34:56.790] [TeleportRouter] [Info] Initial location set to: /home
```

### 导航日志

#### 1. 简单导航（无参数）
```dart
HomeRoute().teleport();
```

输出：
```
🧭 [12:34:57.123] [TeleportRouter] [Navigation] push -> /home
🛣️ [12:34:57.124] [TeleportRouter] [Route] Route name: teleport_router_HomeRoute
```

#### 2. 带路径参数的导航
```dart
UserRoute(id: 123, name: 'Alice').teleport();
```

输出：
```
🧭 [12:34:58.456] [TeleportRouter] [Navigation] push -> /user/123?name=Alice
🛣️ [12:34:58.457] [TeleportRouter] [Route] Route name: teleport_router_UserRoute
📝 [12:34:58.458] [TeleportRouter] [Params] Path params: {id: 123}
📝 [12:34:58.459] [TeleportRouter] [Params] Query params: {name: Alice}
```

#### 3. 带 extra 数据的导航（Map）

**优化前**（只显示类型）：
```dart
DetailsRoute(data: {'key': 'value', 'count': 42}).teleport();
```
输出：
```
📝 [22:56:22.610] [TeleportRouter] [Params] Extra data: IdentityMap<String, dynamic>
```

**优化后**（显示具体内容）：
```dart
DetailsRoute(data: {'key': 'value', 'count': 42}).teleport();
```
输出：
```
🧭 [12:35:00.123] [TeleportRouter] [Navigation] push -> /details
🛣️ [12:35:00.124] [TeleportRouter] [Route] Route name: teleport_router_DetailsRoute
📝 [12:35:00.125] [TeleportRouter] [Params] Extra data: {key: value, count: 42}
```

#### 4. 带 extra 数据的导航（List）
```dart
ListRoute(items: ['item1', 'item2', 'item3']).teleport();
```

输出：
```
🧭 [12:35:01.456] [TeleportRouter] [Navigation] push -> /list
🛣️ [12:35:01.457] [TeleportRouter] [Route] Route name: teleport_router_ListRoute
📝 [12:35:01.458] [TeleportRouter] [Params] Extra data (list): [item1, item2, item3]
```

#### 5. 带自定义对象的导航
```dart
class User {
  final String name;
  final int age;

  User(this.name, this.age);

  @override
  String toString() => 'User(name: $name, age: $age)';
}

ProfileRoute(user: User('Alice', 25)).teleport();
```

输出：
```
🧭 [12:35:02.789] [TeleportRouter] [Navigation] push -> /profile
🛣️ [12:35:02.790] [TeleportRouter] [Route] Route name: teleport_router_ProfileRoute
📝 [12:35:02.791] [TeleportRouter] [Params] Extra data (User): User(name: Alice, age: 25)
```

### 返回导航日志

#### 1. 简单返回
```dart
router.pop();
```

输出：
```
🧭 [12:35:03.123] [TeleportRouter] [Navigation] pop
```

#### 2. 带返回值的返回

**字符串返回值**：
```dart
router.pop(result: 'Selected Item');
```

输出：
```
🧭 [12:35:04.456] [TeleportRouter] [Navigation] pop with result (String): Selected Item
```

**Map 返回值**：
```dart
router.pop(result: {'status': 'success', 'data': 123});
```

输出：
```
🧭 [12:35:05.789] [TeleportRouter] [Navigation] pop with result: {status: success, data: 123}
```

**List 返回值**：
```dart
router.pop(result: ['item1', 'item2', 'item3']);
```

输出：
```
🧭 [12:35:06.123] [TeleportRouter] [Navigation] pop with result (list): [item1, item2, item3]
```

**自定义对象返回值**：
```dart
class Result {
  final String status;
  final int code;

  Result(this.status, this.code);

  @override
  String toString() => 'Result(status: $status, code: $code)';
}

router.pop(result: Result('completed', 200));
```

输出：
```
🧭 [12:35:07.456] [TeleportRouter] [Navigation] pop with result (Result): Result(status: completed, code: 200)
```

#### 3. 无法返回的警告
```dart
router.pop(); // 在根路由时
```

输出：
```
⚠️ [12:35:08.789] [TeleportRouter] [Warning] Cannot pop: already at root route
```

### 替换和清空历史

#### 替换当前路由
```dart
LoginRoute().teleport(isReplace: true);
```

输出：
```
🧭 [12:35:06.123] [TeleportRouter] [Navigation] replace -> /login
🛣️ [12:35:06.124] [TeleportRouter] [Route] Route name: teleport_router_LoginRoute
```

#### 清空历史
```dart
HomeRoute().teleport(isClearHistory: true);
```

输出：
```
🧭 [12:35:07.456] [TeleportRouter] [Navigation] go (clear history) -> /home
🛣️ [12:35:07.457] [TeleportRouter] [Route] Route name: teleport_router_HomeRoute
```

## 日志图标说明

| 图标 | 标签 | 说明 |
|------|------|------|
| 🔍 | Debug | 调试信息 |
| ℹ️ | Info | 一般信息 |
| ⚠️ | Warning | 警告信息 |
| ❌ | Error | 错误信息 |
| 🧭 | Navigation | 导航事件 |
| 🛣️ | Route | 路由匹配 |
| 📝 | Params | 参数提取 |
| 🍞 | Breadcrumb | 面包屑导航 |

## 注意事项

1. **仅调试模式**: 日志只在 `kDebugMode == true` 时输出，Release 模式下完全静默
2. **性能影响**: 禁用日志时（`enableLogging: false`），所有日志调用立即返回，无性能损耗
3. **时间戳**: 所有日志都带有精确到毫秒的时间戳，格式：`HH:mm:ss.SSS`
4. **内部使用**: `LogUtil` 类不对外暴露，仅供 teleport_router 内部使用

## 调试技巧

### 1. 追踪完整导航流程

启用日志后，可以清晰地看到从初始化到每次导航的完整流程：

```
────────────────────────────────────────────────────────────
📌 TeleportRouter Initialization
────────────────────────────────────────────────────────────
ℹ️ [12:34:56.789] [Info] Registering 15 routes
ℹ️ [12:34:56.790] [Info] Initial location set to: /home

🧭 [12:34:57.123] [TeleportRouter] [Navigation] push -> /user/123
🛣️ [12:34:57.124] [TeleportRouter] [Route] Route name: teleport_router_UserRoute
📝 [12:34:57.125] [TeleportRouter] [Params] Path params: {id: 123}

🧭 [12:34:58.456] [TeleportRouter] [Navigation] push -> /user/123/profile
🛣️ [12:34:58.457] [TeleportRouter] [Route] Route name: teleport_router_ProfileRoute
📝 [12:34:58.458] [TeleportRouter] [Params] Path params: {userId: 123}

🧭 [12:34:59.789] [TeleportRouter] [Navigation] pop
```

### 2. 验证参数传递

通过日志验证路径参数、查询参数和 extra 数据是否正确传递：

```
📝 [12:35:00.123] [TeleportRouter] [Params] Path params: {userId: 123, postId: 456}
📝 [12:35:00.124] [TeleportRouter] [Params] Query params: {sort: asc, filter: active}
📝 [12:35:00.125] [TeleportRouter] [Params] Extra data: {user: User(name: Alice, age: 25), permissions: [read, write]}
```

### 3. 检测导航问题

日志可以帮助快速定位导航相关的问题：
- 路由是否正确匹配
- 参数是否正确解析
- 导航堆栈是否符合预期

## 最佳实践

1. **开发阶段启用**: 在开发和测试阶段始终启用日志
2. **生产环境关闭**: 在生产构建中确保 `enableLogging: false`
3. **结合调试工具**: 配合 Flutter DevTools 使用，获得更完整的调试体验
4. **关注警告**: 特别注意 ⚠️ 和 ❌ 级别的日志，它们通常指示潜在问题

## 示例项目

查看 `example` 目录中的完整示例应用，了解如何在实际项目中使用日志系统。
