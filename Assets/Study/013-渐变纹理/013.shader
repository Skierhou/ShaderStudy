Shader "Unlit/013"
{
    Properties
    {
        _RampTex("RampTex", 2D) = "white"{}
        _Diffuse ("Diffuse", Color) = (1,1,1,1)
        _Specular ("Specular", Color) = (1,1,1,1)
        _Gloss ("Gloss", Range(1,256)) = 5
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            sampler2D _RampTex;
            float4 _RampTex_ST;     //不需要定义，与_RampTex绑定，tileing值 以及 offset值
            float4 _Diffuse;
            float4 _Specular;
            float _Gloss;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed3 worldNormal : TEXCOORD0;
                float3 worldVertex : TEXCOORD1;
                float2 uv :TEXCOORD2;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = UnityObjectToWorldNormal(v.normal);
                o.worldVertex = UnityObjectToWorldDir(v.vertex);

                //拿到模型uv 与tileing 以及 offset计算完后 返回当前uv
                o.uv = v.texcoord.xy * _RampTex_ST.xy + _RampTex_ST.zw;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                // 获得mainTex对应uv的颜色值
                fixed3 albedo = tex2D(_RampTex, i.uv).rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldVertex);

                fixed halfLambert = dot(worldLightDir,i.worldNormal) * 0.5 + 0.5;
                fixed3 diffuse = _LightColor0.rgb * tex2D(_RampTex,fixed2(halfLambert,halfLambert)) * _Diffuse.rgb * halfLambert;

                fixed3 worldCameraDir = normalize(UnityWorldSpaceViewDir(i.worldVertex));
                fixed3 halfDir = normalize(worldCameraDir + worldLightDir);

                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(i.worldNormal, halfDir)), _Gloss);
                fixed3 color = specular + diffuse + ambient;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
