# Grass

## 概述

这是一个可运行的 URP 程序化草地 Demo。它不需要预制草叶网格：在输入网格的三角面上执行曲面细分，再由 Geometry Shader 生成随表面法线生长的草叶。草叶拥有随机宽高和朝向、前向弯曲、风场动画、主方向光阴影接收与阴影投射。

- 环境：Unity `2022.3.62f2c1`、URP `14.0.12`。
- 场景：`Scenes/GrassDemo.unity`。
- 适用范围：桌面端 URP 效果原型、几何着色器学习与展示。

## 快速运行

打开 `Scenes/GrassDemo.unity`。场景包含 Plane、Sphere、Main Camera 和 Directional Light；Plane 与 Sphere 使用 `Materials/WindBlade.mat`。调整材质参数后可立即观察平面和曲面上的草叶分布、风场摆动及阴影效果。

## 实现结构

- `Shaders/WindBlade.shader`：包含 `ForwardLit` 与 `ShadowCaster` 两个 Pass，双面渲染；Forward Pass 接收主方向光阴影，ShadowCaster Pass 将生成的草叶写入 Shadow Map。
- `Shaders/GrassTessellation.hlsl`：Hull/Domain 阶段对每个输入三角形使用统一细分等级，增加草叶根点密度。
- `Shaders/GrassCommon.hlsl`：Geometry 阶段以细分后三角形中心为根点，生成 3 个片段、共 7 个顶点的草叶条带；同时计算随机变换、风场变形、渐变色、法线和阴影坐标。
- `Materials/WindBlade.mat`：演示材质与风场纹理配置。
- `Materials/Grass_WindNoise01.png`：风场纹理；R、G 通道采样后由 `0–1` 映射为 `-1–1`，分别驱动草叶局部 X/Z 方向的风偏移。

所有材质参数位于 `UnityPerMaterial` CBUFFER，保持 SRP Batcher 的常量缓冲区布局兼容。

## 主要参数

| 参数 | 默认材质值 | 说明 |
| --- | ---: | --- |
| `_BaseColor` | `(0.10, 0.40, 0.05, 1)` | 草根颜色。 |
| `_TopColor` | `(0.50, 0.80, 0.20, 1)` | 草尖颜色。 |
| `_GrassWidth` / `_GrassHeight` | `0.02` / `2.00` | 草叶基础宽度和高度。 |
| `_GrassWidthRandom` / `_GrassHeightRandom` | `0.05` / `0.30` | 每片草叶的随机尺寸范围。 |
| `_RandomRotation` | `1.00` | 绕表面法线的随机朝向强度。 |
| `_BendRotationRandom` | `0.40` | 随机倾倒和风致弯曲幅度。 |
| `_GrassForward` | `0.29` | 草尖前向弯曲距离。 |
| `_GrassCurve` | `3.10` | 弯曲曲线指数；值越高，弯曲越集中在草尖。 |
| `_TessellationUniform` | `7.60` | 每个输入三角形的统一曲面细分等级。 |
| `_WindFrequency` | `(0.05, 0.05, 0, 0)` | 风场随时间滚动的 XY 速度。 |

## 渲染与平台限制

- Shader 使用 Hull、Domain 和 Geometry Shader，目标为 `#pragma target 4.6`；适合 DX11/DX12 等桌面端图形 API。
- Geometry Shader 在移动端 Metal/Vulkan 路径上支持和吞吐量有限；不适合作为移动端或 WebGL 的草地方案。
- 每个细分后的草根在 Forward 和 ShadowCaster 两个 Pass 中都会生成草叶，并各采样一次风场纹理。细分等级和输入网格三角形数会同时放大顶点、几何和阴影开销。
- 当前没有距离裁剪、LOD 或自适应曲面细分。大面积网格和远景草地应先在 Unity Profiler、Frame Debugger、RenderDoc 中测量 Pass 耗时、三角形数与阴影图成本，再加入分块、距离裁剪和 LOD。

## 目录

```text
Grass/
├── Shaders/      WindBlade Shader、公共草叶逻辑和曲面细分逻辑
├── Materials/    WindBlade 材质与风场纹理
├── Meshes/       当前无专属模型
├── Prefabs/      当前无专属预制体
├── Scenes/       GrassDemo 演示场景
├── Scripts/      当前无专属脚本
└── README.md     实现、参数与平台限制说明
```

## 迭代记录

### 2026-08-06

- 完善可运行 Demo 的入口、渲染结构、材质参数和平台限制说明。
- 记录 Geometry Shader 草地的桌面端定位，以及后续距离裁剪、LOD 和自适应细分的优化方向。
