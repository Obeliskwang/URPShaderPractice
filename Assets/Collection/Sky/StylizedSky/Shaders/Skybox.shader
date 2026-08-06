Shader "URPShaderPractice/Sky/StylizedSky/Skybox"
{
    Properties
    {
        [HDR] _SkyColor("Sky Color", Color) = (0.18, 0.45, 0.85, 1)
        
        [Header(Sun Settings)]
        [HDR] _SunColor("Sun Color", Color) = (1.0, 0.75, 0.3, 1)
        _SunRadius("Sun Radius", Range(0.001, 0.2)) = 0.04
        _HaloRadius("Halo Radius", Range(0.001, 0.2)) = 0.08
        
        [Header(Moon Settings)]
        [HDR] _MoonColor("Moon Color", Color) = (0.7, 0.8, 1.0, 1)
        _MoonRadius("Moon Radius", Range(0.001, 0.2)) = 0.04
        _MoonSoftness("Moon Softness", Range(0.0001, 0.02)) = 0.002

        _MoonOffset("Moon Crescent Offset", Range(-0.1, 0.1)) = 0.02
    
        [Header(Sky Gradient)]
        [HDR] _DayTopColor("Day Top Color", Color) = (0.15, 0.45, 1.0, 1)
        [HDR] _DayBottomColor("Day Bottom Color", Color) = (0.65, 0.85, 1.0, 1)
        [HDR] _NightTopColor("Night Top Color", Color) = (0.01, 0.02, 0.08, 1)
        [HDR] _NightBottomColor("Night Bottom Color", Color) = (0.08, 0.10, 0.20, 1)
        
        _HorizonWidth("Horizon Width", Range(0.001, 0.5)) = 0.1
        [HDR] _HorizonColorDay("Horizon Color Day", Color) = (1.0, 0.45, 0.15, 1.0)
        _HorizonSunRange("Horizon Sun Range",Range(0.001, 0.5)) = 0.15
        _HorizonSunFocus( "Horizon Sun Focus", Range(1.0, 32.0)) = 4.0

        [Header(Day Night Transition)]
        _TwilightNightLevel("Twilight Night Level", Range(-0.3, 0.0)) = -0.08
        _TwilightDayLevel("Twilight Day Level", Range(0.0, 0.3)) = 0.12
        
        [Header(Star Settings)]
        _Stars("Stars", 2D) = "black" {}

        [Header(Cloud Settings)]
        _BaseNoise("Cloud Base Noise", 2D) = "white" {}
        _SecNoise("Cloud Secondary Noise", 2D) = "white" {}
        _Distort("Cloud Distortion Noise", 2D) = "white" {}

        _CloudScale("Cloud Scale", Range(0.05, 4.0)) = 0.5
        _CloudSpeed("Cloud Speed XY", Vector) = (0.01, 0.02, 0.0, 0.0)
        _CloudDistortion("Cloud Distortion", Range(0.0, 2.0)) = 0.5
        _CloudCutoff("Cloud Cutoff", Range(0.0, 1.0)) = 0.25
        _CloudFuzziness("Cloud Fuzziness", Range(0.001, 1.0)) = 0.15
        _CloudDetailScale("Cloud Detail Scale", Range(0.25, 4.0)) = 1.2
        _CloudDetailStrength("Cloud Detail Erosion", Range(0.0, 1.0)) = 0.35
        
        [HDR] _CloudColorDayEdge("Cloud Day Edge", Color) = (0.65, 0.72, 0.80, 1)
        [HDR] _CloudColorDayMain("Cloud Day Main", Color) = (1.0, 1.0, 1.0, 1)
        [HDR] _CloudColorNightEdge("Cloud Night Edge", Color) = (0.04, 0.05, 0.10, 1)
        [HDR] _CloudColorNightMain("Cloud Night Main", Color) = (0.15, 0.18, 0.30, 1)
   
   
   }

    SubShader
    {
        Tags
        {
            "Queue" = "Background"
            "RenderType" = "Background"
            "RenderPipeline" = "UniversalPipeline"
            "PreviewType" = "Skybox"
        }

        Pass
        {
            Name "Skybox"

            Cull Off
            ZWrite Off

            HLSLPROGRAM
            #pragma target 2.0
            #pragma vertex Vert
            #pragma fragment Frag

            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Lighting.hlsl"
            
            TEXTURE2D(_Stars);
            SAMPLER(sampler_Stars);

            TEXTURE2D(_BaseNoise);
            TEXTURE2D(_Distort);
            TEXTURE2D(_SecNoise);

            // 三张纹理使用相同�?Repeat/Bilinear 采样状态，节省 sampler�?
            // 基础版先使用各纹理的同名 sampler，确�?Unity D3D11 稳定识别绑定�?
            SAMPLER(sampler_BaseNoise);
            SAMPLER(sampler_Distort);
            SAMPLER(sampler_SecNoise);

            CBUFFER_START(UnityPerMaterial)
                half4 _SkyColor;
                half4 _SunColor;
                float _SunRadius;
                float _HaloRadius;

                half4 _MoonColor;
                float _MoonRadius;
                float _MoonSoftness;
                float _MoonOffset;

                half4 _DayTopColor;
                half4 _DayBottomColor;  
                half4 _NightTopColor;
                half4 _NightBottomColor;
                float _HorizonWidth;
                half4 _HorizonColorDay;
                float _HorizonSunRange;
                float _HorizonSunFocus;

                float _TwilightNightLevel;
                float _TwilightDayLevel;

                float4 _Stars_ST;

                float _CloudScale;
                float4 _CloudSpeed;
                float _CloudDistortion;
                float _CloudCutoff;
                float _CloudFuzziness;
                float _CloudDetailScale;
                float _CloudDetailStrength;

                half4 _CloudColorDayEdge;
                half4 _CloudColorDayMain;
                half4 _CloudColorNightEdge;
                half4 _CloudColorNightMain;
            CBUFFER_END

            struct Attributes
            {
                float3 positionOS : POSITION;
            };

            struct Varyings
            {
                float4 positionCS : SV_POSITION;
                float3 viewDirectionWS : TEXCOORD0;
            };

            Varyings Vert(Attributes input)
            {
                Varyings output;

                output.positionCS = TransformObjectToHClip(input.positionOS);

                // Always place the skybox at the far clipping plane.
                output.positionCS.z = UNITY_RAW_FAR_CLIP_VALUE * output.positionCS.w;

                // A skybox cube's local vertex position represents a viewing direction.
                output.viewDirectionWS = TransformObjectToWorldDir(input.positionOS);
                return output;
            }

            half4 Frag(Varyings input) : SV_Target
            {
                float3 viewDirectionWS = normalize(input.viewDirectionWS);
                float verticalGradient = saturate(viewDirectionWS.y);
                
                // Keep the star projection finite at the horizon. Sampling with Inf/NaN
                // coordinates is undefined and can intermittently produce black pixels.
                float safeStarProjectionY = max(abs(viewDirectionWS.y), 0.05);
                safeStarProjectionY *= viewDirectionWS.y < 0.0 ? -1.0 : 1.0;
                float2 skyUV = viewDirectionWS.xz / safeStarProjectionY;
                float2 starUV = skyUV * _Stars_ST.xy + _Stars_ST.zw;
                
                // 避免投影 UV 在地平线 y=0 附近变成无穷大�?
                float safeSkyY = max(viewDirectionWS.y, 0.05);
                float2 cloudUV = viewDirectionWS.xz / safeSkyY;
                
                float2 scrollOffset = _Time.y * _CloudSpeed.xy;

                // 采样纹理颜色
                // 星星纹理采样
                half3 stars = SAMPLE_TEXTURE2D(_Stars, sampler_Stars, starUV).rgb;
                
                // 云纹理采�?
                // distort只产�?UV 偏移，不直接成为云遮罩�?
                float2 distortUV = (cloudUV - scrollOffset * 0.35) * (_CloudScale * 0.55);
                half distortNoise = SAMPLE_TEXTURE2D(_Distort, sampler_Distort, distortUV).r;

                // 0..1 转换�?-1..1，避�?UV 只朝正方向偏移�?
                half signedDistortion = distortNoise * 2.0h - 1.0h;

                float2 distortionDirection = normalize(float2(1.0, 0.63));
                float2 distortionOffset = distortionDirection * signedDistortion * _CloudDistortion;

                // 基础贴图和细节贴图（负责侵蚀主体�?
                half baseNoise = SAMPLE_TEXTURE2D(_BaseNoise, sampler_BaseNoise, (cloudUV - scrollOffset) * _CloudScale + distortionOffset).r;
                float2 secondaryUV = (cloudUV - scrollOffset * 0.83) * (_CloudScale * _CloudDetailScale) - distortionOffset * 0.65;
                half secondaryNoise = SAMPLE_TEXTURE2D(_SecNoise, sampler_SecNoise, secondaryUV).r;
                half cloudDensity = saturate(baseNoise - (1.0h - secondaryNoise) * _CloudDetailStrength);
                
                
                
                // 控制范围
                // 地平线范�?
                float horizon = abs(viewDirectionWS.y);

                // 云范围，只出现在天空上半部分
                half cloudHemisphereMask = saturate(viewDirectionWS.y);
    
                // 偏移月亮视线方向
                float3 shiftedViewDirectionWS =
                    float3(
                        viewDirectionWS.x + _MoonOffset,
                        viewDirectionWS.y,
                        viewDirectionWS.z
                    );

                // URP equivalent of reading the primary directional light direction.
                Light mainLight = GetMainLight();
                float3 sunDirectionWS = normalize(mainLight.direction); // 确定太阳方向
                float3 moonDirectionWS = -sunDirectionWS;

                float sunHeight = abs(sunDirectionWS.y); // 获取太阳高度
                float sunViewDot =  dot(viewDirectionWS, sunDirectionWS);
                half sunDirectionAlignment = saturate(sunViewDot);
                
                
                float safeTwilightDayLevel = max(_TwilightDayLevel, _TwilightNightLevel + 0.001);
                half dayFactor = smoothstep(_TwilightNightLevel, safeTwilightDayLevel, sunDirectionWS.y);
                
                half starVisibility = 1.0h - dayFactor;

                
                // 像素与日、月欧式距离
                float sunDistance = distance(viewDirectionWS, sunDirectionWS); // 太阳方向与像素方向的距离
                float moonDistance = distance(viewDirectionWS, moonDirectionWS);
                float crescentDistance = distance(shiftedViewDirectionWS, moonDirectionWS);
               float safeHaloRadius = max(_HaloRadius, _SunRadius + 1e-4);
                
               
                // 遮罩设置
                half sunMask = 1.0h - smoothstep(_SunRadius, safeHaloRadius, sunDistance);
                half fullMoonMask =
                    1.0h - smoothstep(
                        _MoonRadius,
                        _MoonRadius + _MoonSoftness,
                        moonDistance
                    );

                half cutoutMoonMask =
                    1.0h - smoothstep(
                        _MoonRadius,
                        _MoonRadius + _MoonSoftness,
                        crescentDistance
                    );

                half crescentMoonMask = saturate(fullMoonMask - cutoutMoonMask);
                
                 float horizonMask =1.0 - smoothstep(0.0,_HorizonWidth, horizon );
                    
                    // 时间遮罩
                half sunNearHorizon =
                    1.0h - smoothstep(
                        0.0,
                        _HorizonSunRange,
                        sunHeight
                    );

                half sunDirectionMask = pow( sunDirectionAlignment,   _HorizonSunFocus  );
                half horizonGlowMask =  horizonMask * sunNearHorizon * sunDirectionMask;
           
                 // 云遮�?
                half clouds = smoothstep(_CloudCutoff, _CloudCutoff + max(_CloudFuzziness, 0.001h), cloudDensity);
                clouds *= smoothstep(0.0h, 0.12h, viewDirectionWS.y);
                
                // 颜色渐变
                // 昼渐�?
                half3 gradientDay = lerp(
                    _DayBottomColor.rgb,
                    _DayTopColor.rgb,
                    verticalGradient
                );
                
                // 夜渐�?
                half3 gradientNight = lerp(
                    _NightBottomColor.rgb,
                    _NightTopColor.rgb,
                    verticalGradient
                );

                // 昼夜过渡
                half3 skyGradient = lerp(
                    gradientNight,
                    gradientDay,
                    dayFactor
                );

                // 天空底色与地平线颜色过渡
                half3 horizonGradient = lerp(
                    skyGradient,
                    _HorizonColorDay.rgb,
                    horizonGlowMask
                );

                // 昼夜云颜�?
                half3 cloudsColoredDay = lerp(
                    _CloudColorDayEdge.rgb,
                    _CloudColorDayMain.rgb,
                    clouds
                ) * clouds;

                half3 cloudsColoredNight = lerp(
                    _CloudColorNightEdge.rgb,
                    _CloudColorNightMain.rgb,
                    clouds
                ) * clouds;

                half3 cloudsColored = lerp(
                    cloudsColoredNight,
                    cloudsColoredDay,
                    dayFactor
                );
                // 显式展开 lerp，避免不同平台对 half3/half 重载匹配产生歧义�?
                // 1. 天空底色
               half3 color = horizonGradient;
               color += stars * starVisibility;
               
                color = color * (1.0h - sunMask) + _SunColor.rgb * sunMask;
                
                color = color * (1.0h - crescentMoonMask) + _MoonColor.rgb * crescentMoonMask;
                
                half cloudsNegative = 1.0h - clouds;

                // 云覆盖下面已经合成好的天空、星星、太阳和月亮�?
                color = color * cloudsNegative + cloudsColored;

                // 测试月相变化
                //color = color * (1.0h - cutoutMoonMask) + half3(1.0h, 0.0h, 0.0h) * cutoutMoonMask;
                
                
                return half4(color, 1.0h);
            }
            ENDHLSL
        }
    }

    Fallback Off
}

