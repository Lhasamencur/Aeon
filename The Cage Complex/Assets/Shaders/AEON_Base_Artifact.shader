Shader "AEON_Base_Artifact" 
{
	Properties  
	{
		_SpecAmount ( "Specular Amount", Range( 0.0, 48.0 ) ) = 1.0
		_SpecTexAmount ( "Spec Texture Amount", Range( 0.0, 1.0 ) ) = 0.25
		_Normalmap ( "Normalmap", 2D ) = "normal" {}
		_Specmap ( "Specmap", 2D ) = "spec" {}
		
		_DataTex ( "Data Artifact", 2D ) = "black" {}
		_Rate ( "Artifact Rate", float ) = 2.0
		_Screeny_rate ( "Screen Rate", float ) = 6.0
		_WarpScale ( "Warp Scale", range( 0, 4 ) ) = 0.5
		_WarpOffset ( "Warp Offset", range( 0, 0.5 ) ) = 0.5
		
		_FresnelPower ( "Fresnel Power", Range( 0.0, 16.0 ) ) = 8.0
		_FresnelPrimarySecondary ( "Primary/Secondary Fresnel Degree", Range( 0.0, 1.0 ) ) = 1.0
		_FresnelBoost ( "Fresnel Boost", Range( 1.0, 2.0 ) ) = 0.0
		_FresnelBalance ( "Fresnel Balance", Range( 0.0, 0.0625 ) ) = 0.25
		_FresnelEmitColor ( "Fresnel Emit Color", Color ) = ( 0.89, 0.945, 1.0, 0.0 )
		
		_PrimarySecondary ( "Primary/Secondary Degree", Range( 0.0, 1.0 ) ) = 1.0
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
		#pragma surface surf SimpleSpecular vertex:vert novertexlights
		#pragma glsl
		//fullforwardshadows approxview dualforward
		
		float _Gloss;
		float _PrimarySecondary;
		
		fixed CalculateSpecular( fixed3 lDir, fixed3 vDir, fixed3 norm, float gloss )
		{	 
			float3 halfVector = normalize( lDir + vDir );
			float specDot = saturate( dot( halfVector, norm ) );
			
			float primaryBlob = pow( specDot, _Gloss * 128.0 );
			float secondaryBlob = pow( specDot, _Gloss * 16.0 );
			float tripleSpec = lerp( primaryBlob, secondaryBlob, _PrimarySecondary );

			return tripleSpec * gloss;
		}
		
		fixed4 LightingSimpleSpecular( SurfaceOutput s, fixed3 lightDir, fixed3 viewDir, fixed atten ) 
		{
			fixed spec = CalculateSpecular( lightDir, viewDir, s.Normal, s.Gloss ) * s.Specular;
			
			fixed4 c;
			c.rgb = ( _LightColor0.rgb * spec ) * atten;
			c.a = s.Alpha;
			
			return c;
		}
	
	 	sampler2D _Normalmap;
	 	sampler2D _Specmap; 

		fixed _SpecAmount;
		fixed _SpecTexAmount; 
		
		float _FresnelPower;
		float _FresnelPrimarySecondary;
		float _FresnelBoost;
		
        float4 _FresnelEmitColor;
		float _FresnelBalance;
		
		sampler2D _DataTex;
		
		float _WarpScale;
		float _WarpOffset;
		float _Rate;
		float _Screeny_rate;
		
		struct Input 
		{
			float2 uv_Normalmap;
			float2 uv_Specmap;
            
			float4 pos : POSITION;
			float4 dataUV : TEXCOORD1;
			float3 viewDir;
		};

		void vert ( inout appdata_full v, out Input o )
		{
		    float4 pos = mul( UNITY_MATRIX_MVP, v.vertex );
		    float2 screenuv = pos.xy / pos.w;
		    screenuv.y += _Time.x * _Screeny_rate;
			
			o.dataUV = float4( screenuv.x, screenuv.y, 0, 0 );
			float4 tex = tex2Dlod( _DataTex, o.dataUV );
			
			float3 warp = float3(
				sin( v.normal.x*tex.r*v.vertex.x),
				atan( v.normal.y*tex.g*v.vertex.y),
				cos( v.normal.z*tex.b*v.vertex.z)
			);
			
			float dist = distance( v.vertex.xyz, v.vertex.xyz + warp );
			v.vertex.xyz = lerp( v.vertex.xyz + warp * _WarpScale, v.vertex.xyz + _WarpOffset * sin( _Time.x * _Rate ), dist );
		}

		void surf( Input IN, inout SurfaceOutput o ) 
		{
			o.Normal = UnpackNormal( tex2D( _Normalmap, IN.uv_Normalmap ) );
		
			float fresnelDot = 1.0 - saturate( dot( normalize( IN.viewDir ), o.Normal ) );
			float fresnelPrimaryBlob = pow( fresnelDot, _FresnelPower * 2.0 );
			float fresnelSecondaryBlob = pow( fresnelDot, _FresnelPower );
			float fresnel = lerp( fresnelPrimaryBlob, fresnelSecondaryBlob, _FresnelPrimarySecondary );
			fresnel *= _FresnelBoost;
			
			float spec = lerp( tex2D( _Specmap, IN.uv_Specmap ).r, 1.0, _SpecTexAmount );
			o.Emission = fresnel * _FresnelEmitColor * spec;
			o.Specular = spec * _SpecAmount;
			o.Gloss = lerp( fresnel, 1.0, _FresnelBalance );
		}
	
		ENDCG
	} 
	    
	Fallback "Diffuse"
}