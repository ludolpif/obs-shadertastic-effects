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
uniform bool should_be_squared;
uniform int shape_kind;
uniform float shape_nsides;
uniform float shape_width;
uniform float shape_rotate;
uniform float shape_smoothness;
uniform bool smooth_inside;
uniform float shape_center_u;
uniform float shape_center_v;
//----------------------------------------------------------------------------------------------------------------------

#ifndef _CONSTS_HLSL
#define _CONSTS_HLSL
/*
 * Note: Number of decimal places have been preperly choosen for 32 bits
 *  IEEE754 floats (binary32 format). You can verify with the link below that
 *  adding more decimal places will not change any bits in memory at all.
 *  https://www.h-schmidt.net/FloatConverter/IEEE754.html
 */
#define M_TWOPI     6.2831853
#define M_PI        3.14159265
#define M_PI_2      1.57079632
#define M_PI_3      1.04719755
#define M_PI_4      0.78539816
#define M_1_PI      0.31830988
#define M_2_PI      0.63661977

#define M_E         2.7182818
#define M_LOG2E     1.442695
#define M_LOG10E    0.43429448
#define M_LN2       0.69314718
#define M_LN10      2.30258509
#define M_SQRT2     1.4142135
#define M_SQRT1_2   0.70710678

#endif /* _CONSTS_HLSL */

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

//Here goes your implementation !

float4 EffectLinear(float2 uv)
{
    float aspect_ratio = upixel/vpixel;
    float2 shape_center = float2(shape_center_u, shape_center_v);

    float2 uv_centered = uv * 2.0 - 1.0;
    if ( should_be_squared ) uv_centered[1] *= aspect_ratio;

    float4 rgba = image.Sample(textureSampler, uv);
    float d = 0;
    if ( shape_kind == 1 ) {
        /* Circle */
        d = distance(uv_centered, shape_center);
        /* dst : used to compare the currently processed pixel distance from the circle center and the circle diameter
         *   considering an inner margin to let room to smoothing 
        float compare_distance = distance(uv_centered, shape_center);
        compare_distance -= (shape_width-2.0*vpixel)*aspect_ratio/2.0;
        compare_distance /= upixel; // converts dst from [0;1] to [0;image width in pixels]
        rgba.a = 1.0 - clamp(compare_distance, 0.0, 1.0);*/
    } else if ( shape_kind == 2 ) {
        /* regular polygon with N faces, from https://thebookofshaders.com/07/ */
        //FIXME take shape_width into account, uniformise antialiasing (tunable smoothstep everywhere ?)
        // Remap the space to -1. to 1.
        // Angle and radius from the current pixel
        float a = atan2(uv_centered[0], uv_centered[1]) + M_PI + M_PI_3*shape_rotate ;
        float r = M_TWOPI/shape_nsides;
        // Shaping function that modulate the distance
        d = cos(floor(.5+a/r)*r - a) * length(uv_centered);
    } 
    //TODO smoothing in uv non squared space lead to inconsistencies
    // alpha=1.0 when inside shape, alpha=0.0 outside, alpha ramp at shape border to have an anti-aliasing or smoothing
    if ( smooth_inside ) {
        rgba.a = 1.0-smoothstep(shape_width - shape_smoothness*upixel, shape_width, d);
    } else {
        rgba.a = 1.0-smoothstep(shape_width, shape_width + shape_smoothness*upixel, d);
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
