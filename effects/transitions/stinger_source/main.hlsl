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
uniform texture2d tex_fillkey;
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

struct VertDataOut {
    float2 uv  : TEXCOORD0;
    float2 uv_fill: TEXCOORD1;
    float2 uv_key : TEXCOORD2;
    float4 pos : POSITION;
};

struct FragData {
    float2 uv  : TEXCOORD0;
    float2 uv_fill: TEXCOORD1;
    float2 uv_key : TEXCOORD2;
};

VertDataOut VSDefault(VertData v_in)
{
    VertDataOut vert_out;
    vert_out.uv  = v_in.uv;
    vert_out.uv_fill  = float2(v_in.uv[0]/2, v_in.uv[1]);
    vert_out.uv_key  = float2(0.5+v_in.uv[0]/2, v_in.uv[1]);
    vert_out.pos = mul(float4(v_in.pos.xyz, 1.0), ViewProj);
    return vert_out;
}
//----------------------------------------------------------------------------------------------------------------------

float4 EffectLinear(float2 uv, float2 uv_fill, float2 uv_key)
{
    float4 col_a = tex_a.Sample(textureSampler, uv);
    float4 col_b = tex_b.Sample(textureSampler, uv);
    float4 col_fill = tex_fillkey.Sample(textureSampler, uv_fill);
    float4 col_key = tex_fillkey.Sample(textureSampler, uv_key);
    // lerp(x,y,s) returns x*(1-s) + y*s; Works with x,y,s being vector of same size, or (x,y same size and s is float).
    return float4(lerp(lerp(col_a, col_b, col_key).rgb, col_fill.rgb, col_fill.a), 1.0);
}
//----------------------------------------------------------------------------------------------------------------------

// You probably don't want to change anything from this point.

float4 PSEffect(FragData f_in) : TARGET
{
    float4 rgba = EffectLinear(f_in.uv, f_in.uv_fill, f_in.uv_key);
    if (current_step == nb_steps - 1) {
        rgba.rgb = srgb_nonlinear_to_linear(rgba.rgb);
    }
    return rgba;
}

float4 PSEffectLinear(FragData f_in) : TARGET
{
    float4 rgba = EffectLinear(f_in.uv, f_in.uv_fill, f_in.uv_key);
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
