#ifndef GRASS_COMMON_INCLUDED
#define GRASS_COMMON_INCLUDED

#define BLADE_SEGMENTS 3

// URP 基础变换函数 + 主光/阴影/环境光函数
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
#include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"

// 输入网格原始顶点：由 Unity Mesh 提供，后续会进入曲面细分阶段
struct Attributes
{
    float4 positionOS   : POSITION;
    float3 normalOS     : NORMAL;
    float4 tangentOS    : TANGENT; // w 分量存储切线空间手性，用于计算副切线方向
};

// 曲面细分输出到几何着色器的数据
struct GeomVaryings
{
    float4 positionOS   : TEXCOORD0;
    float3 normalOS     : TEXCOORD1;
    float4 tangentOS    : TEXCOORD2;
};

// 几何着色器输出到片元着色器的数据
struct Varyings
{
    float4 positionCS   : SV_POSITION;
    half4 color         : TEXCOORD0; // 草根到草尖插值得到的颜色
    float4 shadowCoord  : TEXCOORD1; // 主光阴影贴图采样坐标，用于接收阴影
    float3 normalWS     : TEXCOORD2;
};

// 材质参数放入 UnityPerMaterial，保持 SRP Batcher 兼容
CBUFFER_START(UnityPerMaterial)
half4 _BaseColor;
half4 _TopColor;

float _GrassWidth;
float _GrassHeight;
float _GrassWidthRandom;
float _GrassHeightRandom;

float _RandomRotation;
float _Curvature;
float _BendRotationRandom;
float _GrassForward;
float _GrassCurve;

float _TessellationUniform;

float4 _WindDistortionMap_ST;
float2 _WindFrequency;
CBUFFER_END

// 风场贴图：在几何着色器里采样，用于旋转/扰动草叶
TEXTURE2D(_WindDistortionMap);
SAMPLER(sampler_WindDistortionMap);

#if defined(GRASS_SHADOW_CASTER_PASS)
// URP ShadowCaster Pass 注入的灯光方向/位置，用于 ApplyShadowBias
float3 _LightDirection;
float3 _LightPosition;
#endif

// 曲面细分：把原始三角形细分出更多生成草的采样点
#include "Assets/Collection/Grass/Shaders/GrassTessellation.hlsl"

// 伪随机数发生器：输入一个二维坐标，输出 0~1 的稳定随机数
float Hash21(float2 co)
{
    return frac(sin(dot(co, float2(12.9898, 78.233))) * 43758.5453);
}

// 任意轴旋转矩阵：用于随机朝向、随机弯折、风向扰动
float3x3 AngleAxis3x3(float angle, float3 axis)
{
    float c, s;
    sincos(angle, s, c);

    float t = 1.0 - c;
    float x = axis.x;
    float y = axis.y;
    float z = axis.z;

    return float3x3(
        t * x * x + c,     t * x * y - s * z, t * x * z + s * y,
        t * x * y + s * z, t * y * y + c,     t * y * z - s * x,
        t * x * z - s * y, t * y * z + s * x, t * z * z + c
    );
}

#if defined(GRASS_SHADOW_CASTER_PASS)
// ShadowCaster Pass 中根据光源类型选择阴影投射方向
float3 GetGrassShadowLightDirection(float3 positionWS)
{
    #if defined(_CASTING_PUNCTUAL_LIGHT_SHADOW)
        return normalize(_LightPosition - positionWS);
    #else
        return _LightDirection;
    #endif
}
#endif

// 构造单个草叶顶点：
// rootPosOS 是草根位置；offsetTS 是草叶局部切线空间偏移；tbn 负责 TS -> OS；color 是该高度颜色
Varyings GenerateGrassVertex(float3 rootPosOS, float3 offsetTS, float3x3 tbn, half4 color)
{
    Varyings o = (Varyings)0;

    // 将切线空间 (TS) 的草叶偏移点转换到模型空间 (OS)，再转换到世界空间 (WS)
    float3 positionOS = rootPosOS + mul(tbn, offsetTS);
    float3 positionWS = TransformObjectToWorld(positionOS);

    float3 tangentNormal = normalize(float3(0.0, -1.0, offsetTS.y));
    float3 normalOS = normalize(mul(tbn, tangentNormal));
    float3 normalWS = TransformObjectToWorldDir(normalOS);

    o.normalWS = normalWS;

    #if defined(GRASS_SHADOW_CASTER_PASS)
        // 草片大致位于 TS 的 XZ 平面，所以 TS 的 Y 方向可以近似当作草片法线
        //float3 normalOS = normalize(mul(tbn, float3(0.0, 1.0, 0.0)));
        //float3 normalWS = TransformObjectToWorldDir(normalOS);
        float3 lightDirectionWS = GetGrassShadowLightDirection(positionWS);

        // 给阴影深度加 bias，减少草片自己投到自己身上的条纹伪影
        positionWS = ApplyShadowBias(positionWS, normalWS, lightDirectionWS);
        o.positionCS = TransformWorldToHClip(positionWS);

        // 保证裁剪空间深度不会越过近裁剪面
        #if UNITY_REVERSED_Z
            o.positionCS.z = min(o.positionCS.z, UNITY_NEAR_CLIP_VALUE);
        #else
            o.positionCS.z = max(o.positionCS.z, UNITY_NEAR_CLIP_VALUE);
        #endif
    #else
        // 普通渲染 Pass：输出裁剪空间位置，并额外计算接收阴影所需的 shadowCoord
        o.positionCS = TransformObjectToHClip(positionOS);
        o.shadowCoord = TransformWorldToShadowCoord(positionWS);
    #endif

    o.color = color;
    return o;
}

// 顶点着色器：这里不做变形，只把原始网格数据传给曲面细分阶段
Attributes vert(Attributes input)
{
    return input;
}

// 几何着色器最多输出：每段两个顶点 + 最后一个草尖顶点
[maxvertexcount(BLADE_SEGMENTS * 2 + 1)]
void geo(triangle GeomVaryings input[3], inout TriangleStream<Varyings> triStream)
{
    // 1. 计算三角形面的中心作为草根位置，并平均法线/切线作为草叶生长方向依据
    float3 rootPosOS = (input[0].positionOS.xyz + input[1].positionOS.xyz + input[2].positionOS.xyz) * 0.33333333;
    float3 normalOS = normalize(input[0].normalOS + input[1].normalOS + input[2].normalOS);
    float4 tangentOS = normalize(input[0].tangentOS + input[1].tangentOS + input[2].tangentOS);

    // 2. 只在朝上的表面长草，避免墙面/背面也生成草
    float3 normalWS = TransformObjectToWorldNormal(normalOS);
    if (normalWS.y < 0.5)
    {
        return;
    }

    // 3. 构建 TBN 矩阵：把草叶局部切线空间转换到模型空间
    float3 bitangentOS = cross(normalOS, tangentOS.xyz) * tangentOS.w;
    float3x3 tbnOS = float3x3(
        tangentOS.x, bitangentOS.x, normalOS.x,
        tangentOS.y, bitangentOS.y, normalOS.y,
        tangentOS.z, bitangentOS.z, normalOS.z
    );

    // 4. 绕草根法线随机旋转，让每片草朝向不同
    float randomVal = Hash21(rootPosOS.xz);
    float randomAngle = randomVal * TWO_PI * _RandomRotation;
    float3x3 rotMatrix = AngleAxis3x3(randomAngle, float3(0.0, 0.0, 1.0));

    // 5. 给每片草一个随机倾倒角度，避免所有草都笔直站立
    float bendRandomVal = Hash21(rootPosOS.zx);
    float bendAngle = bendRandomVal * _BendRotationRandom * PI * 0.5;
    float3x3 bendRotationMatrix = AngleAxis3x3(bendAngle, float3(-1.0, 0.0, 0.0));

    // 6. 根据世界坐标采样风贴图，并随时间滚动风场
    float3 rootPosWS = TransformObjectToWorld(rootPosOS);
    float2 windUV =
        rootPosWS.xz * _WindDistortionMap_ST.xy +
        _WindDistortionMap_ST.zw +
        _WindFrequency.xy * _Time.y;

    // 风贴图 RG 从 0~1 还原到 -1~1，作为风向和强度
    float2 windSample = SAMPLE_TEXTURE2D_LOD(_WindDistortionMap, sampler_WindDistortionMap, windUV, 0).rg * 2.0 - 1.0;
    float windAmount = saturate(length(windSample));
    float3 windAxisTS = normalize(float3(windSample.x, windSample.y, 0.0001));
    float windAngle = windAmount * _BendRotationRandom * PI * 0.5;
    float3x3 windRotationMatrix = AngleAxis3x3(windAngle, windAxisTS);

    // 完整变换矩阵：TBN -> 风扰动 -> 随机朝向 -> 随机弯折
    float3x3 transformationMatrix = mul(mul(mul(tbnOS, windRotationMatrix), rotMatrix), bendRotationMatrix);

    // 草根两个底部顶点只使用朝向矩阵，保证根部牢牢贴住表面
    float3x3 transformationMatrixFacing = mul(tbnOS, rotMatrix);

    // 7. 计算每片草的随机高度、宽度和前向弯曲幅度
    float height = (Hash21(rootPosOS.zy) * 2.0 - 1.0) * _GrassHeightRandom + _GrassHeight;
    float width = (Hash21(rootPosOS.xz) * 2.0 - 1.0) * _GrassWidthRandom + _GrassWidth;
    float halfWidth = width * 0.5;
    float forward = lerp(0.3, 1.0, Hash21(rootPosOS.yz)) * _GrassForward;

    // 8. 分段生成草叶主体：每一段输出左右两个顶点，TriangleStream 自动连接成三角条带
    for (int i = 0; i < BLADE_SEGMENTS; i++)
    {
        // t 表示当前段在整片草叶上的高度比例：0 是根部，越接近 1 越靠近草尖
        float t = i / (float)BLADE_SEGMENTS;

        // 越往上越高、越窄，并按 pow 曲线逐渐向前弯曲
        float segmentHeight = height * t;
        float segmentHalfWidth = halfWidth * (1.0 - t);
        float segmentForward = pow(t, _GrassCurve) * forward;
        float3x3 segmentTransform = i == 0 ? transformationMatrixFacing : transformationMatrix;
        half4 segmentColor = lerp(_BaseColor, _TopColor, t);

        // 当前段左侧顶点
        triStream.Append(GenerateGrassVertex(
            rootPosOS,
            float3(-segmentHalfWidth, segmentForward, segmentHeight),
            segmentTransform,
            segmentColor
        ));

        // 当前段右侧顶点
        triStream.Append(GenerateGrassVertex(
            rootPosOS,
            float3(segmentHalfWidth, segmentForward, segmentHeight),
            segmentTransform,
            segmentColor
        ));
    }

    // 9. 循环只生成到靠近草尖的最后一层，真正的草尖需要单独补一个中心顶点
    triStream.Append(GenerateGrassVertex(
        rootPosOS,
        float3(0.0, forward, height),
        transformationMatrix,
        _TopColor
    ));

    // 当前草叶结束，防止下一片草与这一片继续连成同一个三角条带
    triStream.RestartStrip();
}

#endif
