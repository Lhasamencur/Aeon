Shader "Rimlight_Base"
{  
        Properties
        {
				_DiffuseAmount ( "Diffuse Amount", Range( 0.0, 1.0 ) ) = 0.25
        		_Normalmap ( "Normalmap", 2D ) = "normal" {}
                _RimColor( "Rim Color", Color ) = ( 0.89, 0.945, 1.0, 0.0 )
				_FresnelPower ( "Fresnel Power", Range( 0.0, 8.0 ) ) = 8.0
				_FresnelSelection ( "Fresnel Selection", Range( 0.0, 1.0 ) ) = 1.0
        }      
   
        SubShader
        {
	        Tags
	        {
	          "Queue" = "Geometry"
	          "IgnoreProjector" = "True"
	          "RenderType" =  "Opaque"
	        }
	
	        Cull Back
	        ZWrite On
	        ZTest LEqual
	
			CGPROGRAM
			#pragma target 3.0 
			#pragma surface surf Lambert
   
            struct Input
            {
                float3 viewDir;
				float2 uv_Normalmap;
			};
		
		 	sampler2D _Normalmap;
			float3 _RimColor;
            float _FresnelPower;
            float _FresnelSelection;
			fixed _DiffuseAmount;
   
            void surf( Input IN, inout SurfaceOutput o )
            {
                    o.Albedo = _DiffuseAmount;
					o.Normal = UnpackNormal( tex2D( _Normalmap, IN.uv_Normalmap ) );
                    
					float fresnelDot = 1.0 - saturate( min( 1.0, dot( IN.viewDir, o.Normal ) ) );
				
					float primaryBlob = pow( fresnelDot, _FresnelPower * 2.0 );
					float secondaryBlob = pow( fresnelDot, _FresnelPower * 1.0 );
					
                    o.Emission = secondaryBlob;//lerp( primaryBlob, secondaryBlob, _FresnelSelection ) * _RimColor; 
            }
            
            ENDCG
        }
        
        Fallback "Diffuse"
}