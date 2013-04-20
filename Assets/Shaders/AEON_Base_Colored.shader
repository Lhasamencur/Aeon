Shader "AEON_Base_Colored" 
{
	Properties  
	{
		_TexAmount ( "Texture Amount", Range( 0.0, 1.0 ) ) = 0.25
		_TexBoost ( "Texture Boost", Range( 0.0, 2.0 ) ) = 0.0
		_MainMap ( "Main Texture", 2D ) = "main" {}
		_MainColor( "Main Color", Color ) = ( 0.89, 0.945, 1.0, 0.0 )
		_Normalmap ( "Normalmap", 2D ) = "normal" {}
		_Specmap ( "Specmap", 2D ) = "spec" {}
		_AmbientRim ( "Ambient Rim", Range( 0.0, 0.5 ) ) = 0.075
		_FresnelPower ( "Fresnel Power", Range( 0.0, 32.0 ) ) = 8.0
		_FresnelMult ( "Fresnel Multiplier", Range( 0.0, 2.25 ) ) = 0.75
		_FresnelDilute ( "Fresnel Dilute", Range( 0.0, 2.25 ) ) = 0.75
		_PrimaryBlob ( "Primary Blob", Range( 0.0, 1.0 ) ) = 1.0
		_SecondaryBlob ( "Secondary Blob", Range( 0.0, 1.0 ) ) = 0.125
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
		#pragma surface surf SimpleSpecular noambient novertexlights vertex:vert
		//fullforwardshadows approxview
		
		float _Shininess;
		float _Gloss;
		float _AmbientRim;
		float _FresnelPower;
		float _FresnelMult;
		float _FresnelDilute;
		float _PrimaryBlob;
		float _SecondaryBlob;
		float _BRDFAmount;
		float _BRDFRoughnessX;
		float _BRDFRoughnessY;
		float4 _MainColor;
		
		fixed CalculateSpecular( fixed3 lDir, fixed3 vDir, fixed3 norm, fixed spec, fixed3 tangent )
		{	
			float3 halfVector = normalize( lDir + vDir );
			
			float specDot = saturate( dot( halfVector, norm ) );
			float fresnelDot = min( 1.0, dot( vDir, norm ) );
			float rimCore = 1.0 - saturate( fresnelDot );
			
			float rim = rimCore + ( pow( rimCore, _FresnelPower ) * 2.0 );
			rim *= specDot;
			float doubleSpec = ( ( _SecondaryBlob * pow( specDot, _Gloss * 16.0 ) ) + ( pow( specDot, _Gloss * 128.0 ) * _PrimaryBlob ) ) * 2.5;
			
            float SpecularCore = doubleSpec;
			return spec * ( ( rim * _AmbientRim ) + ( _FresnelMult * rim + _FresnelDilute ) * SpecularCore );
		}
		
		fixed4 LightingSimpleSpecular( SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed atten ) 
		{
			fixed diff = saturate( dot( s.Normal, lightDir ) );
			fixed spec = CalculateSpecular( lightDir, viewDir, s.Normal, s.Specular, s.Albedo );
			
			fixed4 c;
			c.rgb = ( _MainColor * s.Gloss * _LightColor0.rgb * diff + _LightColor0.rgb * spec ) * atten;
			
			return c;
		}
		
		fixed4 LightingSimpleSpecular_DirLightmap( SurfaceOutput s, fixed4 color, fixed4 scale, fixed3 viewDir, bool surfFuncWritesNormal, out fixed3 specColor ) 
		{
			UNITY_DIRBASIS
			half3 scalePerBasisVector;
			
			half3 lm = DirLightmapDiffuse( unity_DirBasis, color, scale, s.Normal, surfFuncWritesNormal, scalePerBasisVector ) * _MainColor;
			half3 lightDir = normalize( scalePerBasisVector.x * unity_DirBasis[0] + scalePerBasisVector.y * unity_DirBasis[1] + scalePerBasisVector.z * unity_DirBasis[2 ]);
			
			specColor = lm * CalculateSpecular( lightDir, viewDir, s.Normal, s.Specular, s.Albedo );
			
			return half4( lm * 0.5, 1.0 );
		}
		
		struct Input 
		{
			float3 viewDir;
			float3 tangent;
			float2 uv_MainMap;
			float2 uv_Normalmap;
			float2 uv_Specmap;
			float3 worldNormal; INTERNAL_DATA
		};
	
 		sampler2D _MainMap;
	 	sampler2D _Normalmap;
	 	sampler2D _Specmap;
		fixed _ScaleX;
		fixed _ScaleY;
		fixed _TexAmount;
		fixed _TexBoost;
		
		void vert( inout appdata_full v, out Input o ) 
		{
			UNITY_INITIALIZE_OUTPUT( Input, o );
			o.tangent = v.tangent;
		}
		
		void surf( Input IN, inout SurfaceOutput o ) 
		{
			float tex = lerp( tex2D( _MainMap, IN.uv_MainMap ).r, 1.0 + _TexBoost, _TexAmount );
			o.Albedo = 0.175 * tex;// IN.tangent; // Smuggle Tangent in Albedo;

			o.Normal = UnpackNormal( tex2D( _Normalmap, IN.uv_Normalmap ) );
			o.Gloss = 0.25 * tex; // Smuggle Albedo in Gloss;
			o.Specular = lerp( tex2D( _Specmap, IN.uv_Specmap ).r, 1.0 + _TexBoost, _TexAmount );
		}
	
		ENDCG
	} 
	    
	Fallback "Diffuse"
}