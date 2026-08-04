#ifndef GRASS_TESSELLATION_INCLUDED
#define GRASS_TESSELLATION_INCLUDED

struct TessellationFactors
{
    float edge[3] : SV_TessFactor;        // 三角形三条边的细分等级
    float inside  : SV_InsideTessFactor;  // 三角形内部的细分等级
};

// Patch Constant Function：为每个输入三角形决定曲面细分密度
TessellationFactors PatchConstantFunction(InputPatch<Attributes, 3> patch)
{
    TessellationFactors f;

    // 统一细分：三条边和内部都使用同一个材质参数
    f.edge[0] = _TessellationUniform;
    f.edge[1] = _TessellationUniform;
    f.edge[2] = _TessellationUniform;
    f.inside = _TessellationUniform;

    return f;
}

// Hull Shader：控制三角形 Patch 的输出控制点数量和细分方式
[domain("tri")]
[partitioning("integer")]              // 使用整数细分，便于学习和观察
[outputtopology("triangle_cw")]        // 输出顺时针三角形
[patchconstantfunc("PatchConstantFunction")]
[outputcontrolpoints(3)]
Attributes hull(InputPatch<Attributes, 3> patch, uint id : SV_OutputControlPointID)
{
    // 这里只原样传递 3 个控制点，不在 Hull 阶段改变网格形状
    return patch[id];
}

// Domain Shader：根据重心坐标，在细分后的三角形内部插值出新的顶点
[domain("tri")]
GeomVaryings domain(
    TessellationFactors factors,
    const OutputPatch<Attributes, 3> patch,
    float3 barycentricCoordinates : SV_DomainLocation)
{
    GeomVaryings o;

    // 使用重心坐标插值任意字段：x/y/z 分别对应原始三角形三个顶点的权重
    #define INTERPOLATE(fieldName) \
        patch[0].fieldName * barycentricCoordinates.x + \
        patch[1].fieldName * barycentricCoordinates.y + \
        patch[2].fieldName * barycentricCoordinates.z

    // 插值得到新的模型空间位置、法线和切线，随后交给几何着色器生成草叶
    o.positionOS = INTERPOLATE(positionOS);
    o.normalOS = normalize(INTERPOLATE(normalOS));
    o.tangentOS = normalize(INTERPOLATE(tangentOS));

    return o;
}

#endif
