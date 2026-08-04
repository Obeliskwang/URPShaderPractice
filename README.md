# URP Shader Practice

这是一个用于整理 Unity URP Shader 练习、实验和展示场景的仓库。每个 shader demo 独立放在 `Assets/Collection/` 下，公共资源放在 `Shared/` 下，方便后续持续扩展、对比和复用。

## 项目环境

- Unity: `2022.3.62f2c1`
- Render Pipeline: Universal Render Pipeline `14.0.12`
- 目标用途：URP shader / HLSL / Shader Graph 练习与效果归档

## 仓库内容

```text
URPShaderPractice/
├── Assets/
│   ├── Collection/       每个 shader demo 的独立目录
│   ├── Settings/         Unity 质量档与渲染管线配置
│   └── URP/              URP Pipeline Asset 与 Renderer 配置
├── Packages/             Unity Package Manager 依赖
├── ProjectSettings/      Unity 项目设置
├── Shared/               多个 demo 共用的 shader、材质、模型、脚本等资源
└── README.md             仓库总览与目录规范
```

## Demo 列表

| Demo | 路径 | 状态 | 说明 |
| --- | --- | --- | --- |
| Grass | `Assets/Collection/Grass/` | 待补充 | 草地、植被或风场相关 shader demo |
| Water | `Assets/Collection/Water/` | 待补充 | 水面、波纹、折射或泡沫相关 shader demo |
| Scanline | `Assets/Collection/Scanline/` | 待补充 | 扫描线、屏幕故障或后处理风格 shader demo |
| Template | `Assets/Collection/Template/` | 模板 | 新建 demo 时参考的目录模板 |

## Shader 文档格式

每个 demo 的 README 建议按照“问题 - 方案 - 效果 - 性能 - 迭代日志”来写。前四项说明当前版本的设计结果，迭代日志记录后续发现和调整路线。

### 问题

说明这个 shader 想解决什么视觉或技术问题。

- 目标效果：
- 使用场景：
- 原始问题：
- 限制条件：

### 方案

说明 shader 或配套脚本的核心实现思路。

- 渲染管线：
- Shader 类型：
- 核心算法：
- 关键贴图或数据：
- 主要参数：

### 效果

说明实际观感、可调范围和展示方式。

- 展示场景：
- 主要视觉特征：
- 推荐截图：
- 已知限制：

### 性能

说明成本来源和优化方向，不建议在未测试前写固定 FPS。

- 主要成本：
- 纹理采样：
- Pass 数量：
- 变体/Keyword：
- 移动端风险：
- Profiling 工具：Unity Profiler、Frame Debugger、RenderDoc

### 迭代日志

用于记录 shader 后续迭代，不需要写得很长，重点是留下“为什么改、怎么改”的路线。日志按两套模式记录：

```text
新增问题 -> 解决方案
优化策略 -> 解决方案
```

建议格式：

```text
#### YYYY-MM-DD

- 新增问题：
- 解决方案：

- 优化策略：
- 解决方案：
```

## Demo 目录规范

以 `Assets/Collection/Grass/` 为例：

```text
Collection/Grass/
├── Shaders/      放 shader、hlsl、shadergraph 等源码
├── Materials/    放材质、贴图、噪声图、LUT 等展示资源
├── Meshes/       放该 demo 专属模型
├── Prefabs/      放该 demo 专属预制体
├── Scenes/       放展示场景
├── Scripts/      放该 demo 专属脚本
└── README.md     写该 shader 的功能、参数、限制和截图说明
```

## Shared 目录用途

`Shared/` 用于存放多个 demo 共用的资源，避免重复拷贝：

```text
Shared/
├── Shaders/      多个 demo 共用的 shader include 或工具函数
├── Materials/    多个 demo 共用的材质、贴图、噪声图或 LUT
├── Meshes/       多个 demo 共用的模型
├── Prefabs/      通用相机、灯光、展示台等预制体
└── Scripts/      通用相机控制、UI 展示脚本等
```

## 资产命名规范

目录负责区分 demo 模块和资产类型，文件名只表达具体内容、必要语义和变体。不要重复添加 `Shader`、`Material`、`Mat`、`Mesh`、`Prefab`、`Scene` 等类型字段。

- 使用英文、数字和 PascalCase，不使用空格、中文或连字符。
- 序号统一使用两位数字，例如 `01`、`02`。
- 不使用 `New`、`Final`、`Latest`、`Copy` 等临时名称。
- 贴图必须保留用途语义；Grass 贴图以 `Grass` 为主体，例如 `Grass_BaseColor.png`、`Grass_Normal.png`、`Grass_WindNoise01.png`。
- 场景使用 `<Demo><用途>.unity`，不加下划线，例如 `GrassDemo.unity`、`GrassPerformance.unity`、`GrassDebug.unity`。
- C# 文件名必须与类名一致，例如 `GrassWindController.cs`。
- `Shared/` 内资产不再添加 `Shared` 前缀。
- ShaderLab 内部路径必须包含项目和模块，例如 `Shader "URPShaderPractice/Grass/WindBlade"`。
- 资产与对应 `.meta` 必须一起提交；不要手动修改 GUID。

示例：

```text
Shaders/WindBlade.shader
Shaders/WindCommon.hlsl
Materials/WindBlade.mat
Materials/Grass_BaseColor.png
Materials/Grass_Normal.png
Meshes/Blade_LOD0.fbx
Prefabs/WindPatch.prefab
Scenes/GrassDemo.unity
Scripts/GrassWindController.cs
```

## 新增 Demo 流程

1. 复制 `Assets/Collection/Template/`。
2. 重命名为新的 demo 名称，例如 `Assets/Collection/Dissolve/`。
3. 将 shader、hlsl、shadergraph 放入 `Shaders/`。
4. 将材质、贴图、模型、预制体和展示场景放入对应目录。
5. 按 README 模板补充“问题 - 方案 - 效果 - 性能”，并在迭代日志中记录后续问题和优化。
