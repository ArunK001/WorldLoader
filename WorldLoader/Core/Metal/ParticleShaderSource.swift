import Foundation

enum ParticleShaderSource {
    static let code = """
    #include <metal_stdlib>
    using namespace metal;

    struct Particle {
        float2 position;
        float  brightness;
        float  opacity;
        float  scale;
        float  shape;
    };

    struct Uniforms {
        float2 viewport;
        float2 origin;
        float  side;
        float  dotSize;
        float4 dotColor;
        float4 glowColor;
        float4 fadedColor;
        float4 background;
        float  time;
    };

    struct VertexOut {
        float4 position [[position]];
        float  pointSize [[point_size]];
        float4 color;
        float  shape;
        float  glow;
    };

    static inline float3 mix3(float3 a, float3 b, float t) {
        return a + (b - a) * clamp(t, 0.0f, 1.0f);
    }

    vertex VertexOut particle_vertex(
        const device Particle *particles [[buffer(0)]],
        constant Uniforms &uniforms [[buffer(1)]],
        uint vid [[vertex_id]]
    ) {
        Particle p = particles[vid];
        float2 pixel = uniforms.origin + p.position * uniforms.side;

        float2 ndc;
        ndc.x = (pixel.x / uniforms.viewport.x) * 2.0f - 1.0f;
        ndc.y = 1.0f - (pixel.y / uniforms.viewport.y) * 2.0f;

        float brightness = p.brightness;
        float3 base = mix3(uniforms.fadedColor.rgb, uniforms.dotColor.rgb, min(1.0f, brightness));
        float3 color = brightness > 1.0f
            ? mix3(base, uniforms.glowColor.rgb, min(1.0f, (brightness - 1.0f) / 1.2f))
            : base;

        float size = max(1.5f, uniforms.dotSize * p.scale * (1.0f + max(0.0f, brightness - 1.0f) * 0.25f));

        VertexOut out;
        out.position = float4(ndc, 0.0f, 1.0f);
        out.pointSize = size * 2.4f;
        out.color = float4(color, clamp(p.opacity * min(1.0f, 0.45f + brightness * 0.5f), 0.0f, 1.0f));
        out.shape = p.shape;
        out.glow = clamp((brightness - 0.85f) * 0.55f, 0.0f, 0.85f);
        return out;
    }

    fragment float4 particle_fragment(VertexOut in [[stage_in]],
                                      float2 pc [[point_coord]]) {
        float2 uv = pc * 2.0f - 1.0f;
        float alpha = 0.0f;

        if (in.shape < 0.5f) {
            float d = length(uv);
            float core = 1.0f - smoothstep(0.18f, 0.52f, d);
            float halo = (1.0f - smoothstep(0.35f, 1.0f, d)) * in.glow;
            alpha = max(core, halo * 0.55f);
        } else if (in.shape < 1.5f) {
            float2 a = abs(uv);
            float d = max(a.x, a.y);
            alpha = 1.0f - smoothstep(0.42f, 0.62f, d);
        } else {
            float2 p = float2(uv.x, -uv.y);
            float d = max(abs(p.x) * 0.9f + p.y * 0.55f, -p.y - 0.15f);
            alpha = 1.0f - smoothstep(0.35f, 0.55f, d);
        }

        float4 color = in.color;
        color.a *= alpha;
        if (color.a < 0.01f) discard_fragment();
        return color;
    }

    struct LineVertexIn {
        float2 position;
    };

    struct LineVertexOut {
        float4 position [[position]];
        float4 color;
    };

    vertex LineVertexOut line_vertex(
        const device LineVertexIn *vertices [[buffer(0)]],
        constant Uniforms &uniforms [[buffer(1)]],
        uint vid [[vertex_id]]
    ) {
        float2 pixel = uniforms.origin + vertices[vid].position * uniforms.side;
        float2 ndc;
        ndc.x = (pixel.x / uniforms.viewport.x) * 2.0f - 1.0f;
        ndc.y = 1.0f - (pixel.y / uniforms.viewport.y) * 2.0f;

        LineVertexOut out;
        out.position = float4(ndc, 0.0f, 1.0f);
        out.color = float4(uniforms.dotColor.rgb, 0.92f);
        return out;
    }

    fragment float4 line_fragment(LineVertexOut in [[stage_in]]) {
        return in.color;
    }
    """
}
