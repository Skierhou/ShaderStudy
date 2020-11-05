Shader "Unlit/007"
{
    Properties
    {
        _Diffuse("Diffuse",Color) = (1,1,1,1)
        _Specular("_Specular",Color) =(1,1,1,1)
        _Gloss("Gloss",float) = 0.5
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

            float4 _Diffuse;
            float4 _Specular;
            float _Gloss;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                fixed3 color : COLOR;
            };

            v2f vert (appdata_base v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);

                float worldPos = mul(unity_ObjectToWorld, v.vertex);

                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldLight = normalize(UnityWorldSpaceLightDir(worldPos));
                float3 diffuse = _Diffuse.rgb * _LightColor0.rgb * saturate(dot(worldNormal,worldLight));
                float3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;

                float3 reflectDir = normalize(reflect(-worldLight,worldNormal));
                float3 worldCameraDir = normalize(WorldSpaceViewDir(v.vertex));
                float3 specular = _Specular.rgb * _LightColor0.rgb * pow(saturate(dot(reflectDir,worldCameraDir)),_Gloss);

                o.color = diffuse + ambient + specular;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                return fixed4(i.color,1);
            }
            ENDCG
        }
    }
}
