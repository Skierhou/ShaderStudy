﻿Shader "Unlit/011"
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
            float4 _MainTex_ST;     //不需要定义，与_MainTex绑定，tileing值 以及 offset值
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
                float3 lightDir : TEXCOORD1;
                float3 viewDir :TEXCOORD2;
            };

            v2f vert (appdata_tan v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.texcoord,_MainTex);
                o.uv.zw = TRANSFORM_TEX(v.texcoord,_BumpMap);

                //求副切线向量
                //float3 binormal = cross(normalize(v.normal),normalize(v.tangent.xyz)) * v.tangent.w;
                //模型空间到切线空间的旋转矩阵
                //float3x3 rotation = float3x3(v.tangent.xyz,binormal,v.normal);
                TANGENT_SPACE_ROTATION;     //这个宏定义了上面两条代码

                //拿到模型uv 与tileing 以及 offset计算完后 返回当前uv
                //o.uv = v.texcoord.xy * _MainTex_ST.xy + _MainTex_ST.zw;

                //ObjSpaceLightDir / ObjSpaceViewDir  获取 物体空间的光照以及视角向量，  乘旋转矩阵即可
                o.lightDir = normalize(mul(rotation,ObjSpaceLightDir(v.vertex)).xyz);
                o.viewDir = normalize(mul(rotation,ObjSpaceViewDir(v.vertex)).xyz);
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 packedNormal = tex2D(_BumpMap,i.uv.wz);

                //如果法线使用Default模式 则需要计算
                // fixed3 tangentNormal;
                // tangentNormal.xy = (packedNormal.xy * 2 -1) * _BumpScale;
                // tangentNormal.z = sqrt(1-saturate(dot(tangentNormal.xy,tangentNormal.xy)));
                
                //如果法线使用NormalMap 模式，Unity自动计算
                fixed3 tangentNormal = UnpackNormal(packedNormal);
                tangentNormal.xy *= _BumpScale;

                // 获得mainTex对应uv的颜色值
                fixed3 albedo = tex2D(_MainTex, i.uv.xy).rgb;

                fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
                fixed3 diffuse = _LightColor0.rgb * albedo * _Diffuse.rgb * saturate(dot(i.lightDir,tangentNormal));

                fixed3 halfDir = normalize(i.viewDir + i.lightDir);
                fixed3 specular = _LightColor0.rgb * _Specular.rgb * pow(saturate(dot(tangentNormal, halfDir)), _Gloss);
                
                fixed3 color = specular + diffuse + ambient;
                return fixed4(color,1);
            }
            ENDCG
        }
    }
}
