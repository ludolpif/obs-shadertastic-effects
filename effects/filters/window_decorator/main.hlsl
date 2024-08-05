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
uniform texture2d deco_tex;
uniform float deco_scale;

/* #include "../../shadertastic-lib/geometry/inside_box.hlsl" */
#ifndef _INSIDE_BOX_HLSL
#define _INSIDE_BOX_HLSL
/**
 * Returns true if v is included in the rectangle defined by left_top (inclusive) and right_bottom (exclusive)
 * Alternative definition : with left_top.x <= right_bottom.x and left_top.y <= right_bottom.y,
 *  it returns ( left_top.x <= v.x < right_bottom.x && left_top.y <= v.y < right_bottom.y )
 * Behavior on limits is tricky if left_top.x > right_bottom.x or left_top.y > right_bottom.y
 * @param v coordinates of a point to test
 * @param left_top coordinates of the top left corner of the rectangle
 * @param right_bottom coordinates of the bottom right corner of the rectangle
 */
bool inside_box(float2 v, float2 left_top, float2 right_bottom) {
    float2 s = step(left_top, v) - step(right_bottom, v);
    return s.x * s.y != 0.0;
}
#endif /* _INSIDE_BOX_HLSL */

//----------------------------------------------------------------------------------------------------------------------

// These are required objects for the shader to work.
// You don't need to change anything here, unless you know what you are doing
sampler_state textureSampler {
    Filter    = Linear;
    AddressU  = Clamp;
    AddressV  = Clamp;
};

struct VertDataIn {
    float2 uv  : TEXCOORD0;
    float4 pos : POSITION;
};

struct VertDataOut {
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
    float4 pos : POSITION;
};

struct FragData {
    float2 uv : TEXCOORD0;
    float2 uv1 : TEXCOORD1;
    float2 uv2 : TEXCOORD2;
};

/* Marche pas dans OBS
float2 dim(Texture2D textureObj)
{
	uint width;
	uint height;
	textureObj.GetDimensions(width, height);
	return float2(width, height);
}*/

VertDataOut VSWithBorders(VertDataIn v_in)
{
    VertDataOut vert_out;
    float2 image_dim = float2(1920.0,1080.0);
    float2 deco_dim = float2(339.0,179.0);
    float2 deco_scaled = deco_dim * deco_scale;
    float2 total_dim = image_dim + deco_scaled;
    float2 total_ratio = total_dim/image_dim;
    float2 deco_ratio = deco_scaled/image_dim;

    float4 v_interm_pos = float4(v_in.pos.xyz,1.0);
    v_interm_pos.xy = (v_interm_pos.xy - deco_scaled/2.0) * total_ratio;

    float4x4 vp = ViewProj;
    vp[1][3] = 0.0; // translation on y-axis on OBS linux
    vp[0][3] = 0.5; // translation on x-axis on OBS linux
    vert_out.pos = mul(v_interm_pos, vp);

    vert_out.uv = (v_in.uv - deco_ratio/2.0) * total_ratio;
    vert_out.uv1 = v_in.uv / deco_ratio;
    vert_out.uv2 = v_in.uv / deco_ratio - 1.0; // FIXME  make the real calculus

    return vert_out;
}


float4 EffectLinear(float2 uv, float2 uv1, float2 uv2)
{
    float2 deco_uv;
    bool isOuter = !inside_box(uv, float2(0.0,0.0), float2(1.0,1.0) );
    if ( isOuter ) {
        // We are on a pixel that is part of the decoration border
        if ( uv[0] < 0.0 ) {
            deco_uv[0] = uv1[0];
        } else if ( uv[0] < 1.0 ) {
            deco_uv[0] = 0.5;
        } else {
            deco_uv[0] = uv2[0];
        }
        if ( uv[1] < 0.0 ) {
            deco_uv[1] = uv1[1];
        } else if ( uv[1] < 1.0 ) {
            deco_uv[1] = 0.5;
        } else {
            deco_uv[1] = uv2[1];
        }
    }
    // StackOverflow advises that we should never conditionnaly call tex.Sample()
    float4 rgba = image.Sample(textureSampler, uv);
    float4 col = deco_tex.Sample(textureSampler, deco_uv);
    if ( isOuter ) {
        rgba = col;
    }
    return rgba;
}
// You probably don't want to change anything from this point.

float4 PSEffect(FragData f_in) : TARGET
{
    float4 rgba = EffectLinear(f_in.uv, f_in.uv1, f_in.uv2);
    return rgba;
}

technique Draw
{
    pass
    {
        vertex_shader = VSWithBorders(v_in);
        pixel_shader = PSEffect(f_in);
    }
}
