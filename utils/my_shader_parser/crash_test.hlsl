uniform float4x4 ViewProj;

// Common parameters for all shaders, as reference. Do not uncomment this (but you can remove it safely).

uniform float time;            // Time since the shader is running. Goes from 0 to 1 for transition effects; goes from 0 to infinity for filter effects
uniform texture2d image;       // Texture of the source (filters only)
uniform texture2d tex_interm;  // Intermediate texture where the previous step will be rendered (for multistep effects)
uniform float upixel;          // Width of a pixel in the UV space
uniform float vpixel;          // Height of a pixel in the UV space
uniform float rand_seed;       // Seed for random functions
uniform int current_step;      // index of current step (for multistep effects)

// Specific parameters of the shader. They must be defined in the meta.json file next to this one.
uniform float progression = 1.0;
const float testing = 1.0;
pppppppppppppppproperty float testing2 = 1.0;
unicorn float testing3 = 42.0;

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
    float2 uv  : TEXCOORD0 /* SYNTAX ERROR TESTING HERE (missing ;) */
};

VertData VSDefault(VertData v_in)
{
    VertData vert_out;
    vert_out.uv  = v_in.uv;

    // Mirror effect done via vert_out.pos.x modification
    float half_width = 1.0/upixel/2.0;
    float v_mirror_pos_x = (v_in.pos.x-half_width)*cos(progression*PI)+half_width ;
    float4 v_miror = float4(v_mirror_pos_x, v_in.pos.y, v_in.pos.z, 1.0);

    vert_out.pos = mul(v_miror, ViewProj);
    return vert_out;
}

float4 EffectLinear(float2 uv)
{
    float4 rgba = image.Sample(textureSampler, uv);
/* CRASH TEST HERE */
    rgba.a = undefined_var;
    //if (true) {
/* CRASH TEST HERE */
    return rgba;
}

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
