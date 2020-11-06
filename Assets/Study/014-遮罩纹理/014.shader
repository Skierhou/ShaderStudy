Shader "Unlit/014"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white"{}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", float) = 1
        _SpecularMask("Specular Mask",2D) = "white"{}
        _SpecularScale("Specular Scale",float) = 1
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

            sampler2D _MainTex;
            float4 _MainTex_ST;     //不需要定义，与_MainTex绑定，tileing值 以及 offset值
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            float4 _Diffuse;
            float4 _Specular;
            float _Gloss;

            sampler2D _SpecularMask;
            float4 _SpecularMask_ST;
            float _SpecularScale;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv :TEXCOORD0;
                float2 maskUv : TEXCOORD1;
                float3 lightDir : TEXCOORD2;
                float3 viewDir :TEXCOORD3;
            };

            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);
                o.maskUv = TRANSFORM_TEX(v.texcoord,_SpecularMask);

                TANGENT_SPACE_ROTATION;

                o.lightDir = normalize(mul(rotation,ObjSpaceLightDir(v.vertex)).xyz);
                o.viewDir = normalize(mul(rotation,ObjSpaceViewDir(v.vertex)).xyz);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 packedNormal = tex2D(_BumpMap,i.uv.zw);

                fixed3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;

                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * saturate(dot(i.lightDir,tangentNormal));

                fixed3 halfDir = normalize(i.viewDir + i.lightDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss);
                
                //高光遮罩
                float mask = tex2D(_SpecularMask,i.maskUv).r * _SpecularScale;

                fixed3 color = specular * mask + diffuse + ambient;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
