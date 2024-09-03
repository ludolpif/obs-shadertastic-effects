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
uniform float porch;
uniform bool reverse;
uniform int wanted_ease_func;
uniform int wanted_visual_test;
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

#define PI  3.14159265359
#define TAU 6.28318530718
#define PI_HALF 1.5707963268

float ease_in_sine(float x) {
    return 1.0 - cos(PI_HALF*x); // FIXME make less dumb maths
}
float ease_out_sine(float x) {
    return sin(PI_HALF*x);
}
float ease_in_out_sine(float x) {
    return (1.0 - cos(PI*x)) / 2.0; // FIXME make less dumb maths
}
float ease_in_quad(float x) {
    return x*x;
}
float ease_out_quad(float x) {
    float w = 1.0-x;
    return 1.0-w*w;
}
float ease_in_out_quad(float x) {
    //return x < 0.5 ? 2 * x * x : 1 - Math.pow(-2 * x + 2, 2) / 2;
    return 0.5; // FIXME make less dumb maths
}
float ease_in_cubic(float x) {
    return x*x*x;
}
float ease_out_cubic(float x) {
    float w = 1.0-x;
    return 1.0-w*w*w;
}

float4 visual_test(float2 uv, float4 rgba, float ez) {
    // Animate the output
    bool inside = false;
    if ( wanted_visual_test == 0 ) {
        // sizes
        float2 uv_sym = (uv-0.5)*2.0;
        float2 p2 = 1.0-float2(ez,ez);
        float2 p1 = -p2;
        inside = inside_box(uv_sym, p1, p2);
    } else if ( wanted_visual_test == 1 ) {
        // positions
        inside = 1.0-uv[0] > ez;
    } else {
        // transparencies
        rgba.a = 0.5 + ez*0.5;
    }

    return inside?float4(rgba.rgb*0.5, 1.0):rgba;
}

float4 EffectLinear(float2 uv)
{
    // Lets note: ez = tested_easing_function(t);
    float ez;
    // Set t as a repeating linear time progression from 0.0 to 1.0 with a pause at begining and at the end
    float t = clamp(fmod(time*4.0,1.0+porch*2.0)-porch, 0.0, 1.0);
    t = reverse?1.0-t:t;

    // Get the current source pixel
    float4 rgba = image.Sample(textureSampler, uv);

    // Split screen to compare easing function with linear function
    float2 uv_split = uv;
    if ( wanted_visual_test == 0 ) {
        uv_split *= float2(2.0,1.0); // vertical (side-by-side) split
    } else {
        uv_split *= float2(1.0,2.0); // horizontal (top vs bottom) split
    }

    if ( fmod(uv_split,1.0) == uv_split ) {
        // Apply the easing function
        if      ( wanted_ease_func == 1 ) { ez = ease_in_sine(t); }
        else if ( wanted_ease_func == 2 ) { ez = ease_out_sine(t); }
        else if ( wanted_ease_func == 3 ) { ez = ease_in_out_sine(t); }
        else if ( wanted_ease_func == 4 ) { ez = ease_in_quad(t); }
        else if ( wanted_ease_func == 5 ) { ez = ease_out_quad(t); }
        else if ( wanted_ease_func == 6 ) { ez = ease_in_out_quad(t); }
        else if ( wanted_ease_func == 7 ) { ez = ease_in_cubic(t); }
        else if ( wanted_ease_func == 8 ) { ez = ease_out_cubic(t); }
        else { ez = t; }
        // Demonstrate the easing function 
        rgba = visual_test(uv_split, rgba, ez);
    } else {
        // Demonstrate the linear case
        rgba = visual_test(fmod(uv_split,1.0), rgba, t);
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
