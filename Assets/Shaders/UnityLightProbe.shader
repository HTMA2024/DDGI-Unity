Shader "UnityLightProbe"
{
	Properties
	{

	}

	SubShader
	{

		Tags { "RenderType"="Opaque" "LightMode"="ForwardBase" }
	LOD 100

		CGINCLUDE
		#pragma target 3.0
		ENDCG
		Blend Off
		AlphaToMask Off
		Cull Back
		ColorMask RGBA
		ZWrite On
		ZTest LEqual
		Offset 0 , 0

		Pass
		{
			Name "Unlit"

			CGPROGRAM

			#ifndef UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX

			#define UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input)
			#endif
			#pragma vertex vert
			#pragma fragment frag
			#pragma multi_compile_instancing
			#include "UnityCG.cginc"
			#define ASE_NEEDS_FRAG_WORLD_POSITION

			struct appdata
			{
				float4 vertex : POSITION;
				float4 color : COLOR;
				float3 ase_normal : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
			};

			struct v2f
			{
				float4 vertex : SV_POSITION;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 worldPos : TEXCOORD0;
				#endif
				float3 ase_normal : NORMAL;
				UNITY_VERTEX_INPUT_INSTANCE_ID
				UNITY_VERTEX_OUTPUT_STEREO
			};

			half3 SHEvalLinearL0L1Custom (half4 normal)
			{
			    half3 x;

			    x.r = dot(unity_SHAr,normal);
			    x.g = dot(unity_SHAg,normal);
			    x.b = dot(unity_SHAb,normal);

			    return x;
			}

			half3 SHEvalLinearL2Custom (half4 normal)
			{
			    half3 x1, x2;

			    half4 vB = normal.xyzz * normal.yzzx;
			    x1.r = dot(unity_SHBr,vB);
			    x1.g = dot(unity_SHBg,vB);
			    x1.b = dot(unity_SHBb,vB);

			    half vC = normal.x*normal.x - normal.y*normal.y;
			    x2 = unity_SHC.rgb * vC;

			    return x1 + x2;
			}

			half3 ShadeSHPerPixelCustom (half3 normal, half3 ambient, float3 worldPos)
			{
			    half3 ambient_contrib = 0.0;

		        ambient_contrib = SHEvalLinearL0L1Custom (half4(normal, 1.0));
		        ambient_contrib += SHEvalLinearL2Custom (half4(normal, 1.0));

		        ambient = max(half3(0, 0, 0), ambient+ambient_contrib);

			    return ambient;
			}
			float3 Indirect2( float3 normalWorld, float ambient, float3 worldPos )
			{
				return ShadeSHPerPixelCustom(normalWorld, ambient, worldPos);
			}

			v2f vert ( appdata v )
			{
				v2f o;
				UNITY_SETUP_INSTANCE_ID(v);
				UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(o);
				UNITY_TRANSFER_INSTANCE_ID(v, o);

				o.ase_normal = v.ase_normal;
				float3 vertexValue = float3(0, 0, 0);
				#if ASE_ABSOLUTE_VERTEX_POS
				vertexValue = v.vertex.xyz;
				#endif
				vertexValue = vertexValue;
				#if ASE_ABSOLUTE_VERTEX_POS
				v.vertex.xyz = vertexValue;
				#else
				v.vertex.xyz += vertexValue;
				#endif
				o.vertex = UnityObjectToClipPos(v.vertex);

				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				#endif
				return o;
			}

			fixed4 frag (v2f i ) : SV_Target
			{
				UNITY_SETUP_INSTANCE_ID(i);
				UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(i);
				fixed4 finalColor;
				#ifdef ASE_NEEDS_FRAG_WORLD_POSITION
				float3 WorldPosition = i.worldPos;
				#endif
				float3 normalWorld2 = i.ase_normal;
				float ambient2 = 0.0;
				float3 worldPos2 = WorldPosition;
				float3 localIndirect2 = Indirect2( normalWorld2 , ambient2 , worldPos2 );

				finalColor = float4( localIndirect2 , 0.0 );
				return finalColor;
			}
			ENDCG
		}
	}
	CustomEditor "ASEMaterialInspector"

	Fallback Off
}
