Shader "AEON_Base_Texture" 
{
	Properties  
	{
		_DiffuseAmount ( "Diffuse Amount", Range( 0.0, 0.25 ) ) = 0.25
		_TexAmount ( "Texture Amount", Range( 0.0, 1.0 ) ) = 0.25
		_SpecAmount ( "Specular Amount", Range( 0.0, 48.0 ) ) = 1.0
		_SpecTexAmount ( "Spec Texture Amount", Range( 0.0, 1.0 ) ) = 0.25
		_MainMap ( "Main Texture", 2D ) = "main" {}
		_Normalmap ( "Normalmap", 2D ) = "normal" {}
		_Specmap ( "Specmap", 2D ) = "spec" {}
		
		_FresnelPower ( "Fresnel Power", Range( 0.0, 16.0 ) ) = 8.0
		_FresnelPrimarySecondary ( "Primary/Secondary Fresnel Degree", Range( 0.0, 1.0 ) ) = 1.0
		_FresnelTertiary ( "Fresnel Tertiary Infusion", Range( 0.0, 0.25 ) ) = 0.25
		_FresnelBoost ( "Fresnel Boost", Range( 1.0, 2.0 ) ) = 0.0
		_FresnelBalance ( "Fresnel Balance", Range( 0.0, 0.25 ) ) = 0.25
		_FresnelEmitColor ( "Fresnel Emit Color", Color ) = ( 0.89, 0.945, 1.0, 0.0 )
		
		_PrimarySecondary ( "Primary/Secondary Degree", Range( 0.0, 1.0 ) ) = 1.0
		_Tertiary ( "Tertiary Infusion", Range( 0.0, 0.25 ) ) = 0.25
		_Gloss ( "Gloss", Range( 0.0, 2.0 ) ) = 1.0
	}
	    
	SubShader 
	{
        Tags
        {
          "Queue"="Geometry+0" 
          "IgnoreProjector"="False"
          "RenderType"="Opaque"
        }

        Cull Back
        ZWrite On
        ZTest LEqual

		CGPROGRAM
		#pragma target 3.0 
		#pragma surface surf SimpleSpecular novertexlights fullforwardshadows
		//fullforwardshadows approxview dualforward
		
		float _Gloss;
		float _PrimarySecondary;
		fixed _Tertiary;
		
		fixed CalculateSpecular( fixed3 lDir, fixed3 vDir, fixed3 norm, float gloss )
		{	 
			float3 halfVector = normalize( lDir + vDir );
			float specDot = saturate( dot( halfVector, norm ) );
			
			float primaryBlob = pow( specDot, _Gloss * 128.0 );
			float secondaryBlob = pow( specDot, _Gloss * 16.0 );
			float tertiaryBlob = pow( specDot, _Gloss * 8.0 );
			float tripleSpec = lerp( primaryBlob, secondaryBlob, _PrimarySecondary ) + tertiaryBlob * _Tertiary;

			return tripleSpec * gloss;
		}
		
		fixed4 LightingSimpleSpecular( SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed atten ) 
		{
			fixed diff = saturate( dot( s.Normal, lightDir ) );
			fixed spec = CalculateSpecular( lightDir, viewDir, s.Normal, s.Gloss ) * s.Specular;
			
			fixed4 c;
			c.rgb = ( s.Albedo * _LightColor0.rgb * diff + _LightColor0.rgb * spec ) * atten;
			c.a = s.Alpha;
			
			return c;
		}
		
		fixed4 LightingSimpleSpecular_DirLightmap( SurfaceOutput s, fixed4 color, fixed4 scale, fixed3 viewDir, bool surfFuncWritesNormal, out fixed3 specColor ) 
		{
			UNITY_DIRBASIS
			half3 scalePerBasisVector;
			
			half3 lm = DirLightmapDiffuse( unity_DirBasis, color, scale, s.Normal, surfFuncWritesNormal, scalePerBasisVector );
			half3 lightDir = normalize( scalePerBasisVector.x * unity_DirBasis[0] + scalePerBasisVector.y * unity_DirBasis[1] + scalePerBasisVector.z * unity_DirBasis[2 ]);
			
			specColor = lm * CalculateSpecular( lightDir, viewDir, s.Normal, s.Gloss ) * s.Specular;
			
			return half4( lm * 0.5, 1.0 ); 
		}
		
		struct Input 
		{
			float2 uv_MainMap;
			float2 uv_Normalmap;
			float2 uv_Specmap;
            float3 viewDir;
		};
	
 		sampler2D _MainMap;
	 	sampler2D _Normalmap;
	 	sampler2D _Specmap; 

		fixed _SpecAmount;
		fixed _SpecTexAmount; 
		fixed _TexAmount;
		fixed _DiffuseAmount;
		
		float _FresnelPower;
		float _FresnelPrimarySecondary;
		float _FresnelTertiary;
		float _FresnelBoost;
		
        float4 _FresnelEmitColor;
		float _FresnelBalance;

		void surf( Input IN, inout SurfaceOutput o ) 
		{
			o.Normal = UnpackNormal( tex2D( _Normalmap, IN.uv_Normalmap ) );
		
			float fresnelDot = 1.0 - saturate( dot( normalize( IN.viewDir ), o.Normal ) );
			float fresnelPrimaryBlob = pow( fresnelDot, _FresnelPower * 2.0 );
			float fresnelSecondaryBlob = pow( fresnelDot, _FresnelPower );
			float fresnelTertiaryBlob = pow( fresnelDot, _FresnelPower * 0.5 );
			float fresnel = lerp( fresnelPrimaryBlob, fresnelSecondaryBlob, _FresnelPrimarySecondary ) + fresnelTertiaryBlob * _FresnelTertiary;
			fresnel *= _FresnelBoost;
		
			float tex = lerp( tex2D( _MainMap, IN.uv_MainMap ).r, 1.0, _TexAmount );
			o.Albedo = _DiffuseAmount * tex;
			o.Emission = fresnel * _FresnelEmitColor;
			o.Specular = lerp( tex2D( _Specmap, IN.uv_Specmap ).r, 1.0, _SpecTexAmount ) * _SpecAmount;
			o.Gloss = lerp( fresnel, 1.0, _FresnelBalance );
		}
	
		ENDCG
	} 
	    
	Fallback "Diffuse"
}