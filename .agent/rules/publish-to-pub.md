---
trigger: always_on
---

1. 先更新版本号。只改动 version: 0.4.0 。其他的依赖版本不要改
2. 始终保持   tp_router_annotation:  ，不要修改 tp_router_annotation 的版本 
3. 3 个库的版本号统一，及时没有任何代码改动
2. 编写 changelog
3. 按顺序发布 
	a. tp_router_annotation
	b. tp_router_genarator
	c. tp_router
4. 发布代码： fd pub publish   执行后等待一会 输入 y
5. 发布结束后，执行 git add . && git commit -m  "publish version:xx"