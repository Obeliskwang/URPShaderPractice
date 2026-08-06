# Stylized Sky

## 问题

在 URP 中提供一个可实时预览的程序化风格化天空盒，覆盖昼夜循环、日/月、星空、云层、主方向光和雾色同步。

- 目标效果：0–24 小时连续昼夜过渡，以及太阳、月亮、星星和三层噪声云。
- 使用场景：`Scenes/StylizedSkyDemo.unity`。
- 环境：Unity `2022.3.62f2c1`，URP `14.0.12`。

## 方案

- `Shaders/Skybox.shader`：URP Skybox pass；使用 `GetMainLight()` 获取主方向光方向，绘制日/月、渐变、地平线辉光、星空和云层遮罩。
- `Materials/Skybox.mat`：天空盒材质，关联所有纹理。
- `Scripts/StylizedSkyController.cs`：在 Inspector 中拖动 `Time Of Day`（0–24）即可预览；可自动播放，并同步 Directional Light、SRP Lens Flare、雾色与动态 GI。
- `LensFlares/DirectionalLight.asset`：SRP Lens Flare Data；需在场景主方向光的 `LensFlareComponentSRP` 中手动指定。

重要参数：`Sun Radius`、`Moon Radius`、`Moon Crescent Offset`、`Twilight Night/Day Level`、云层 Scale/Speed/Cutoff/Fuzziness 与日夜云颜色。

## 效果

- 顶部/底部独立的昼夜四向渐变；日出与日落地平线暖色。
- 太阳跟随主方向光，月亮位于其反方向；`Moon Crescent Offset` 控制月牙。
- 星空在夜晚淡入，云层最终合成，因此会遮挡太阳、月亮和星星。

独立场景仅含 Main Camera、Directional Light 与 Sky Controller，不依赖第三方环境资源。

## 性能

- 单个 Background Pass；无 Shader Variant/Keyword。
- 每像素采样 4 张纹理：星图 1 张、云噪声 3 张；云遮罩与天体在同一 Pass 合成。
- 移动端建议降低天空渲染分辨率、减少 `DynamicGI.UpdateEnvironment` 调用频率，或关闭动态 GI。
- 建议使用 Unity Profiler、Frame Debugger 和 RenderDoc 在目标平台确认开销。

## 迭代日志

#### 2026-08-06

- 新增问题：原资产命名、Shader 注册路径和 Lens Flare 位置不符合仓库规范 -> 解决方案：重命名为规范目录资产，Shader 注册为 `URPShaderPractice/Sky/StylizedSky/Skybox`，并将 Lens Flare Data 归档到 `LensFlares/`。
- 新增问题：展示场景依赖源项目的环境资产 -> 解决方案：重建仅含相机、方向光和天空控制器的独立演示场景，不迁移第三方资源。

