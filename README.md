[中文版本 (Chinese Version)](README_CN.md)

# URP Dynamic Diffuse Global Illumination (DDGI)

A dynamic diffuse global illumination system built on Unity URP 14.0 + DXR, based on the NVIDIA RTXGI SDK. Light probes are placed on a uniform 3D grid, with hardware ray tracing updating irradiance / distance atlases each frame to provide real-time indirect lighting.

## Showcase

![overview](assets/github-repo-images/DDGI-Unity/overview.gif)

## Rendering Pipeline

```
Per Frame:
  Build RTAS → Dispatch Rays → G-Buffer
  → [Probe Relocation] → [Probe Classification]
  → LightingCombined (Direct + Indirect + Radiance, single pass)
  → Monte Carlo Integration (Irradiance + Distance Atlas)
  → [Variability Reduction] → Border Update → Ping-Pong Swap

Apply GI (URP RendererFeature):
  Depth → World Pos → Sample DDGI Atlas (trilinear + Chebyshev) → Additive Composite
```

## Key Technical Details

### Per-Stage Visualization

| Direct Irradiance | Indirect Irradiance | Outgoing Radiance | Irradiance |
|---|---|---|---|
| ![direct](assets/github-repo-images/DDGI-Unity/direct-irradiance.jpg) | ![indirect](assets/github-repo-images/DDGI-Unity/indirect-irradiance.jpg) | ![radiance](assets/github-repo-images/DDGI-Unity/radiance.jpg) | ![irradiance](assets/github-repo-images/DDGI-Unity/irradiance.jpg) |

### Probe Relocation

![probe-relocation](assets/github-repo-images/DDGI-Unity/probe-relocation.gif)

### Implementation Details

- Direct lighting, indirect light sampling, and radiance compositing compressed into a single compute pass (LightingCombined), eliminating intermediate buffers
- Atlas uses ping-pong double buffering — writes to Current, reads from Prev — zero-copy swap
- Ray directions based on Fibonacci sphere uniform distribution + Halton sequence per-frame random rotation
- Monte Carlo integration uses exponential moving average (hysteresis); irradiance uses gamma encoding (γ=5.0) for improved dark region precision
- Probe Relocation automatically moves probes embedded in geometry; Classification marks invalid probes based on backface hit ratio
- Variability Reduction via multi-level reduction + AsyncGPUReadback drives adaptive update frequency
- Light leak suppression: surface bias, Chebyshev visibility test, weight crushing
- GI application stage: trilinear interpolation + Chebyshev visibility-weighted sampling of surrounding 8 probes

## Directory Structure

```
Assets/DDGILightProbe/
├── Runtime/
│   ├── Core/              DDGIVolume, DDGIRaytracingManager, DDGIProbeUpdater,
│   │                      DDGIAtlasManager, DDGIApplyGIRendererFeature,
│   │                      DDGIProbeVisualizer, DDGISkyOnlyValidator ...
│   └── Shaders/
│       ├── DDGILightingCombined.compute      Combined lighting pass
│       ├── DDGIMonteCarloIntegration.compute  Monte Carlo integration + Border Update
│       ├── DDGIProbeRelocation.compute        Probe relocation
│       ├── DDGIProbeClassification.compute    Probe classification
│       ├── DDGIVariabilityReduction.compute   Variability reduction
│       ├── DDGISampling.hlsl                  Atlas sampling utilities
│       ├── DDGIApplyGI.shader                 Full-screen GI composite
│       └── DDGIRaytracing/                    RayGen, ClosestHit, Miss, GBuffer
└── Editor/                Volume / Updater / Visualizer / Validator Inspector
```

## Requirements

- Unity 2022.3+, Windows, DirectX 12
- GPU with DXR 1.0 support (NVIDIA RTX / AMD RX 6000+)
- URP 14.0+, Deferred Rendering Path

## Setup

1. Add `DDGIApplyGIRendererFeature` to the URP Renderer
2. Create a GameObject → Light → DDGI Volume in the scene
3. Set `DDGIProbeUpdater` to Raytracing mode, click "Auto Find Shaders"
4. Adjust Volume parameters; enter Play Mode to see real-time GI

## References

- [NVIDIA RTXGI SDK](https://github.com/NVIDIAGameWorks/RTXGI)
- Majercik et al., *Dynamic Diffuse Global Illumination with Ray-Traced Irradiance Fields*, JCGT 2019
- Majercik et al., *Scaling Probe-Based Real-Time Dynamic Global Illumination for Production*, JCGT 2021

## License & Acknowledgments

This project contains Sponza scene assets under the following licenses:

- Sponza model: CC BY 3.0 — © 2010 Frank Meinl, Crytek
- NoEmotion HDRs textures: CC BY-ND 4.0 — © 2022 Peter Sanitra

See `Assets/com.unity.sponza-urp@5665fb87d0/copyright.txt` for full copyright information.
