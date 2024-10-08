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
uniform int wanted_visual_test;
uniform int wanted_ease_kind;
uniform int wanted_ease_func;
uniform bool reverse;
uniform float curve_ratio;
uniform float porch;
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
#define PI_HALF 1.5707963268

bool inside_1d(float v, float target, float radius) {
    return ( v - target >= -radius ) && ( v - target <= radius );
}
float4 draw_curve(float2 uv, float f, float4 color) {
    float x = uv[0];
    float y = 1.0-uv[1];
    float u_px = 2.0*upixel/curve_ratio;
    float v_px = 2.0*vpixel/curve_ratio;

    // Conditions are sorted from foreground to background
    if ( inside_1d(f, y, u_px*3.0) ) {
        // color'ed f function curve
        return color;
    }
    if ( inside_1d(x, 0.5, u_px) || inside_1d(y, 0.5, v_px ) ) {
        // black center lines (at x==0.5 or y==0.5, not at origin)
        return float4(0.0, 0.0, 0.0, 1.0);
    }
    if ( inside_1d(frac(x*10.0), 0.0, u_px*10.0) || inside_1d(frac(y*10.0), 0.0, v_px*10.0 ) ) {
        // gray grid lines
        return float4(0.3, 0.3, 0.3, 1.0);
    }
    if ( inside_1d(x, y, u_px) ) {
        // green y = x linear/identity function
        return float4(0.1, 0.6, 0.2, 1.0);
    }
    // Semi-transparent white graph background
    return float4(1.0, 1.0, 1.0, 0.38);
}


float ease_in_sine(float x) {
    return 1.0 - cos(PI_HALF*x);
}
float ease_out_sine(float x) {
    return sin(PI_HALF*x);
}
float ease_in_out_sine(float x) {
    return (1.0 - cos(PI*x)) / 2.0;
}
float ease_in_quad(float x) {
    //note: pow(x, 2.0) is not defined for x<0.0 as per specification. x*x is always defined.
    return x*x;
}
float ease_out_quad(float x) {
    float w = 1.0-x;
    return 1.0-w*w;
}
float ease_in_out_quad(float x) {
    return x<0.5 ? 0.5 * ease_in_quad(2.0*x) : 0.5 * ease_out_quad(2.0*x-1.0) + 0.5;
}
float ease_in_cubic(float x) {
    float x2=x*x;
    return x2*x;
}
float ease_out_cubic(float x) {
    float w = 1.0-x;
    float w2 = w*w;
    return 1.0-w2*w;
}
float ease_in_out_cubic(float x) {
    return x<0.5 ? 0.5 * ease_in_cubic(2.0*x) : 0.5 * ease_out_cubic(2.0*x-1.0) + 0.5;
}
float ease_in_quart(float x) {
    float x2=x*x;
    return x2*x2;
}
float ease_out_quart(float x) {
    float w = 1.0-x;
    float w2 = w*w;
    return 1.0-w2*w2;
}
float ease_in_out_quart(float x) {
    return x<0.5 ? 0.5 * ease_in_quart(2.0*x) : 0.5 * ease_out_quart(2.0*x-1.0) + 0.5;
}
float ease_in_quint(float x) {
    float x2=x*x;
    return x2*x2*x;
}
float ease_out_quint(float x) {
    float w = 1.0-x;
    float w2 = w*w;
    return 1.0-w2*w2*w;
}
float ease_in_out_quint(float x) {
    return x<0.5 ? 0.5 * ease_in_quint(2.0*x) : 0.5 * ease_out_quint(2.0*x-1.0) + 0.5;
}
float ease_in_expo(float x) {
    float w = 1.0-x;
    float p = -10.0*w;
    return x==0.0?0.0:pow(2.0, p);
}
float ease_out_expo(float x) {
    float p = -10.0*x;
    return x==1.0 ? 1.0 : 1.0 - pow(2.0, p);
    //note: wrong edge value seen 2024-09-04 on https://easings.net/#easeOutExpo
}
float ease_in_out_expo(float x) {
    return x<0.5 ? 0.5 * ease_in_expo(2.0*x) : 0.5 * ease_out_expo(2.0*x - 1.0) + 0.5;
}
float ease_in_circ(float x) {
    float xcl = clamp(x,0.0,1.0);
    return 1.0-sqrt(1.0-xcl*xcl);
}
float ease_out_circ(float x) {
    float xcl = clamp(x,0.0,1.0);
    float w = 1.0-xcl;
    return sqrt(1.0 - w*w);
}
float ease_in_out_circ(float x) {
    return x<0.5 ? 0.5 * ease_in_circ(2.0*x) : 0.5 * ease_out_circ(2.0*x - 1.0) + 0.5;
}
float ease_in_back(float x) {
    float x2 = x*x;
    float x3 = x2*x;
    return 2.70158*x3 - 1.70158*x2;
}
float ease_out_back(float x) {
    float w = 1.0-x;
    float w2 = w*w;
    float w3 = w2*w;
    return 1.0 - (2.70158*w3 - 1.70158*w2);
}
float ease_in_out_back(float x) {
    return x<0.5 ? 0.5 * ease_in_back(2.0*x) : 0.5 * ease_out_back(2.0*x-1.0) + 0.5;
}
float ease_in_elastic(float x) {
    float w = 1.0-x;
    float p = -10.0*w;
    return x==0.0?0.0:x==1.0?1.0:
       -pow(2.0, p) * sin( (2.0*PI/3.0)*(p-0.75) );
}
float ease_out_elastic(float x) {
    float p = -10.0*x;
    return x==0.0?0.0:x==1.0?1.0:
        1.0 - pow(2.0, p) * sin( (2.0*PI/3.0)*(p+0.75) );
}
float ease_in_out_elastic(float x) {
    return x<0.5 ? 0.5 * ease_in_elastic(2.0*x) : 0.5 * ease_out_elastic(2.0*x-1.0) + 0.5;
}
float ease_out_bounce(float x) {
    const float4 bw = float4(1.0,2.0,2.5,2.75)/2.75;
    const float4 bj = float4(0.0,1.5,2.25,2.625)/2.75;
    const float4 bb = float4(0.0,0.75, 0.9375, 0.984375);

    int i = x<bw[0]?0:x<bw[1]?1:x<bw[2]?2:3;
    float w = x - bj[i];
    return 7.5625*w*w + bb[i];
}
float ease_in_bounce(float x) {
    float w = 1.0-x;
    return 1.0 - ease_out_bounce(w);
}
float ease_in_out_bounce(float x) {
    return x<0.5 ? 0.5 * ease_in_bounce(2.0*x) : 0.5 * ease_out_bounce(2.0*x-1.0) + 0.5;
}

float2 bezier_quartic_2d(float2 p0, float2 p1, float2 p2, float s) {
    float2 p01 = lerp(p0,p1,s);
    float2 p12 = lerp(p1,p2,s);
    return lerp(p01,p12,s);
}
float2 bezier_cubic_2d(float2 p0, float2 p1, float2 p2, float2 p3, float s) {
    float2 p01 = lerp(p0,p1,s);
    float2 p12 = lerp(p1,p2,s);
    float2 p23 = lerp(p2,p3,s);
    float2 p012 = lerp(p01,p12,s);
    float2 p123 = lerp(p12,p23,s);
    return lerp(p012,p123,s);
}
float2 bezier_quadratic_2d(float2 p0, float2 p1, float2 p2, float2 p3, float2 p4, float s) {
    float2 p01 = lerp(p0,p1,s);
    float2 p12 = lerp(p1,p2,s);
    float2 p23 = lerp(p2,p3,s);
    float2 p34 = lerp(p3,p4,s);
    float2 p012 = lerp(p01,p12,s);
    float2 p123 = lerp(p12,p23,s);
    float2 p234 = lerp(p23,p34,s);
    float2 p0123 = lerp(p012,p123,s);
    float2 p1234 = lerp(p123,p234,s);
    return lerp(p0123,p1234,s);
}
float ease_out_bezier_demo1(float x) {
    float2 p0 = float2(0,0);
    float2 p1 = float2(0,1);
    float2 p2 = float2(0.3,1);
    float2 p3 = float2(0.7,0);
    float2 p4 = float2(1,1);
    float2 b = bezier_quadratic_2d(p0,p1,p2,p3,p4,x);
    //note: throwing b[0] is not mathematically satisfying but it seems enough to get a fairly customizable curve
    // bezier function here map 1d to 2d coordinates uv = b(t) while easing functions are traditionnally 1d to 1d
    return b[1];
}
float ease_in_bezier_demo1(float x) {
    float w = 1.0-x;
    return 1.0 - ease_out_bezier_demo1(w);
}
float ease_in_out_bezier_demo1(float x) {
    return x<0.5 ? 0.5 * ease_in_bezier_demo1(2.0*x) : 0.5 * ease_out_bezier_demo1(2.0*x-1.0) + 0.5;
}
// https://solhsa.com/interpolation/
float catmullrom(float t, float p0, float p1, float p2, float p3) {
    return 0.5 * (
            (2 * p1) +
            (-p0 + p2)*t +
            (2 * p0 - 5 * p1 + 4 * p2 - p3)*t*t +
            (-p0 + 3 * p1 - 3 * p2 + p3)*t*t*t
            );
}

float ease_out_catmullrom_demo1(float x) {
    float Q = -6.0;
    float T = 4.0;
    return catmullrom(x, Q, 0.0, 1.0, T);
}

float ease_in_catmullrom_demo1(float x) {
    float w = 1.0-x;
    return 1.0 - ease_out_catmullrom_demo1(w);
}

float ease_in_out_catmullrom_demo1(float x) {
    return x<0.5 ? 0.5 * ease_in_catmullrom_demo1(2.0*x) : 0.5 * ease_out_catmullrom_demo1(2.0*x-1.0) + 0.5;
}

float4 visual_test(float2 uv, float4 rgba, float ez) {
    // Animate the output
    bool inside = false;
    if (wanted_visual_test == 0) {
        // sizes
        float2 uv_sym = (uv - 0.5) * 2.0;
        float2 p2 = float2(ez, ez);
        float2 p1 = -p2;
        inside = inside_box(uv_sym, p1, p2);
    }
    else if (wanted_visual_test == 1) {
        // positions
        inside = !(uv.x > ez);
    }
    else {
        // transparencies
        rgba.a = 0.2 + ez*0.8;
    }

    return inside ? float4(rgba.rgb*0.5, 1.0) : rgba;
}

float apply_easing(float t) {
    float ez;
    int ease_func_id = wanted_ease_func==0 ? 0 : wanted_ease_func+wanted_ease_kind;

    if      ( ease_func_id == 1 ) { ez = ease_in_sine(t); }
    else if ( ease_func_id == 2 ) { ez = ease_out_sine(t); }
    else if ( ease_func_id == 3 ) { ez = ease_in_out_sine(t); }
    else if ( ease_func_id == 4 ) { ez = ease_in_quad(t); }
    else if ( ease_func_id == 5 ) { ez = ease_out_quad(t); }
    else if ( ease_func_id == 6 ) { ez = ease_in_out_quad(t); }
    else if ( ease_func_id == 7 ) { ez = ease_in_cubic(t); }
    else if ( ease_func_id == 8 ) { ez = ease_out_cubic(t); }
    else if ( ease_func_id == 9 ) { ez = ease_in_out_cubic(t); }
    else if ( ease_func_id == 10 ) { ez = ease_in_quart(t); }
    else if ( ease_func_id == 11 ) { ez = ease_out_quart(t); }
    else if ( ease_func_id == 12 ) { ez = ease_in_out_quart(t); }
    else if ( ease_func_id == 13 ) { ez = ease_in_quint(t); }
    else if ( ease_func_id == 14 ) { ez = ease_out_quint(t); }
    else if ( ease_func_id == 15 ) { ez = ease_in_out_quint(t); }
    else if ( ease_func_id == 16 ) { ez = ease_in_expo(t); }
    else if ( ease_func_id == 17 ) { ez = ease_out_expo(t); }
    else if ( ease_func_id == 18 ) { ez = ease_in_out_expo(t); }
    else if ( ease_func_id == 19 ) { ez = ease_in_circ(t); }
    else if ( ease_func_id == 20 ) { ez = ease_out_circ(t); }
    else if ( ease_func_id == 21 ) { ez = ease_in_out_circ(t); }
    else if ( ease_func_id == 22 ) { ez = ease_in_back(t); }
    else if ( ease_func_id == 23 ) { ez = ease_out_back(t); }
    else if ( ease_func_id == 24 ) { ez = ease_in_out_back(t); }
    else if ( ease_func_id == 25 ) { ez = ease_in_elastic(t); }
    else if ( ease_func_id == 26 ) { ez = ease_out_elastic(t); }
    else if ( ease_func_id == 27 ) { ez = ease_in_out_elastic(t); }
    else if ( ease_func_id == 28 ) { ez = ease_in_bounce(t); }
    else if ( ease_func_id == 29 ) { ez = ease_out_bounce(t); }
    else if ( ease_func_id == 30 ) { ez = ease_in_out_bounce(t); }
    else if ( ease_func_id == 31 ) { ez = ease_in_bezier_demo1(t); }
    else if ( ease_func_id == 32 ) { ez = ease_out_bezier_demo1(t); }
    else if ( ease_func_id == 33 ) { ez = ease_in_out_bezier_demo1(t); }
    else if ( ease_func_id == 34 ) { ez = ease_in_catmullrom_demo1(t); }
    else if ( ease_func_id == 35 ) { ez = ease_out_catmullrom_demo1(t); }
    else if ( ease_func_id == 36 ) { ez = ease_in_out_catmullrom_demo1(t); }
    else { ez = t; }

    return ez;
}

float4 EffectLinear(float2 uv)
{
    // Lets note: ez = tested_easing_function(t);
    float ez;
    // Set t as a repeating linear time progression from 0.0 to 1.0 with a pause at begining and at the end
    float t = clamp(fmod(time*4.0,1.0+porch*2.0)-porch, 0.0, 1.0);
    t = reverse ? 1.0 - t : t;

    // Get the current source pixel
    float4 rgba = image.Sample(textureSampler, uv);

    // Split screen to compare easing function with linear function
    float2 uv_split = uv;
    if ( wanted_visual_test == 0 ) {
        uv_split *= float2(2.0,1.0); // vertical (side-by-side) split
    }
    else {
        uv_split *= float2(1.0,2.0); // horizontal (top vs bottom) split
    }

    if ( fmod(uv_split,1.0) == uv_split ) {
        // Apply the easing function
        ez = apply_easing(t);

        // Demonstrate the easing function
        rgba = visual_test(uv_split, rgba, ez);
    }
    else {
        // Demonstrate the linear case
        rgba = visual_test(fmod(uv_split,1.0), rgba, t);
    }

    // Display the curve graph in a semi-transparent fashion
    if (uv.x > (1-curve_ratio) && uv.y > (1-curve_ratio)) {
        float2 uv_small = (uv - (1-curve_ratio)) / curve_ratio;
        float ez2 = apply_easing(uv_small.x);

        float4 curve_px = draw_curve(uv_small, ez2, float4(0.1, 0.2, 0.8, 1.0));
        // (alpha crudely blended, not in linear space, not important for this use case)
        rgba.xyz = lerp( rgba.rgb, curve_px.rgb, curve_px.a );
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
