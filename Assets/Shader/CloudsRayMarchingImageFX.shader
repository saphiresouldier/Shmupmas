Shader "Custom/CloudsRayMarchingImageFX"
{
	HLSLINCLUDE

	#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"

	TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
	TEXTURE2D_SAMPLER2D(_NoiseTex, sampler_NoiseTex);
	float _Blend;
	float _NoiseTexDimension;

	float4 Frag(VaryingsDefault i) : SV_Target
	{
		float4 color = SAMPLE_TEXTURE2D(_MainTex, sampler_MainTex, i.texcoord);
		float4 noise = SAMPLE_TEXTURE2D(_NoiseTex, sampler_NoiseTex, i.texcoord);
		float luminance = dot(color.rgb, float3(0.2126729, 0.7151522, 0.0721750));
		color.rgb = lerp(color.rgb, luminance.xxx, _Blend.xxx);
		return color;
	}

		ENDHLSL

		SubShader
	{
		Cull Off ZWrite Off ZTest Always

			Pass
		{
			HLSLPROGRAM

				#pragma vertex VertDefault
				#pragma fragment Frag

			ENDHLSL
		}
	}
}