Shader "Vivify/CustomObjects/CustomSaber"
{
    Properties
    {
        /*
        These are fed in by Vivify per saber.
        In fact, Vivify will attempt to feed these values into every child of a saber prefab.
        */
        _Color ("Saber Color", Color) = (1,1,1)
        _RimPower ("Rim Power", float) = 1
        _Glow ("Glow opacity", Range(0, 1)) = 0
        _timespeed ("Time Speed", float) = 1
        _uvscale ("UV Scale", float) = 1
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #pragma multi_compile_instancing // Insert for GPU instancing
            // Ensure to check "Enable GPU Instancing" on the material

            #include "UnityCG.cginc"
            #include "Assets/VivifyTemplate/Utilities/Shader Functions/Noise.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 uv : TEXCOORD0;
                UNITY_VERTEX_INPUT_INSTANCE_ID
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float2 uv : TEXCOORD0;
                float3 worldPos : TEXCOORD1;
                float3 normal : TEXCOORD2;
                UNITY_VERTEX_INPUT_INSTANCE_ID // Insert for GPU instancing
                UNITY_VERTEX_OUTPUT_STEREO
            };

            // Register GPU instanced properties (apply per-saber)
            UNITY_INSTANCING_BUFFER_START(Props)
            UNITY_DEFINE_INSTANCED_PROP(float3, _Color)
            UNITY_INSTANCING_BUFFER_END(Props)

            v2f vert (appdata v)
            {
                v2f o;
                UNITY_INITIALIZE_OUTPUT(v2f, o);
                UNITY_SETUP_INSTANCE_ID(v);
                UNITY_TRANSFER_INSTANCE_ID(v, o); // Insert for GPU instancing
                UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
                o.uv = v.uv;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                o.normal = UnityObjectToWorldNormal(v.normal);
                return o;
            }

            //https://www.shadertoy.com/view/MlVGDK

            float n ( float3 x ) {
                float s = perlin(x);
                for (float i = 2.0; i < 10.0; i += 1.0) {
                    s += perlin(x / i) / i;
                }
                return s;
            }

            float _RimPower;
            float _Glow;
            float _timespeed;
            float _uvscale;

            fixed4 frag (v2f i) : SV_Target
            {
                UNITY_SETUP_INSTANCE_ID(i); // Insert for GPU instancing

                // The color of the saber
                float3 Color = UNITY_ACCESS_INSTANCED_PROP(Props, _Color);

                float3 viewDir = normalize(_WorldSpaceCameraPos - i.worldPos);
                half rim = 1.0 - saturate(dot(normalize(viewDir), normalize(i.normal)));
                float3 finalColor = lerp(Color.bgr, Color.rgb, pow(rim, 0.1));
                finalColor = pow(finalColor, _RimPower);

                float3 v1 = (i.uv.xyy * _uvscale) + _Time * _timespeed * 3.14;
                float3 v2 = (i.uv.xyy * _uvscale) + _Time * _timespeed;
                float a = abs(n(float3(v1.xy, sin(_Time.y * _timespeed))) - n(float3(v2.xy, cos((_Time.y * _timespeed) + 3.0))));
                float powA = pow(a, 0.2);
                float3 noiseColor = float3(0.5 - powA * 0.5, 0.5 - powA * 0.5, 0.5 - powA * 0.5);
                noiseColor = saturate(noiseColor+0.25);

                return float4(noiseColor * finalColor * 2, Luminance(finalColor));
            }
            ENDCG
        }
        Pass
        {
            Name "ShadowCaster"
            Tags { "LightMode" = "ShadowCaster" }
            ZWrite On ZTest LEqual
            // add all fragment modifications here with the final v2f output being SHADOW_CASTER_FRAGMENT(i)
        }
    }
}
