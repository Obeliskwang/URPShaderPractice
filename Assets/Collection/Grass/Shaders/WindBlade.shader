Shader "URPShaderPractice/Grass/WindBlade"
{
    Properties
    {
        [Header(Grass Color)]
        _BaseColor ("Base Color", Color) = (0.1, 0.4, 0.05, 1.0) // 草根部颜色
        _TopColor("Top Color", Color) = (0.5, 0.8, 0.2, 1)       // 草尖部颜色

        [Header(Grass Size)]
        _GrassWidth("Grass Width", Float) = 0.05                 // 草叶基础宽度
        _GrassHeight("Grass Height", Float) = 0.2                // 草叶基础高度
        _GrassWidthRandom("Grass Width Random", Float) = 0.3     // 草叶宽度随机变化范围
        _GrassHeightRandom("Grass Height Random", Float) = 0.3   // 草叶高度随机变化范围

        [Header(Grass Deformation)]
        _RandomRotation ("Random Rotation (0-1)", Range(0, 1)) = 1.0       // 绕草根法线方向的随机朝向
        _Curvature ("Curvature Amount", Range(0, 1)) = 0.3                // 旧版单三角草尖弯曲参数，保留作兼容
        _BendRotationRandom("Bend Rotation Random", Range(0, 1)) = 0.2     // 每片草随机倾倒/风弯幅度
        _GrassForward("Grass Forward Amount", Float) = 0.38               // 草叶向前弯曲的最大距离
        _GrassCurve("Grass Curvature Amount", Range(1, 4)) = 2            // 草叶弯曲曲线，数值越大越接近草尖才弯

        [Header(Tessellation)]
        _TessellationUniform("Tessellation Uniform", Range(1, 64)) = 1     // 曲面细分密度，越大生成草根点越多

        [Header(Wind)]
        _WindDistortionMap("Wind Distortion Map", 2D) = "gray" {}         // 风场扰动贴图，RG 控制风向
        _WindFrequency("Wind Frequency", Vector) = (0.05, 0.05, 0, 0)     // 风场随时间滚动速度
    }

    SubShader
    {
        Tags
        {
            "RenderType" = "Opaque"
            "RenderPipeline" = "UniversalPipeline"
            "Queue" = "Geometry"
        }
        LOD 300

        Pass
        {
            Name "ForwardLit"
            Tags { "LightMode" = "UniversalForwardOnly" } // URP 主渲染 Pass：负责把草画到摄像机画面里

            Cull Off // 双面渲染，草片正反面都可见
            ZWrite On
            ZTest LEqual
            

            HLSLPROGRAM
            #pragma target 4.6
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma geometry geo
            #pragma fragment frag

            // 编译 URP 主光阴影相关变体，让草可以接收方向光阴影
            #pragma multi_compile _ _MAIN_LIGHT_SHADOWS _MAIN_LIGHT_SHADOWS_CASCADE _MAIN_LIGHT_SHADOWS_SCREEN
            #pragma multi_compile_fragment _ _SHADOWS_SOFT

            // 公共草生成逻辑：顶点/曲面细分/几何着色器/阴影坐标都在这里
            #include "Assets/Collection/Grass/Shaders/GrassCommon.hlsl"

            // 片元着色器：使用主方向光阴影 + 环境光，给草做一个轻量级光照
            half4 frag(Varyings input, bool isFrontFace : SV_IsFrontFace) : SV_Target
            {
                Light mainLight = GetMainLight(input.shadowCoord);

                float3 normalWS = isFrontFace ? input.normalWS : -input.normalWS;
                float3 lightDirWS = normalize(mainLight.direction);
                
               half frontLight = saturate(dot(normalWS, lightDirWS));
                half backLight = saturate(dot(-normalWS, lightDirWS)) * 0.35;

                half NdotL = max(frontLight, backLight);
                NdotL = max(NdotL, 0.35);

                half shadow = lerp(0.85, 1.0, mainLight.shadowAttenuation);

                //half lightAmount = saturate(mainLight.direction.y * 0.5 + 0.5);
                //lightAmount = lerp(0.5, 1.0, lightAmount);

                half3 color = input.color.rgb * shadow * NdotL;

                return half4(color, input.color.a);
            }

            // 测试法线传递
            //half4 frag(Varyings input, bool isFrontFace : SV_IsFrontFace) : SV_Target
            //{
            //    float3 normalWS = isFrontFace ? input.normalWS : -input.normalWS;

            //    return half4(normalWS * 0.5 + 0.5, 1.0);
            //}
            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" } // 阴影投射 Pass：从灯光视角把草写入 shadow map

            Cull Off // 阴影也双面写入，避免草片背面不投影
            ZWrite On
            ZTest LEqual
            ColorMask 0 // 阴影贴图只需要深度，不需要颜色

            HLSLPROGRAM
            #pragma target 4.6
            #pragma vertex vert
            #pragma hull hull
            #pragma domain domain
            #pragma geometry geo
            #pragma fragment frag

            // 编译点光/聚光阴影投射变体；方向光阴影走默认分支
            #pragma multi_compile_vertex _ _CASTING_PUNCTUAL_LIGHT_SHADOW

            // 告诉 GrassCommon 当前正在编译 ShadowCaster Pass，启用阴影偏移逻辑
            #define GRASS_SHADOW_CASTER_PASS 1
            #include "Assets/Collection/Grass/Shaders/GrassCommon.hlsl"

            // ShadowCaster Pass 只写深度，颜色输出无意义
            half4 frag(Varyings input) : SV_Target
            {
                return 0;
            }
            ENDHLSL
        }
    }

    FallBack "Hidden/Shader Graph/FallbackError"
}
