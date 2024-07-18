// Common parameters for all shaders, as reference. Do not uncomment this (but you can remove it safely).
/*
uniform float time;            // Time since the shader is running. Goes from 0 to 1 for transition effects; goes from 0 to infinity for filter effects
uniform texture2d tex_a;       // Texture of the previous frame (transitions only)
uniform texture2d tex_b;       // Texture of the next frame (transitions only)
uniform texture2d tex_interm;  // Intermediate texture where the previous step will be rendered (for multistep effects)
uniform float upixel;          // Width of a pixel in the UV space
uniform float vpixel;          // Height of a pixel in the UV space
uniform float rand_seed;       // Seed for random functions
uniform int current_step;      // index of current step (for multistep effects)
uniform int nb_steps;          // number of steps (for multisteps effects)
*/

// Specific parameters of the shader. They must be defined in the meta.json file next to this one.
uniform float columns;
uniform float phase_shift;
uniform float4 bg_color;

// Additionnal definitions for this shader
#define PI 3.1415926535
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
float4 EffectLinear(float2 uv)
{
    float2 cr = vec2(columns,columns*upixel/vpixel);
    
    float2 tiles_no = trunc(cr*uv);
    float2 tiles_uv = frac(cr*uv);
//  return float4(tiles_uv, 0.0, 1.0);
    float2 phases = tiles_no/(cr-1.0);
//  return float4(phases, 0.0, 1.0);
    float phase = (phases[0] + phases[1])/2.0;
//  return float4(phase, 0.0, 0.0, 1.0);
    float progression = clamp(time + (time-phase)*phase_shift, 0.0, 1.0);
//  return float4(progression, 0.0, 0.0, 1.0);
    float cos_t = cos(progression*PI);

    float2 flip = tiles_uv-0.5;
    flip[0] /= abs(cos_t);
    float2 flip_uv = flip+0.5;
//  return float4(progression, 0.0, 0.0, 1.0);
    
    float2 uv2 = (tiles_no+flip_uv)/cr;
    float4 col_a = tex_a.Sample(textureSampler, uv2);
    float4 col_b = tex_b.Sample(textureSampler, uv2);

    if ( cos_t == 0.0 || abs(flip[0]) > 0.5 ) {
        return bg_color;
    } else if (cos_t > 0.0) {
        return col_a;
    } else {
        return col_b;
    }
}
//----------------------------------------------------------------------------------------------------------------------

// You probably don't want to change anything from this point.

float4 PSEffect(FragData f_in) : TARGET
{
    float4 rgba = EffectLinear(f_in.uv);
    if (current_step == nb_steps - 1) {
        rgba.rgb = srgb_nonlinear_to_linear(rgba.rgb);
    }
    return rgba;
}

float4 PSEffectLinear(FragData f_in) : TARGET
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

technique DrawLinear
{
    pass
    {
        vertex_shader = VSDefault(v_in);
        pixel_shader = PSEffectLinear(f_in);
    }
}
