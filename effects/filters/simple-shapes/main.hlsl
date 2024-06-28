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
uniform float shape_width;
uniform float shape_center_u;
uniform float shape_center_v;
uniform int shape_kind;
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

//Here goes your implementation !

float4 EffectLinear(float2 uv)
{
    float aspect_ratio = upixel/vpixel;
    float2 center_squared = float2(shape_center_u, shape_center_v*aspect_ratio);
    float2 uv_squared = uv;
    uv_squared[1] *= aspect_ratio;

    float4 rgba = image.Sample(textureSampler, uv);
    if ( shape_kind == 1 ) {
        /* Circle */
        /* dst : used to compare the currently processed pixel distance from the circle center and the circle diameter
         *   considering an inner margin to let room to smoothing */
        float compare_distance = distance(uv_squared, center_squared);
        compare_distance -= (shape_width-2.0*vpixel)*aspect_ratio/2.0;
        compare_distance /= upixel; /* converts dst from [0;1] to [0;image width in pixels] */
        rgba.a = 1.0 - clamp(compare_distance, 0.0, 1.0);
    } else if ( shape_kind == 2 ) {
        /* Square (no smoothing, nor useful because OBS already have crop function) */
        float2 compare_distance = abs(uv_squared-center_squared) - shape_width*aspect_ratio/2.0;
        if ( compare_distance[0] > 0.0 || compare_distance[1] > 0.0 ) {
            rgba.a = 0.0;
        }
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
