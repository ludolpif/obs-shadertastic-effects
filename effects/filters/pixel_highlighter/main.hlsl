// Common parameters for all shaders, as reference. Do not uncomment this (but you can remove it safely).
/*
uniform float time;            // Time since the shader is running. Goes from 0 to 1 for transition effects; goes from 0 to infinity for filter effects
uniform texture2d image;       // Texture of the source (filters only)
uniform texture2d tex_interm;  // Intermediate texture where the previous step will be rendered (for multistep effects)
uniform float upixel;          // Width of a pixel in the UV space
uniform float vpixel;          // Height of a pixel in the UV space
uniform float rand_seed;       // Seed for random functions
uniform int current_step;      // index of current step (for multistep effects)
*/

// Specific parameters of the shader. They must be defined in the meta.json file next to this one.
uniform float luma_min;
uniform float luma_max;

//----------------------------------------------------------------------------------------------------------------------

// These are required objects for the shader to work.
// You don't need to change anything here, unless you know what you are doing
sampler_state textureSampler {
    Filter    = Linear;
    AddressU  = Clamp;
    AddressV  = Clamp;
};

struct VertData {
    float2 uv  : TEXCOORD0;
    float4 pos : POSITION;
};

struct FragData {
    float2 uv  : TEXCOORD0;
};

VertData VSDefault(VertData v_in)
{
    VertData vert_out;
    vert_out.uv  = v_in.uv;
    vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
    return vert_out;
}
//----------------------------------------------------------------------------------------------------------------------
// manual embed includes from (work in progress) shadertastic-lib for now

//#include "../../shadertastic-lib/color_conversion/rgb2xyz.hlsl"
#ifndef _RGB2XYZ_HLSL
#define _RGB2XYZ_HLSL

// Function to convert RGB to XYZ
float3 rgb2xyz(float3 rgb)
{
    float3 result;
    result.r = 0.4124564 * rgb.r + 0.3575761 * rgb.g + 0.1804375 * rgb.b;
    result.g = 0.2126729 * rgb.r + 0.7151522 * rgb.g + 0.0721750 * rgb.b;
    result.b = 0.0193339 * rgb.r + 0.1191920 * rgb.g + 0.9503041 * rgb.b;
    return result;
}

#endif /* _RGB2XYZ_HLSL */
//#include "../../shadertastic-lib/color_conversion/xyz2lab.hlsl"
#ifndef _XYZ2LAB_HLSL
#define _XYZ2LAB_HLSL

// Function to convert XYZ to Lab*
float3 xyz2lab(float3 xyz)
{
    float3 result;
    float epsilon = 0.008856;
    float kappa = 903.3;

    float3 xyzn = float3(0.9505, 1.0, 1.0890); // D50 reference white point

    float3 xyzRatio = xyz / xyzn;
    float3 fxyz = float3(
        pow(xyzRatio.x, 1.0 / 3.0),
        pow(xyzRatio.y, 1.0 / 3.0),
        pow(xyzRatio.z, 1.0 / 3.0)
    );

    result.x = 116.0 * fxyz.y - 16.0;
    result.y = 500.0 * (fxyz.x - fxyz.y);
    result.z = 200.0 * (fxyz.y - fxyz.z);

    return result;
}

#endif /* _XYZ2LAB_HLSL */
//#include "../../shadertastic-lib/color_conversion/rgb2lab.hlsl"
#ifndef _RGB2LAB_HLSL
#define _RGB2LAB_HLSL

// Function to convert RGB to Lab*
float3 rgb2lab(float3 rgb)
{
    return xyz2lab(rgb2xyz(rgb));
}

#endif /* _RGB2LAB_HLSL */

//----------------------------------------------------------------------------------------------------------------------

/*
 * Source: the Y component in BT709: https://www.itu.int/rec/R-REC-BT.709-1-199311-S/en
 * Derivation of luminance signal E′ = 0.2126 RE′ + 0.7152 GE′ + 0.0722 BE′
 * Where prime refers to non-linear signals.
 */
float rgb2lum_rec709(float3 rgb) {
	 return 0.2126 * rgb.r + 0.7152 * rgb.g + 0.0722 * rgb.b;
}

float4 EffectLinear(float2 uv)
{
    // get current pixel rgb color (+alpha) by sampling the image texture2d at location given by uv
	float4 rgba = image.Sample(textureSampler, uv);
    // compute luminance of this color (assuming that we got a non-linear rgb value in [0.0;1.0]³
	//float3 lab = rgb2lab(rgba.rgb);
	//float lum = lab[0];
 
    // less accurate but simpler compute of the luminance of this color
	float lum = rgb2lum_rec709(rgba.rgb);
	
    // blink will containt original orinal half of the time, and inverted color the other half
	float3 blink = fract(time*10.0)>0.5?rgba.rgb:1.0-rgba.rgb;
	
    // Replace source image color by blink if the are in the luminance range choosen by the user
	if ( lum * 100.0 > luma_min && lum * 100.0 < luma_max) {
		rgba = float4(blink, 1.0);
	}

	return rgba;
}
//----------------------------------------------------------------------------------------------------------------------

// You probably don't want to change anything from this point.

float4 PSEffect(FragData f_in) : TARGET
{
    float4 rgba = EffectLinear(f_in.uv);
    return rgba;
}

technique Draw
{
    pass
    {
        vertex_shader = VSDefault(v_in);
        pixel_shader = PSEffect(f_in);
    }
}
