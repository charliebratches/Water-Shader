Shader "Custom/waterRipple"
{
    Properties
    {
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
		_MaskTex ("Mask Texture (RGB)", 2D) = "white" {}
		[Normal] _MaskNormal ( "Normal Mask map", 2D ) = "bump" {}
		_MaskNormalScale ( "Mask Normal strenght", Float ) = 1.0
		_MaskScrollAmount("Mask Scroll Amount", Range(0,1.0)) = 0
		_Color ("Color", Color) = (1,1,1,1)
		_Glossiness ("Smoothness", Range(0,1)) = 0.5
		_Metallic ("Metallic", Range(0,1)) = 0.0
		[Header (Ripple Settings)]
		_Scale ("Scale", float) = 1
		_Speed ("Speed", float) = 1
		_Frequency ("Frequency", float) = 1
		[Header (Fade Settings)]
		_InvFade ("Intersection Fade Amount", Range(0.01,3.0)) = 1.0
		_FadeSat ("Fade Saturation Amount", Range(0,1.0)) = 0.1
		_FadeFogginess ("Fade Fogginess", Range(0,1.0)) = 0.1
		_FadeLength("Fade Length", Range(0, 64.0)) = 1
		_MaskFadeLength("Texture Mask Fade Length", Range(0, 30.0)) = 1
		_GlowColor ("Glow Color", Color) = (1,1,1,1)
		_GlowStength("Glow Strength", Range(0,1.0)) = 0
		[Header  (Refraction Settings)]
		[Header (Color)]
		_DarkColor ("Dark water color",  Color) = (0,0,0,1)

		[Header (Fresnel)]
		_FPower ("Fresnel power", Range (0.001, 10.0)) = 5.0
		_FScale ("Fresnel scale", Range (0.0, 1.0)) = 1.0
		_FBias ("Fresnel bias", Range(0.0, 1.0)) = 0.0

		[Header (Dissortion)]
		_DissortAmt ( "Dissortion amount", Range (0.0, 1.0) ) = 0.3
		[Normal] _BumpMap ( "Normal dissortion map", 2D ) = "bump" {}
		_BumpScale ( "Normal strenght", Float ) = 1.0

		_SpeedX ( "Waves speed (X)", float ) = 0.5
		_SpeedY ( "Waves speed (Y)", float ) = 0.5
    }

	CGINCLUDE
	// Some helpers
	#define DISSORTION_MAX 127
	#define SPEED_UV(c) _Time.c * float2(_SpeedX, _SpeedY)
	#define TEX(name) tex2D(name, IN.uv##name)
	ENDCG

    SubShader
    {
        Blend SrcAlpha OneMinusSrcAlpha
		Cull Off

        Tags
        {
            "RenderType" = "Transparent+1"
            "Queue" = "Transparent"
        }

		GrabPass { }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard alpha nolightmap noshadow vertex:vert
		// #pragma surface surf Standard alpha nolightmap noshadow vertex:vert
        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0


        sampler2D _MainTex;
		sampler2D _MaskTex;

		float _Scale, _Speed, _Frequency;

		half _Glossiness;
        half _Metallic;
        fixed4 _Color;

		sampler2D _CameraDepthTexture;
		
		uniform float _WaveAmplitude[100];
		uniform float _WaveAmplitudeArray;

		uniform float _OffsetX[100];
		uniform float _OffsetXArray;

		uniform float _OffsetZ[100];
		uniform float _OffsetZArray;

		uniform float _Distance[100];
		uniform float _DistanceArray;

		uniform float _xImpact[100];
		uniform float _xImpactArray;

		uniform float _zImpact[100];
		uniform float _zImpactArray;

		uniform sampler2D _GrabTexture;
		uniform float4 _GrabTexture_TexelSize;

		uniform fixed4 _DarkColor;

		uniform float _FPower;
		uniform float _FScale;
		uniform float _FBias;

		uniform float _DissortAmt;
		uniform sampler2D _BumpMap;
		uniform float _BumpScale;
		uniform float _MaskScrollAmount;
		uniform sampler2D _MaskNormal;
		uniform float _MaskNormalScale;

		uniform float _SpeedX;
		uniform float _SpeedY;

		float _InvFade;
		float _FadeSat;
		float _FadeFogginess;
		float _FadeLength;
		float _MaskFadeLength;
		float _GlowStength;
		fixed4 _GlowColor;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)


        struct Input {
            float2 uv_MainTex;
			float2 uv_MaskTex;
            float3 rippleNormal;
			float eyeDepth;
			float4 screenPos;
			float2 uv_BumpMap;
			float2 uv_MaskNormal;
			float3 viewDir;
			float3 worldPos;
        };

		void vert ( inout appdata_full v, out Input o )
		{
			UNITY_INITIALIZE_OUTPUT(Input, o);
			COMPUTE_EYEDEPTH(o.eyeDepth);
			half offsetvert = ((v.vertex.x * v.vertex.x) + (v.vertex.z * v.vertex.z));
			float3 worldPos = mul (unity_ObjectToWorld, v.vertex).xyz;

			for(int i=0; i<_WaveAmplitudeArray; i++){
				half value = _Scale * sin(_Time.w * -_Speed * _Frequency + offsetvert + (v.vertex.x * _OffsetX[i]) + (v.vertex.z * _OffsetZ[i]));
				if (sqrt(pow(worldPos.x - _xImpact[i], 2) + pow(worldPos.z - _zImpact[i], 2)) < _Distance[i])
				{
					v.vertex.y += value * _WaveAmplitude[i];
					v.normal.xyz += value * _WaveAmplitude[i];
					o.rippleNormal = value * _WaveAmplitude[i];
				}
			}
		}

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
			// Edge Intersection
			float sceneZ2 = LinearEyeDepth(SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos)));
            float surfZ = -mul(UNITY_MATRIX_V, float4(IN.worldPos.xyz, 1)).z;
            float diff = sceneZ2 - surfZ;
            float intersect = 1 - saturate(diff / _FadeLength);
			float maskIntersect = 1 - (saturate(diff / _MaskFadeLength));
			// Calculate fade amount
			float rawZ = SAMPLE_DEPTH_TEXTURE_PROJ(_CameraDepthTexture, UNITY_PROJ_COORD(IN.screenPos));
            float sceneZ = LinearEyeDepth(rawZ);
            float partZ = IN.eyeDepth;

			float fade = 1.0;
            if ( rawZ > 0.0) // Make sure the depth texture exists
                fade = saturate(_InvFade * (sceneZ - partZ));

			// Calculate Refraction
			// normal bump
			IN.uv_BumpMap += SPEED_UV (xy);
			float3 bump = UnpackScaleNormal (TEX(_BumpMap), _BumpScale);

			// dissorted UVs
			float2 dissort = (bump + IN.rippleNormal) * pow (_DissortAmt * DISSORTION_MAX + 1, 2.0)*2;
			IN.screenPos.xy += (dissort * _GrabTexture_TexelSize.xy) * IN.screenPos.z;

			// ???
			#ifndef UNITY_UV_STARTS_AT_TOP
				IN.screenPos.y = 1 - IN.screenPos.y;
			#endif

			// fresnel amount
			float fresnel;
			fresnel = 1.0 - dot (bump, IN.viewDir);
			fresnel = _FScale * pow (fresnel, _FPower);
			fresnel = _FBias + (1.0 - _FBias) * saturate(fresnel);

			// Compute final fragment color
			half3 frag, emission;
			frag = lerp (tex2Dproj (_GrabTexture, IN.screenPos), _Color, _FadeFogginess).rgb;
			frag = lerp (frag, _Color, (1 * fresnel));
			emission = _Color * (0.1 * fresnel);

			IN.uv_MaskTex += SPEED_UV (xy)*_MaskScrollAmount;
			IN.uv_MaskNormal += SPEED_UV (xy)*_MaskScrollAmount;

            fixed4 c = fixed4(lerp(tex2D (_MainTex, IN.uv_MainTex) * _Color, 
				lerp(_GlowColor, tex2D (_MaskTex, IN.uv_MaskTex) * _GlowColor * (1+ _GlowStength), pow(maskIntersect, 2)), 
				pow(intersect, 4)));

            o.Albedo = c.rgb * fade * frag;
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
			o.Emission = emission;
			
			o.Normal = float3(lerp(bump, UnpackScaleNormal (TEX(_MaskNormal), _MaskNormalScale), pow(maskIntersect, 2)));
			o.Normal.y += IN.rippleNormal;
            o.Alpha = c.a * fade + _FadeSat;
        }

        ENDCG
    }
    FallBack "Diffuse"
}
