# URP Shader Practice

用于整理、实验和展示 Unity URP Shader 的练习仓库。每个 Demo 独立放在 `Assets/Collection/`，公共资源放在 `Shared/`，便于持续扩展、对比和复用。

## 项目环境

- Unity：`2022.3.62f2c1`
- Render Pipeline：Universal Render Pipeline `14.0.12`
- 用途：URP Shader、HLSL 与 Shader Graph 的效果练习和归档。

## 仓库结构

```text
URPShaderPractice/
├── Assets/
│   ├── Collection/       各 Demo 的独立目录
│   ├── Settings/         质量与渲染管线配置
│   └── URP/              URP Pipeline Asset 与 Renderer 配置
├── Packages/             Unity Package Manager 依赖
├── ProjectSettings/      Unity 项目设置
├── Shared/               多个 Demo 共用的资源
└── README.md             仓库总览
```

## Demo 列表

| Demo | 路径 | 状态 | 说明 |
| --- | --- | --- | --- |
| **Grass** | `Assets/Collection/Grass/` | 可运行 | 基于 Hull、Domain 与 Geometry Shader 的程序化草叶：曲面细分生成根点，支持随机尺寸、朝向、弯曲、风场、主光阴影和投射阴影。入口场景：`Scenes/GrassDemo.unity`。 |
| Scanline | `Assets/Collection/Scanline/` | 待补充 | 扫描线、屏幕故障或后处理风格 Shader Demo。 |
| **Stylized Sky** | `Assets/Collection/Sky/StylizedSky/` | 可运行 | 程序化昼夜天空盒：日/月、星空、云层、地平线辉光，以及主方向光、雾色、SRP Lens Flare 和动态 GI 同步。入口场景：`Scenes/StylizedSkyDemo.unity`。 |
| Water | `Assets/Collection/Water/` | 待补充 | 水面、波纹、折射或泡沫相关 Shader Demo。 |
| Template | `Assets/Collection/Template/` | 模板 | 新建 Demo 时使用的目录模板。 |

## Demo 展示

### Grass



### Scanline

<img src=".\images\scanline.gif" style="zoom: 50%;" />

### Stylized Sky

<img src=".\images\stylizedsky.gif" style="zoom:150%;" />

### Water



## Demo 目录规范

```text
Collection/<DemoName>/
├── Shaders/      .shader、.hlsl、.shadergraph
├── Materials/    材质、贴图、噪声图、LUT
├── Meshes/       Demo 专属模型
├── Prefabs/      Demo 专属预制体
├── Scenes/       展示场景
├── Scripts/      Demo 专属脚本
└── README.md     功能、参数、限制和性能说明
```

`Shared/` 用于放置多个 Demo 共用的 Shader include、材质、模型、预制体和脚本，避免跨 Demo 重复拷贝。

## 新增 Demo 流程

1. 复制 `Assets/Collection/Template/`。
2. 重命名为新的 Demo 名称，例如 `Assets/Collection/Dissolve/`。
3. 将 Shader、材质、模型、预制体、场景和脚本放入对应子目录。
4. 补充 Demo README，说明问题、方案、效果、性能和后续迭代。
