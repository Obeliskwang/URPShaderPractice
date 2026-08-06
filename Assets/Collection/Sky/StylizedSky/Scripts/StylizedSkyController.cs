using System;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;

[ExecuteAlways]
[DisallowMultipleComponent]
public sealed class StylizedSkyController : MonoBehaviour
{
    [Header("Time")]
    [SerializeField, Range(0f, 24f)]
    private float timeOfDay = 12f;

    [SerializeField]
    private bool autoPlay;

    [SerializeField, Min(1f)]
    private float dayDurationSeconds = 120f;

    [SerializeField]
    private bool loop = true;

    [Header("Celestial Rotation")]
    [SerializeField]
    private Light directionalLight;

    [SerializeField, Range(-180f, 180f)]
    private float sunAzimuth;

    [Header("Directional Light")]
    [SerializeField]
    private Gradient directionalLightColor = CreateDirectionalLightColorGradient();

    [SerializeField]
    private AnimationCurve directionalLightIntensity = CreateDirectionalLightIntensityCurve();

    [SerializeField]
    private AnimationCurve directionalLightShadowStrength = CreateShadowStrengthCurve();

    [Header("Atmosphere")]
    [SerializeField]
    private bool synchronizeFogColor = true;

    [SerializeField]
    private Gradient fogColor = CreateFogColorGradient();

    [Header("Lens Flare")]
    [SerializeField]
    private LensFlareComponentSRP lensFlare;

    [SerializeField]
    private AnimationCurve lensFlareIntensity = CreateLensFlareIntensityCurve();

    [Header("Environment Lighting")]
    [SerializeField]
    private bool updateDynamicGI = true;

    [SerializeField, Min(0.1f)]
    private float environmentUpdateInterval = 1f;

    private double nextEnvironmentUpdateTime;

    // 对外提供时间接口
    public float TimeOfDay
    {
        get => timeOfDay;
        set
        {
            timeOfDay = Mathf.Clamp(value, 0f, 24f);
            Evaluate();
        }
    }

    // 启用时刷新一次界面
    private void OnEnable()
    {
        Evaluate();
    }

    // 1.在编辑器中修改属性时刷新界面 2.修改非法参数
    private void OnValidate()
    {
        dayDurationSeconds = Mathf.Max(1f, dayDurationSeconds);
        timeOfDay = Mathf.Clamp(timeOfDay, 0f, 24f);
        environmentUpdateInterval = Mathf.Max(0.1f, environmentUpdateInterval);
        Evaluate();
    }

    private void Update()
    {
        if (!Application.isPlaying || !autoPlay)
            return;
        
        // 计算每秒推进几小时
        float hoursPerSecond = 24f / dayDurationSeconds;
        float nextTime = timeOfDay + Time.deltaTime * hoursPerSecond;

        if (loop)
        {
            timeOfDay = Mathf.Repeat(nextTime, 24f);
        }
        else
        {
            timeOfDay = Mathf.Min(nextTime, 24f);

            if (timeOfDay >= 24f)
            {
                autoPlay = false;
            }   
        }

        Evaluate();

    }

    // 统一刷新入口
    private void Evaluate()
    {
        float normalizedTime = timeOfDay / 24f;

        ApplyCelestialRotation(normalizedTime);
        ApplyDirectionalLight(normalizedTime);
        ApplyFog(normalizedTime);
        ApplyLensFlare(normalizedTime);
        UpdateEnvironmentIfNeeded();
    }

   // 更新太阳旋转
    private void ApplyCelestialRotation(float normalizedTime)
    {
        if (directionalLight == null)
            return;

        float sunPitch = normalizedTime * 360f - 90f; // 从-90到270度

        directionalLight.transform.rotation = Quaternion.Euler(sunPitch, sunAzimuth, 0f);
    }

    private void ApplyDirectionalLight(float normalizedTime)
    {
        if (directionalLight == null)
            return;

        if (directionalLightColor != null)
            directionalLight.color = directionalLightColor.Evaluate(normalizedTime);

        if (directionalLightIntensity != null)
            directionalLight.intensity = Mathf.Max(0f, directionalLightIntensity.Evaluate(normalizedTime));

        if (directionalLightShadowStrength != null)
            directionalLight.shadowStrength = Mathf.Clamp01(
                directionalLightShadowStrength.Evaluate(normalizedTime));
    }

    private void ApplyFog(float normalizedTime)
    {
        if (!synchronizeFogColor || fogColor == null)
            return;

        RenderSettings.fogColor = fogColor.Evaluate(normalizedTime);
    }

    private void ApplyLensFlare(float normalizedTime)
    {
        if (lensFlare == null || lensFlareIntensity == null)
            return;

        lensFlare.intensity = Mathf.Max(0f, lensFlareIntensity.Evaluate(normalizedTime));
    }

    private void UpdateEnvironmentIfNeeded()
    {
        if (!updateDynamicGI)
            return;

        double currentTime = Time.realtimeSinceStartupAsDouble;
        if (currentTime < nextEnvironmentUpdateTime)
            return;

        DynamicGI.UpdateEnvironment();
        nextEnvironmentUpdateTime = currentTime + environmentUpdateInterval;
    }

    private static Gradient CreateDirectionalLightColorGradient()
    {
        Gradient gradient = new Gradient();
        gradient.SetKeys(
            new[]
            {
                new GradientColorKey(new Color(0.18f, 0.24f, 0.42f), 0f),
                new GradientColorKey(new Color(0.18f, 0.24f, 0.42f), 0.22f),
                new GradientColorKey(new Color(1f, 0.48f, 0.22f), 0.25f),
                new GradientColorKey(new Color(1f, 0.94f, 0.82f), 0.35f),
                new GradientColorKey(new Color(1f, 0.94f, 0.82f), 0.65f),
                new GradientColorKey(new Color(1f, 0.38f, 0.16f), 0.75f),
                new GradientColorKey(new Color(0.18f, 0.24f, 0.42f), 0.8f),
                new GradientColorKey(new Color(0.18f, 0.24f, 0.42f), 1f)
            },
            new[]
            {
                new GradientAlphaKey(1f, 0f),
                new GradientAlphaKey(1f, 1f)
            });
        return gradient;
    }

    private static Gradient CreateFogColorGradient()
    {
        Gradient gradient = new Gradient();
        gradient.SetKeys(
            new[]
            {
                new GradientColorKey(new Color(0.025f, 0.035f, 0.08f), 0f),
                new GradientColorKey(new Color(0.025f, 0.035f, 0.08f), 0.22f),
                new GradientColorKey(new Color(0.78f, 0.38f, 0.24f), 0.25f),
                new GradientColorKey(new Color(0.52f, 0.72f, 0.86f), 0.35f),
                new GradientColorKey(new Color(0.52f, 0.72f, 0.86f), 0.65f),
                new GradientColorKey(new Color(0.72f, 0.3f, 0.22f), 0.75f),
                new GradientColorKey(new Color(0.025f, 0.035f, 0.08f), 0.8f),
                new GradientColorKey(new Color(0.025f, 0.035f, 0.08f), 1f)
            },
            new[]
            {
                new GradientAlphaKey(1f, 0f),
                new GradientAlphaKey(1f, 1f)
            });
        return gradient;
    }

    private static AnimationCurve CreateDirectionalLightIntensityCurve()
    {
        return new AnimationCurve(
            new Keyframe(0f, 0.02f),
            new Keyframe(0.22f, 0.02f),
            new Keyframe(0.25f, 0.45f),
            new Keyframe(0.35f, 1f),
            new Keyframe(0.65f, 1f),
            new Keyframe(0.75f, 0.45f),
            new Keyframe(0.8f, 0.02f),
            new Keyframe(1f, 0.02f));
    }

    private static AnimationCurve CreateShadowStrengthCurve()
    {
        return new AnimationCurve(
            new Keyframe(0f, 0f),
            new Keyframe(0.22f, 0f),
            new Keyframe(0.25f, 0.35f),
            new Keyframe(0.35f, 1f),
            new Keyframe(0.65f, 1f),
            new Keyframe(0.75f, 0.35f),
            new Keyframe(0.8f, 0f),
            new Keyframe(1f, 0f));
    }

    private static AnimationCurve CreateLensFlareIntensityCurve()
    {
        return new AnimationCurve(
            new Keyframe(0f, 0f),
            new Keyframe(0.22f, 0f),
            new Keyframe(0.25f, 1f),
            new Keyframe(0.35f, 0.4f),
            new Keyframe(0.65f, 0.4f),
            new Keyframe(0.75f, 1f),
            new Keyframe(0.8f, 0f),
            new Keyframe(1f, 0f));
    }
}

