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
uniform bool should_print_grid;
uniform bool should_print_font_test;
uniform float debug_value;
uniform float font_size;
uniform int coord_mode;
uniform float pixel_u;
uniform float pixel_v;
uniform int pixel_x;
uniform int pixel_y;

#include "../../shadertastic-lib/debug/print_glyph.hlsl"
#include "../../shadertastic-lib/debug/decode_int.hlsl"
#include "../../shadertastic-lib/debug/decode_float.hlsl"
#include "../../shadertastic-lib/debug/print_values.hlsl"
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

float4 EffectLinear(float2 uv)
{
    float4 color_red  = float4(1.0,0.0,0.0,1.0);
    float4 color_cyan = float4(0.0,1.0,1.0,1.0);

    float2 uv_pixel_to_debug = (coord_mode==0)?float2(pixel_u,pixel_v):float2(pixel_x*upixel, pixel_y*vpixel);

    float4 rgba_pixel_to_debug = image.Sample(textureSampler, uv_pixel_to_debug);
    float4 rgba = image.Sample(textureSampler, uv);

    // First example : print a uniform variable with 3 decimals at top right corner of the image
    // (note : you can't print value that depends on pixel shader's uv)
    if ( printValue(uv, font_size, float2(1.0, 0.0), 3, font_size) ) {
        return color_cyan;
    }
    // Second example : print an RGBA value, note: this one returns a color, not a boolean
    float4 dbg = printRGBA(uv, rgba_pixel_to_debug, float2(1.0, 1.0*font_size), 1, font_size);
    rgba = lerp(rgba, dbg, dbg.a);

    // Display a red 3x3 pixel square around the pixel to debug, preserving the center pixel
    float2 uv_pixel = float2(upixel, vpixel);
    if ( inside_box(uv, uv_pixel_to_debug, uv_pixel_to_debug+uv_pixel ) ) {
        return rgba;
    }
    float2 uv_line_width = uv_pixel * 1.0;
    if ( inside_box(uv, uv_pixel_to_debug-uv_line_width, uv_pixel_to_debug+uv_pixel+uv_line_width) ) {
        return color_red;
    }

    // Display a zoomed area with a red border and filled with the color value of the pixel to debug
    float2 zoomed_center = (uv_pixel_to_debug - float2(0.5,0.5))/2.0 + float2(0.5, 0.5);
    float2 zoomed_topLeft = zoomed_center - 32.0*uv_pixel;
    float2 zoomed_bottomRight = zoomed_center + 32.0*uv_pixel;
    if ( inside_box(uv, zoomed_topLeft, zoomed_bottomRight) ) {
        return rgba_pixel_to_debug;
    }
    if ( inside_box(uv, zoomed_topLeft-uv_line_width, zoomed_bottomRight+uv_line_width) ) {
        return color_red;
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
