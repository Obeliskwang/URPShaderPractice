# Grass

## 问题

在不准备草叶网格的情况下，从普通表面生成具有随机朝向、宽高变化、弯曲和风场动画的草叶，并让草叶在 URP 中接收主光阴影、投射阴影。

- 目标环境：Unity `2022.3.62f2c1`，URP `14.0.12`
- 展示场景：`Scenes/GrassDemo.unity`
- 适用范围：桌面级 URP 草地、植被原型与 Shader 学习展示
- 不依赖 Renderer Feature、Volume Profile 或额外脚本

## 方案

- `Shaders/WindBlade.shader` 提供 ForwardLit 与 ShadowCaster 两个 Pass。
- `Shaders/GrassTessellation.hlsl` 对输入三角面做统一曲面细分，增加草根采样点。
- `Shaders/GrassCommon.hlsl` 在几何阶段生成三段草叶，并计算随机旋转、随机弯曲、风场扰动、颜色渐变、法线与阴影坐标。
- 材质参数放入 `UnityPerMaterial` CBUFFER，以兼容 SRP Batcher 的材质常量布局。
- ShaderLab 注册路径：`URPShaderPractice/Grass/WindBlade`。

风场纹理 `Materials/Grass_WindNoise01.png` 的通道语义：

- R：世界空间风场 X 分量，采样后由 `0..1` 映射到 `-1..1`
- G：世界空间风场 Z 分量，采样后由 `0..1` 映射到 `-1..1`
- B/A：当前版本未使用
- 为保持源效果，迁移时保留原始 sRGB 导入设置；如果改为线性数据纹理，需要重新校准风力观感

## 效果

- Plane 展示平面草地，Sphere 展示草叶沿曲面法线生长的效果。
- 草根到草尖在 `_BaseColor` 与 `_TopColor` 之间渐变。
- `_WindFrequency` 控制风场滚动速度，纹理 Tiling 控制风场空间尺度。
- 截图占位：`Screenshots/GrassDemo.png`（待在 Unity Game View 中补充）。

主要参数：

| 参数 | 类型 | 材质值 | 说明 |
| --- | --- | ---: | --- |
| `_BaseColor` | Color | `(0.10, 0.40, 0.05, 1)` | 草根颜色 |
| `_TopColor` | Color | `(0.50, 0.80, 0.20, 1)` | 草尖颜色 |
| `_GrassWidth` | Float | `0.02` | 草叶基础宽度 |
| `_GrassHeight` | Float | `2.00` | 草叶基础高度 |
| `_GrassWidthRandom` | Float | `0.05` | 宽度随机范围 |
| `_GrassHeightRandom` | Float | `0.30` | 高度随机范围 |
| `_RandomRotation` | Range | `1.00` | 绕表面法线的随机朝向强度 |
| `_BendRotationRandom` | Range | `0.40` | 随机弯曲及风弯曲强度 |
| `_GrassForward` | Float | `0.29` | 草叶向前弯曲距离 |
| `_GrassCurve` | Range | `3.10` | 弯曲曲线指数 |
| `_TessellationUniform` | Range | `7.60` | 曲面细分密度 |
| `_WindFrequency` | Vector | `(0.05, 0.05, 0, 0)` | 风场随时间滚动速度 |

## 性能

- 2 个 Pass：ForwardLit 与 ShadowCaster。
- 每个草根由几何着色器输出 7 个顶点；草根数量随输入三角形数量与 `_TessellationUniform` 快速增长。
- 每个生成点在两个 Pass 中各采样一次风场纹理。
- `#pragma target 4.6`，并依赖 Hull、Domain 与 Geometry Shader；不适合移动端、WebGL，以及缺少这些阶段的平台。
- 当前没有距离裁剪、LOD 或自适应细分，远景和大面积网格可能产生较高 GPU 成本。
- 建议用 Unity Profiler、Frame Debugger 和 RenderDoc 检查目标平台；性能数据尚未实测。

## 迭代日志

### 2026-08-04

- 新增问题 -> 将旧项目中的草 Shader、HLSL、材质、风场纹理与展示场景迁移到独立 Grass 模块。
- 解决方案 -> 保留资源 GUID，修复迁移后的 include 路径，统一 ShaderLab 注册路径与资产命名，并移除场景中的源项目专属依赖。
- 优化策略 -> 保持原始视觉和 sRGB 风场采样，不在迁移阶段改变风力标定。
- 解决方案 -> 在 README 记录纹理通道、桌面平台限制和后续性能验证项。

## 目录说明

```text
Grass/
├── Shaders/      WindBlade Shader 与 Grass HLSL
├── Materials/    WindBlade 材质与 Grass 风场纹理
├── Meshes/       当前无专属模型
├── Prefabs/      当前无专属预制体
├── Scenes/       GrassDemo 展示场景
├── Scripts/      当前无专属脚本
└── README.md     实现、参数、限制与迁移记录
```
