Shader "Custom/CloudsRayMarching"
{
    Properties
    {
        _NoiseTex ("Noise Texture", 2D) = "white" {}
		_NoiseTexSize ("Noise Texture Dimension", Float) = 512
    }
    SubShader
    {
        Tags { "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                UNITY_FOG_COORDS(1)
                float4 vertex : SV_POSITION;
				float4 screenpos : TEXCOORD2;
            };

            sampler2D _NoiseTex;
			float _NoiseTexSize;
            float4 _MainTex_ST;

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				UNITY_TRANSFER_FOG(o, o.vertex);
				o.screenpos = ComputeScreenPos(o.vertex);
                return o;
            }

			//--------------------------------------------------------------------------------
			//TODO
			//
			//Cloud Ten
			//by nimitz 2015 (twitter: @stormoid)
			//License Creative Commons Attribution-NonCommercial-ShareAlike 3.0 Unported License

			float2x2 mm2(float a) { float c = cos(a), s = sin(a); return float2x2(c, s, -s, c); }
			float noise(float t) { return tex2D(_NoiseTex, float2(t, .0) / float2(_NoiseTexSize, _NoiseTexSize)).x; }
			float moy = 0.;

			float noise(float3 p)
			{
				float3 ip = floor(p);
				float3 fp = frac(p);
				fp = fp * fp*(3.0 - 2.0*fp);
				float2 tap = (ip.xy + float2(37.0, 17.0)*ip.z) + fp.xy;
				float2 rz = tex2D(_NoiseTex, (tap + 0.5) / 256.0).yx;
				return lerp(rz.x, rz.y, fp.z);
			}

			float fbm(float3 x)
			{
				float rz = 0.;
				float a = .35;
				for (int i = 0; i < 2; i++)
				{
					rz += noise(x)*a;
					a *= .35;
					x *= 4.;
				}
				return rz;
			}

			float path(float x) { return sin(x*0.01 - 3.1415)*28. + 6.5; }

			float map(float3 p) {
				return p.y*0.07 + (fbm(p*0.3) - 0.1) + sin(p.x*0.24 + sin(p.z*.01)*7.)*0.22 + 0.15 + sin(p.z*0.08)*0.05;
			}

			float march(float3 ro, float3 rd)
			{
				float precis = .3;
				float h = 1.;
				float d = 0.;
				for (int i = 0; i < 17; i++)
				{
					if (abs(h) < precis || d > 70.) break;
					d += h;
					float3 pos = ro + rd * d;
					pos.y += .5;
					float res = map(pos)*7.;
					h = res;
				}
				return d;
			}

			float3 lgt = float3(0,0,0);
			float mapV(float3 p) { return clamp(-map(p), 0., 1.); }

			float4 marchV(float3 ro, float3 rd, float t, float3 bgc)
			{
				float4 rz = float4(0.0, 0.0, 0.0, 0.0);

				for (int i = 0; i < 150; i++)
				{
					if (rz.a > 0.99 || t > 200.) break;

					float3 pos = ro + t * rd;
					float den = mapV(pos);

					float4 col = float4(lerp(float3(.8, .75, .85), float3(0.0, 0.0, 0.0), den), den);
					col.xyz *= lerp(bgc*bgc*2.5, lerp(float3(0.1, 0.2, 0.55), float3(.8, .85, .9), moy*0.4), clamp(-(den*40. + 0.)*pos.y*.03 - moy * 0.5, 0., 1.));
					col.rgb += clamp((1. - den * 6.) + pos.y*0.13 + .55, 0., 1.)*0.35*lerp(bgc, float3(1,1,1), 0.7); //Fringes
					col += clamp(den*pos.y*.15, -.02, .0); //Depth occlusion
					col *= smoothstep(0.2 + moy * 0.05, .0, mapV(pos + 1.*lgt))*.85 + 0.15; //Shadows

					col.a *= .95;
					col.rgb *= col.a;
					rz = rz + col * (1.0 - rz.a);

					t += max(.3, (2. - den * 30.)*t*0.011);
				}

				return clamp(rz, 0., 1.);
			}

			float pent(float2 p) {
				float2 q = abs(p);
				return max(max(q.x*1.176 - p.y*0.385, q.x*0.727 + p.y), -p.y*1.237)*1.;
			}

			float3 lensFlare(float2 p, float2 pos)
			{
				float2 q = p - pos;
				float dq = dot(q, q);
				float2 dist = p * (length(p))*0.75;
				float ang = atan2(q.y, q.x);
				float2 pp = lerp(p, dist, 0.5);
				float sz = 0.01;
				float rz = pow(abs(frac(ang*.8 + .12) - 0.5), 3.)*(noise(ang*15.))*0.5;
				rz *= smoothstep(1.0, 0.0, dot(q, q));
				rz *= smoothstep(0.0, 0.01, dot(q, q));
				rz += max(1.0 / (1.0 + 30.0*pent(dist + 0.8*pos)), .0)*0.17;
				rz += clamp(sz - pow(pent(pp + 0.15*pos), 1.55), .0, 1.)*5.0;
				rz += clamp(sz - pow(pent(pp + 0.1*pos), 2.4), .0, 1.)*4.0;
				rz += clamp(sz - pow(pent(pp - 0.05*pos), 1.2), .0, 1.)*4.0;
				rz += clamp(sz - pow(pent((pp + .5*pos)), 1.7), .0, 1.)*4.0;
				rz += clamp(sz - pow(pent((pp + .3*pos)), 1.9), .0, 1.)*3.0;
				rz += clamp(sz - pow(pent((pp - .2*pos)), 1.3), .0, 1.)*4.0;
				return float3(clamp(rz, 0., 1.0), clamp(rz, 0., 1.), clamp(rz, 0., 1.));
			}

			float3x3 rot_x(float a) { float sa = sin(a); float ca = cos(a); return float3x3(1., .0, .0, .0, ca, sa, .0, -sa, ca); }
			float3x3 rot_y(float a) { float sa = sin(a); float ca = cos(a); return float3x3(ca, .0, sa, .0, 1., .0, -sa, .0, ca); }
			float3x3 rot_z(float a) { float sa = sin(a); float ca = cos(a); return float3x3(ca, sa, .0, -sa, ca, .0, .0, .0, 1.); }

			fixed4 mainImage(float2 q)
			{
				/*float2 q = fragCoord.xy / _ScreenParams.xy;*/
				//float2 q = fragCoord.xy;
				float2 p = q - 0.5;
				float asp = _ScreenParams.x / _ScreenParams.y;
				p.x *= asp;
				float2 mo = float2(0.5, 0.5);
				//float2 mo = iMouse.xy / _ScreenParams.xy;
				moy = mo.y;
				float st = sin(_Time.y*0.3 - 1.3)*0.2;
				float3 ro = float3(0., -2. + sin(_Time.y*.3 - 1.)*2., _Time.y*30.);
				ro.x = path(ro.z);
				float3 ta = ro + float3(0, 0, 1);
				float3 fw = normalize(ta - ro);
				float3 uu = normalize(cross(float3(0.0, 1.0, 0.0), fw));
				float3 vv = normalize(cross(fw, uu));
				const float zoom = 1.;
				float3 rd = normalize(p.x*uu + p.y*vv + -zoom * fw);

				float rox = sin(_Time.y*0.2)*0.6 + 2.9;
				rox += smoothstep(0.6, 1.2, sin(_Time.y*0.25))*3.5;
				float roy = sin(_Time.y*0.5)*0.2;
				float3x3 rotation = rot_x(-roy)*rot_y(-rox + st * 1.5)*rot_z(st);
				float3x3 inv_rotation = rot_z(-st)*rot_y(rox - st * 1.5)*rot_x(roy);
				rd = mul(rd, rotation);
				rd.y -= dot(p, p)*0.06;
				rd = normalize(rd);

				float3 col = float3(0.0, 0.0, 0.0); //BG Base Color
				lgt = normalize(float3(-0.3, mo.y + 0.1, 1.));
				float rdl = clamp(dot(rd, lgt), 0., 1.);

				float3 hor = lerp(float3(.9, .6, .7)*0.35, float3(.5, 0.05, 0.05), rdl);
				hor = lerp(hor, float3(.5, .8, 1), mo.y);
				col += lerp(float3(.2, .2, .6), hor, exp2(-(1. + 3.*(1. - rdl))*max(abs(rd.y), 0.)))*.6;
				col += .8*float3(1., .9, .9)*exp2(rdl*650. - 650.);
				col += .3*float3(1., 1., 0.1)*exp2(rdl*100. - 100.);
				col += .5*float3(1., .7, 0.)*exp2(rdl*50. - 50.);
				col += .4*float3(1., 0., 0.05)*exp2(rdl*10. - 10.);
				
				float3 bgc = col;

				float rz = march(ro, rd);
				//float rz = 75.;

				if (rz < 70.)
				{
					float4 res = marchV(ro, rd, rz - 5., bgc);
					col = col * (1.0 - res.w) + res.xyz;
				}

				float3 proj = mul(-lgt, inv_rotation);
				col += 1.4*float3(0.7, 0.7, 0.4)*clamp(lensFlare(p, -proj.xy / proj.z*zoom)*proj.z, 0., 1.);

				float g = smoothstep(0.03, .97, mo.x);
				col = lerp(lerp(col, col.brg*float3(1, 0.75, 1), clamp(g*2., 0.0, 1.0)), col.bgr, clamp((g - 0.5)*2., 0.0, 1.));

				col = clamp(col, 0., 1.);
				col = col * 0.5 + 0.5*col*col*(3.0 - 2.0*col); //saturation
				col = pow(col, float3(0.416667, 0.416667, 0.416667))*1.055 - 0.055; //sRGB
				col *= pow(16.0*q.x*q.y*(1.0 - q.x)*(1.0 - q.y), 0.12); //Vign

				return fixed4(col, 1.0);

				//return fixed4(0.0,1.0,0.0,1.0);
			}

			fixed4 frag(v2f i) : SV_Target
			{
				// sample the texture
				//fixed4 col = tex2D(_NoiseTex, i.uv);
				fixed4 col = fixed4(0,0,0,0);
				// apply fog
				UNITY_APPLY_FOG(i.fogCoord, col);

				//raymarching
				col = mainImage(i.screenpos.xy);

				return col;
			}

			//--------------------------------------------------------------------------------
            ENDCG
        }
    }
}
