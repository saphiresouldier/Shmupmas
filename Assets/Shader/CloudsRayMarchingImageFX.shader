Shader "Custom/CloudsRayMarchingImageFX"
{
	SubShader
	{

		Cull Off ZWrite Off ZTest Always

		Pass
		{
			HLSLPROGRAM

			// make fog work
			#pragma multi_compile_fog

			#include "CloudsRayMarchingImageFX.hlsl"

			#pragma vertex vert
			#pragma fragment frag

			ENDHLSL
		}
	}
}