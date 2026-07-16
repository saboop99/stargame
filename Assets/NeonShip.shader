Shader "Custom/NeonShip"
{
    Properties
    {
        _MainTex ("Sprite Texture", 2D) = "white" {}

        // --- Cores ---
        _TintColor      ("Ship Tint",          Color) = (0.8, 0.4, 1.0, 1)    // roxo neon base
        _EngineColor    ("Engine Glow Color",  Color) = (0.0, 0.8, 1.0, 1)    // ciano
        _TrailColor     ("Trail Color",        Color) = (1.0, 0.0, 0.8, 1)    // magenta
        _RimColor       ("Rim Light Color",    Color) = (0.5, 0.0, 1.0, 1)    // violeta

        // --- Glow geral ---
        _GlowIntensity  ("Glow Intensity",     Range(0.0, 5.0))  = 2.0
        _GlowSpread     ("Glow Edge Spread",   Range(0.0, 1.0))  = 0.15

        // --- Engine / thruster ---
        _EngineIntensity("Engine Intensity",   Range(0.0, 5.0))  = 3.0
        _EnginePulseSpeed("Engine Pulse Spd", Range(0.0, 10.0)) = 4.0
        _EngineWidth    ("Engine Width",       Range(0.0, 0.5))  = 0.12   // faixa do thruster (em UV)

        // --- Trail / rastro ---
        _TrailLength    ("Trail Length",       Range(0.0, 1.0))  = 0.5
        _TrailIntensity ("Trail Intensity",    Range(0.0, 3.0))  = 1.5
        _TrailSpeed     ("Trail Flicker Spd",  Range(0.0, 10.0)) = 6.0

        // --- Inclinação de movimento ---
        // Alimente via script: -1 = virou esquerda, 0 = reto, 1 = virou direita
        _TiltAmount     ("Tilt (script)",      Range(-1.0, 1.0)) = 0.0
        _TiltShear      ("Tilt Shear Strength",Range(0.0, 0.3))  = 0.08
        _TiltColorShift ("Tilt Color Shift",   Range(0.0, 1.0))  = 0.4

        // --- Scanline / pixel ---
        _PixelSize      ("Pixel Snap Size",    Range(1, 32))     = 4
        _ScanlineStr    ("Scanline Strength",  Range(0.0, 1.0))  = 0.15
        _ScanlineSpeed  ("Scanline Speed",     Range(0.0, 5.0))  = 1.0
    }

    SubShader
    {
        Tags
        {
            "Queue"           = "Transparent"
            "RenderType"      = "Transparent"
            "RenderPipeline"  = "UniversalPipeline"
            "IgnoreProjector" = "True"
        }

        Blend SrcAlpha OneMinusSrcAlpha
        ZWrite Off
        Cull Off

        Pass
        {
            HLSLPROGRAM
            #pragma vertex   vert
            #pragma fragment frag
            #include "Packages/com.unity.render-pipelines.universal/ShaderLibrary/Core.hlsl"

            // ----------------------------------------------------------------
            struct Attributes
            {
                float4 positionOS : POSITION;
                float2 uv         : TEXCOORD0;
                float4 color      : COLOR;
            };

            struct Varyings
            {
                float4 positionHCS : SV_POSITION;
                float2 uv          : TEXCOORD0;
                float4 color       : COLOR;
            };

            // ----------------------------------------------------------------
            TEXTURE2D(_MainTex);
            SAMPLER(sampler_MainTex);

            CBUFFER_START(UnityPerMaterial)
                float4 _MainTex_ST;
                float4 _TintColor;
                float4 _EngineColor;
                float4 _TrailColor;
                float4 _RimColor;

                float  _GlowIntensity;
                float  _GlowSpread;

                float  _EngineIntensity;
                float  _EnginePulseSpeed;
                float  _EngineWidth;

                float  _TrailLength;
                float  _TrailIntensity;
                float  _TrailSpeed;

                float  _TiltAmount;
                float  _TiltShear;
                float  _TiltColorShift;

                float  _PixelSize;
                float  _ScanlineStr;
                float  _ScanlineSpeed;
            CBUFFER_END

            // ----------------------------------------------------------------
            // Helpers
            // ----------------------------------------------------------------
            float2 PixelSnap(float2 uv, float pixelSize)
            {
                float2 grid = float2(pixelSize, pixelSize);
                // snap em espaço de texel
                return floor(uv * grid) / grid;
            }

            float Hash(float n)
            {
                return frac(sin(n) * 43758.5453123);
            }

            // Noise 1D simples
            float Noise1D(float x)
            {
                float i = floor(x);
                float f = frac(x);
                return lerp(Hash(i), Hash(i + 1.0), smoothstep(0.0, 1.0, f));
            }

            // ----------------------------------------------------------------
            // Vertex — aplica shear de inclinação
            // ----------------------------------------------------------------
            Varyings vert(Attributes IN)
            {
                Varyings OUT;

                // Shear horizontal conforme _TiltAmount
                float4 pos = IN.positionOS;
                // Deforma mais no topo (uv.y alto) ao virar
                pos.x += IN.uv.y * _TiltAmount * _TiltShear;

                OUT.positionHCS = TransformObjectToHClip(pos.xyz);
                OUT.uv          = TRANSFORM_TEX(IN.uv, _MainTex);
                OUT.color       = IN.color;
                return OUT;
            }

            // ----------------------------------------------------------------
            // Fragment
            // ----------------------------------------------------------------
            half4 frag(Varyings IN) : SV_Target
            {
                float t = _Time.y;

                // UV com pixel snap
                float2 uv = IN.uv;
                float2 snappedUV = PixelSnap(uv, _PixelSize);

                // Sprite original
                half4 sprite = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv);
                if (sprite.a < 0.01) discard;   // descarta pixels transparentes cedo

                // ---- 1. Tint base com glow na borda -------------------------
                // Borda = pixels onde o alpha cai rapidamente
                float edgeDist  = 1.0 - smoothstep(0.0, _GlowSpread, sprite.a);
                float4 baseColor = sprite * _TintColor;
                baseColor.rgb   += _RimColor.rgb * edgeDist * _GlowIntensity;

                // ---- 2. Engine / thruster (parte de baixo da sprite) --------
                // uv.y próximo de 0 = base da nave (thruster)
                float engineMask = smoothstep(_EngineWidth, 0.0, uv.y) * sprite.a;

                // Pulso: senoide + noise para cintilação orgânica
                float pulse = 0.5 + 0.5 * sin(t * _EnginePulseSpeed)
                            + 0.2 * Noise1D(t * _EnginePulseSpeed * 1.7);
                pulse = saturate(pulse);

                float4 engineGlow = _EngineColor * _EngineIntensity * engineMask * pulse;

                // ---- 3. Rastro (trail) — faixa vertical atrás da nave ------
                // Simula rastro usando uv.y: quanto mais perto de 0, mais intenso
                // e se move com o tempo para efeito de partículas
                float trailV    = uv.y / max(_TrailLength, 0.001);
                float trailMask = (1.0 - saturate(trailV)) * (1.0 - smoothstep(0.3, 0.5, abs(uv.x - 0.5) * 2.0));
                trailMask      *= sprite.a;

                // Cintilação do rastro
                float trailNoise = Noise1D(uv.y * 8.0 - t * _TrailSpeed);
                float4 trailGlow = _TrailColor * _TrailIntensity * trailMask * trailNoise;

                // ---- 4. Chromatic / color shift ao inclinar ----------------
                // Leve aberração: desloca o canal vermelho na direção do tilt
                float shiftAmount = abs(_TiltAmount) * _TiltColorShift * 0.02;
                float rShift = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv + float2(shiftAmount, 0)).r;
                float bShift = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, uv - float2(shiftAmount, 0)).b;
                baseColor.r  = lerp(baseColor.r, rShift * _TintColor.r, abs(_TiltAmount) * _TiltColorShift);
                baseColor.b  = lerp(baseColor.b, bShift * _TintColor.b, abs(_TiltAmount) * _TiltColorShift);

                // ---- 5. Scanline (pixel retro) -----------------------------
                float scanline = sin((snappedUV.y + t * _ScanlineSpeed) * _PixelSize * 3.14159) * 0.5 + 0.5;
                scanline       = 1.0 - _ScanlineStr * (1.0 - scanline);

                // ---- Composição final --------------------------------------
                float4 col  = baseColor;
                col        += engineGlow;
                col        += trailGlow;
                col.rgb    *= scanline;
                col.rgb     = saturate(col.rgb);
                col.a       = sprite.a * IN.color.a;

                return col;
            }
            ENDHLSL
        }
    }

    FallBack "Sprites/Default"
}
