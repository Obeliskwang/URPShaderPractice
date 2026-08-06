# Template

## Demo 概述

- Demo 路径：`Assets/Collection/Template/`
- Shader 主题：填写新 demo 的主题
- 当前状态：模板
- 目标管线：Unity URP 14+

## 问题

这个 demo 想解决的视觉或技术问题：

- 目标效果：
- 使用场景：
- 原始问题：
- 需要避免的问题：

## 方案

shader 或脚本的核心实现思路：

- Shader 文件：
- HLSL Include：
- Shader Graph：
- 配套脚本：
- 核心算法：
- 使用的数据：

## 效果

实际表现与展示方式：

- 展示场景：
- 主要视觉特征：
- 可调参数：
- 截图路径：
- 已知限制：

## 性能

性能成本和优化记录：

- Pass 数量：
- 纹理采样次数：
- 关键字/变体：
- 顶点阶段成本：
- 片元阶段成本：
- 带宽/采样压力：
- 移动端风险：
- Profiling 记录：

## 迭代日志

用于记录 shader 后续迭代路线，按两套模式填写：

- 新增问题 -> 解决方案
- 优化策略 -> 解决方案

### YYYY-MM-DD

- 新增问题：
- 解决方案：

- 优化策略：
- 解决方案：

## 参数说明

| 参数 | 类型 | 默认值 | 说明 |
| --- | --- | --- | --- |
| 待补充 | 待补充 | 待补充 | 待补充 |

## 目录说明

```text
Template/
├── Shaders/      放 shader、hlsl、shadergraph 等源码
├── Materials/    放材质、LUT 等展示资源
├── Textures/     放贴图、噪声图等资源
├── Meshes/       放该 demo 专属模型
├── Prefabs/      放该 demo 专属预制体
├── Scenes/       放展示场景
├── Scripts/      放该 demo 专属脚本
└── README.md     写该 shader 的功能、参数、限制和截图说明
```
