#ifndef DDGI_CLOSEST_HIT_HLSL
#define DDGI_CLOSEST_HIT_HLSL

#include "DDGIGBuffer.hlsl"

struct VertexAttributes
{
    float3 position;
    float3 normal;
    float2 uv;
    float4 tangent;
};

struct MaterialProperties
{
    float4 baseColor;
    float3 emission;
    float metallic;
    float roughness;
    float ao;
};

float3 GetBarycentrics(float2 attribBarycentrics)
{
    return float3(
        1.0 - attribBarycentrics.x - attribBarycentrics.y,
        attribBarycentrics.x,
        attribBarycentrics.y
    );
}

float3 InterpolateFloat3(float3 v0, float3 v1, float3 v2, float3 barycentrics)
{
    return v0 * barycentrics.x + v1 * barycentrics.y + v2 * barycentrics.z;
}

float2 InterpolateFloat2(float2 v0, float2 v1, float2 v2, float3 barycentrics)
{
    return v0 * barycentrics.x + v1 * barycentrics.y + v2 * barycentrics.z;
}

[shader("closesthit")]
void DDGIClosestHitShader(inout DDGIRayPayload payload : SV_RayPayload,
                          BuiltInTriangleIntersectionAttributes attribs : SV_IntersectionAttributes)
{

    float3 barycentrics = GetBarycentrics(attribs.barycentrics);

    float3 worldPos = WorldRayOrigin() + WorldRayDirection() * RayTCurrent();

    float hitDistance = RayTCurrent();

    uint instanceID = InstanceID();
    uint primitiveIndex = PrimitiveIndex();

    float3x4 objectToWorld = ObjectToWorld3x4();
    float3x4 worldToObject = WorldToObject3x4();

    float3 geometricNormal = normalize(cross(
        mul(objectToWorld, float4(1, 0, 0, 0)).xyz,
        mul(objectToWorld, float4(0, 1, 0, 0)).xyz
    ));

    bool isFrontFace = HitKind() == HIT_KIND_TRIANGLE_FRONT_FACE;
    float3 normal = isFrontFace ? geometricNormal : -geometricNormal;

    payload.position = worldPos;
    payload.normal = normal;

    if (isFrontFace)
    {
        payload.hitDistance = hitDistance;
        payload.hitFlag = 1;
    }
    else
    {
        payload.hitDistance = -hitDistance * 0.2;
        payload.hitFlag = 2;
    }

    payload.albedo = float3(0.8, 0.8, 0.8);
    payload.emission = float3(0, 0, 0);
    payload.roughness = 0.5;
    payload.metallic = 0.0;
}

[shader("closesthit")]
void DDGIShadowClosestHitShader(inout DDGIRayPayload payload : SV_RayPayload,
                                 BuiltInTriangleIntersectionAttributes attribs : SV_IntersectionAttributes)
{

    payload.hitFlag = 1;
    payload.hitDistance = RayTCurrent();
}

[shader("anyhit")]
void DDGIAnyHitShader(inout DDGIRayPayload payload : SV_RayPayload,
                      BuiltInTriangleIntersectionAttributes attribs : SV_IntersectionAttributes)
{

    AcceptHitAndEndSearch();
}

#endif
