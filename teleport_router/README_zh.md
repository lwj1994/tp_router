# Flutter 路由神器 TeleportRouter，这也太好用了吧！😭

> **Teleport — 就像 LOL 里的传送。点一下，人就在那了。**
> 这个名字又好记又贴切！它完美契合了游戏中那种“瞬移”到目的地的感觉。再也不用纠结复杂的路由跳转逻辑，只需要调用 `.teleport()`，你就已经到达了目的地。


| Package | Version |
|---------|---------|
| [teleport_router](https://pub.dev/packages/teleport_router) | [![pub package](https://img.shields.io/pub/v/teleport_router.svg)](https://pub.dev/packages/teleport_router) |
| [teleport_router_annotation](https://pub.dev/packages/teleport_router_annotation) | [![pub package](https://img.shields.io/pub/v/teleport_router_annotation.svg)](https://pub.dev/packages/teleport_router_annotation) |
| [teleport_router_generator](https://pub.dev/packages/teleport_router_generator) | [![pub package](https://img.shields.io/pub/v/teleport_router_generator.svg)](https://pub.dev/packages/teleport_router_generator) |

家人们！发现一个超级好用的 Flutter 路由库 **TeleportRouter**！🚀
它是基于 `go_router` 封装的，意味着你拥有官方路由的所有强大功能（Deep Link、Web 支持、嵌套路由），但是用法简化了 100 倍！😍 告别手写字符串跳转，从此爱上写路由！

---

## ✨ 为什么选它？

- **🗝️ 嵌套路由不迷路**：只要告诉路由 "我爸是谁（NavKey）"，自动给你安排得明明白白！
- **📐 类型安全太香了**：`UserRoute(id: 1).teleport()`，再也不用担心拼错字符串了！
- **🐚 底部导航栏神器**：注解配置 BottomNav，几行代码搞定复杂嵌套！
- **🛡️ 守卫鉴权**：类型安全的路由守卫，未登录自动跳走，甚至还能监听登录状态自动刷新！
- **🧩 智能代码生成**：参数、返回值、Deep Link 全部自动搞定！

---

## 🧩 核心原理大揭秘 (必看！)

想用好 TeleportRouter，这这三个概念一定要懂，面试也能吹！

### 1. 黄金三角
- **Routes (`@TeleportRoute`)**：你的页面配置图纸。
- **Generator**：搬砖工，把你写的注解变成代码 (`UserRoute`)。
- **Router (`TeleportRouter`)**：大管家，底层指挥 `go_router` 干活。

### 2. TeleportNavKey：真正的幕后大佬
`TeleportNavKey` 不仅仅是个 `GlobalKey`！它是连接 **Shell (UI容器)**、**Navigator (页面栈)** 和 **Observer (观察者)** 的桥梁。
👉 **敲黑板**：定义 `class MainKey extends TeleportNavKey`，就是给自己造了一把专属钥匙，能够精准控制特定的导航栈！

### 3. 智能观察者 (Smart Observation)
TeleportRouter 会自动给每个 `TeleportNavKey` 注入特工 `TeleportRouteObserver`。
这意味着你可以随时随地：
- `popUntil` (一直退到某页)
- `removeWhere` (把某页偷偷删掉)
- `popToInitial` (一键回到首页)
这些操作在原生 `go_router` 里可是很难搞的哦！TeleportRouter 帮你做到了！�

---

## 📦 安装 (Installation)

在 `pubspec.yaml` 里加上：

```yaml
dependencies:
  teleport_router: ^0.5.1
  teleport_router_annotation: ^0.5.0

dev_dependencies:
  build_runner: ^2.4.0
  teleport_router_generator: ^0.5.0
```

运行小助手：
```bash
dart run build_runner build
```

---

## 🚀 快速上手保姆级教程

### 1. 造钥匙 (Define NavKeys)
新建文件 `lib/routes/nav_keys.dart`：

```dart
// 主 Shell 的钥匙 (比如 BottomNavigationBar)
class MainNavKey extends TeleportNavKey {
  const MainNavKey() : super('main');
}

// 首页的钥匙 (Branch 0)
class HomeNavKey extends TeleportNavKey {
  const HomeNavKey() : super('main', branch: 0);
}
```

### 2. 搭架子 (Define Shells)
给你的主页面加上注解，它是容器！

```dart
@TeleportShellRoute(
  navigatorKey: MainNavKey, // <--- 认领钥匙
  isIndexedStack: true,     // 开启状态保持 (切换 Tab 不重置)
  branchKeys: [HomeNavKey, SettingsNavKey], // <--- 定义分支
)
class MainShellPage extends StatelessWidget {
  final TeleportStatefulNavigationShell navigationShell; // 拿到控制器
  // ...
  // build 里面用 navigationShell 控制 Tab 切换
}
```

### 3. 写页面 (Define Routes)
给页面加注解，想嵌套就认爹！

```dart
// 首页，认 HomeNavKey 当爹，自动放进 Branch 0
@TeleportRoute(
  path: '/home', 
  isInitial: true,
  parentNavigatorKey: HomeNavKey 
)
class HomePage extends StatelessWidget { ... }

// 详情页，没有爹，就是顶层页面
@TeleportRoute(path: '/detail')
class DetailPage extends StatelessWidget { ... }
```

### 4. 跑起来 (Initialize)
在 `main.dart` 里初始化：

```dart
void main() {
  final router = TeleportRouter(
    routes: teleportRoutes, // 生成的代码
  );

  runApp(MaterialApp.router(
    routerConfig: router.routerConfig,
  ));
}
```

---

## 🧭 导航操作，丝滑！

### 类型安全跳转
```dart
// 普通跳转
UserRoute(id: 123).teleport();

// 等待返回值
final result = await SelectRoute().teleport<String>();

// 替换当前页 (Replace)
LoginRoute().teleport(replacement: true);

// 清空栈跳转 (如退出登录)
LoginRoute().teleport(clearHistory: true);
```

### 栈操作 (Pop & Stack)
```dart
// 推荐用 context 扩展，更安全！
context.teleportRouter.popTo(HomeRoute());

context.teleportRouter.popToInitial();

// 全局静态调用 (不推荐，除非没办法)
TeleportRouter.instance.pop();
```

---

## � 传参神器

不用解析 String，直接拿对象！

### Path & Query 参数
```dart
@TeleportRoute(path: '/user/:id')
class UserPage extends StatelessWidget {
  @Path('id') final String userId; // 自动从 URL 拿！
  @Query('q') final String? keyword; // 自动从 ?q=xxx 拿！
  
  const UserPage({required this.userId, this.keyword});
}
```

### 传递对象 (Extra)
```dart
UserRoute(userObj: myUser).teleport();
```

> 💣 **避坑指南 (重要！)**
> **Extra 对象存在内存里！**如果用户刷新浏览器、直接输入 URL 进入、或者 App 进程被杀，**Extra 会变成 null**！
> **持久化数据请务必用 Path/Query 参数或者本地存储！** 别怪我没提醒你哦！😭

---

## 🛡️ 路由守卫 (Guards)

### 全局守卫 (Global Redirect)
做登录检查最合适！

```dart
TeleportRouter(
  refreshListenable: Auth.instance, // 监听登录状态变化！
  redirect: (context, state) async {
    final bool loggedIn = await Auth.instance.checkLogin();
    if (!loggedIn && state.fullPath != '/login') {
      return LoginRoute(); // 没登录？去登录页！
    }
    return null; // 放行
  },
)
```

### 单个路由守卫
```dart
@TeleportRoute(path: '/vip', redirect: VipGuard)
class VipPage ...
```

---

## 🎨 动画 & 页面配置

小红书风格的左滑返回？安排！

```dart
@TeleportRoute(
  path: '/details',
  transition: TeleportSlideTransition(), // 右边滑入
  // 或者
  type: TeleportPageType.swipeBack, // 全屏左滑返回
)
```

还有透明弹窗 (Transparent Page)：
```dart
@TeleportRoute(
  opaque: false, // 透明！
  barrierColor: Color(0x80000000), // 半透明遮罩
  fullscreenDialog: true, // iOS 模态效果
)
class MyDialogPage ...
```

---

好啦，TeleportRouter 的精髓都在这里了！快去试试吧，真的能省下好多时间摸鱼！�
如果有问题，欢迎提 Issue 哦！❤️
