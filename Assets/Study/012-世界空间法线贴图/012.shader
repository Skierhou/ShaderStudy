Shader "Unlit/012"
{
    Properties
    {
        _MainTex("MainTex", 2D) = "white"{}
        _BumpMap("Normal Map", 2D) = "bump" {}
        _BumpScale("Normal Scale", float) = 1
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
            float4 _MainTex_ST;
            sampler2D _BumpMap;
            float4 _BumpMap_ST;
            float _BumpScale;
            float4 _Diffuse;
            float4 _Specular;
            float _Gloss;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv :TEXCOORD0;
                float4 T2W0 : TEXCOORD1;
                float4 T2W1 : TEXCOORD2;
                float4 T2W2 : TEXCOORD3;
            };

            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex).xyz;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent);
                float3 worldBiNormal = cross(worldNormal,worldTangent) * v.tangent.w;

                //
                o.T2W0 = float4(worldTangent.x,worldBiNormal.x,worldNormal.x,worldPos.x);
                o.T2W1 = float4(worldTangent.y,worldBiNormal.y,worldNormal.y,worldPos.y);
                o.T2W2 = float4(worldTangent.z,worldBiNormal.z,worldNormal.z,worldPos.z);

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 worldPos = float3(i.T2W0.w,i.T2W1.w,i.T2W2.w);

                //世界空间光照以及视角
                fixed3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                //获得纹理
                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb;
                fixed4 packedNormal = tex2D(_BumpMap,i.uv.wz);

                //切线空间法线转换至世界坐标
                fixed3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;

                //这里相当于 mul(变换矩阵,tangentNormal) 
                tangentNormal = normalize(float3(dot(i.T2W0.xyz,tangentNormal),dot(i.T2W1.xyz,tangentNormal),dot(i.T2W2.xyz,tangentNormal)));

                //环境光
                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                // lanboter
                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * saturate(dot(lightDir,tangentNormal));

                //blind Phone
                fixed3 halfDir = normalize(viewDir + lightDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss);
                
                fixed3 color = specular + diffuse + ambient;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
