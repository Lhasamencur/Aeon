Shader "Rimlight_Bump" 
{    
	Properties 
	{
		_Normalmap( "Normalmap", 2D ) = "normal" {}
		_RimColor( "Rim Color", Color ) = ( 0.89, 0.945, 1.0, 0.0 )
		_RimPower( "Rim Power", Range( 0.5, 32.0 ) ) = 3.0
		_RimPowerSecondary( "Rim Power - Secondary", Range( 0.5, 32.0 ) ) = 3.0
		_RimLevel( "Rim Level", Range( 0.0, 1.0 ) ) = 0.0
		_RimLevelSecondary( "Rim Level - Secondary", Range( 0.0, 1.0 ) ) = 0.0
		_RimInverse( "Rim Inverse Level", Range( 0.0, 1.0 ) ) = 0.0
		_RimInversePower( "Rim Inverse Power", Range( 0.0, 1.0 ) ) = 3.0
		_HDRBoost( "HDR Boost", Range( 0.0, 10.0 ) ) = 0.25
	}
    
	SubShader 
	{
        Tags { "RenderType"="Opaque" }
        
		//Lighting Off
        
        Pass 
        {
	
			CGPROGRAM
			#pragma target 3.0
			#pragma vertex vert
			#pragma fragment frag
			#pragma fragmentoption ARB_precision_hint_fastest
			 
			#include "UnityCG.cginc"
			
		 	sampler2D _Normalmap;
			
			struct appdata {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float2 texcoord : TEXCOORD0;
			};
	
			struct v2f 
			{
				float4 vertex : POSITION;
				float2 texcoord : TEXCOORD0;
				float3 viewDir : TEXCOORD1;
				float3 normal : TEXCOORD2;
			};
			
			float4 _Normalmap_ST;
			
			v2f vert( appdata v )
			{
				v2f o;
				o.vertex = mul( UNITY_MATRIX_MVP, v.vertex );
				o.viewDir = ObjSpaceViewDir( v.vertex );
				o.texcoord = v.texcoord.xy * _Normalmap_ST.xy + _Normalmap_ST.zw;
				o.normal = v.normal;
				return o;
			}
		    
			float4 _RimColor;
			float _RimPower;
			float _RimLevel; 
			float _RimPowerSecondary;
			float _RimLevelSecondary;
			float _RimInverse;
			float _RimInversePower;
			float _HDRBoost;
			 
			half4 frag( v2f i ) : COLOR 
			{
				half4 col;
				half3 norm = UnpackNormal( tex2D( _Normalmap, i.texcoord ) );
			
				float prim = dot( normalize( i.viewDir ), i.normal );
				float rim = 1.0 - saturate( prim );
				float rimpower = pow( rim, _RimPower ) * _RimLevel;
				rimpower += pow( rim, _RimPowerSecondary ) * _RimLevelSecondary;
				
				col.xyz = _RimColor.rgb * ( rimpower + pow( prim, _RimInversePower ) * _RimInverse ) * _HDRBoost;
				col.a = 1.0f;
				return col; 
			}
		
			ENDCG
		}
	}
}