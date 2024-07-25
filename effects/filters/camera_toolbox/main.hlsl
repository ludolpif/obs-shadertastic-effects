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
#define PI 3.1415926535
// Specific parameters of the shader. They must be defined in the meta.json file next to this one.
uniform float camera_zoom;
uniform float camera_scaledown;
uniform float camera_position_deg;
uniform float camera_position_margin_px;
uniform bool mirror_auto;
uniform float mirror_auto_threshold;
uniform float mirror_progression;
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

VertData VSMirrorAndBorders(VertData v_in)
{
    VertData vert_out;

    float2 center = 0.5/float2(upixel,vpixel);
    float camera_position_rad = camera_position_deg*PI/180.0;
    float2 direction = float2(cos(camera_position_rad), sin(camera_position_rad));

    float4 v_interm_pos = float4(v_in.pos.xyz,1.0);

    //FIXME Usually it is scale, then rotation and lastly translation

    // Mirror
    if ( !mirror_auto ) {
        v_interm_pos.x = cos(mirror_progression*PI) * (v_interm_pos.x - center.x) + center.x;
    } else if ( /* mirror_auto && */ direction.x > mirror_auto_threshold ) {
        v_interm_pos.x = -1.0 * (v_interm_pos.x - center.x) + center.x;
    } /* else no mirror */
    
    // Zoom
    v_interm_pos.w *= camera_scaledown;
    // Center the camera image
    v_interm_pos.xy += center*(camera_scaledown-1.0);
    
    // Move the camera to direction on the greatest ellipsis allowing the image to not overflow
    float2 move = direction * center*(camera_scaledown-1.0);
    // Move further, clamping to the border of image
    move *= 2.0;
    move = min(move,  center*(camera_scaledown-1.0) - camera_position_margin_px*camera_scaledown);
    move = max(move, -center*(camera_scaledown-1.0) + camera_position_margin_px*camera_scaledown);
    // TODO in case of camera_scaledown near 1 and non null margin, the image maybe zoomed from top left corner and not center
    v_interm_pos.xy += move;

    vert_out.pos = mul(v_interm_pos, ViewProj);

    // Centered cropping image zoom inside camera frame
    vert_out.uv  = (v_in.uv-0.5)/camera_zoom + 0.5;
    return vert_out;
}

float4 EffectLinear(float2 uv)
{
    float4 rgba = image.Sample(textureSampler, uv);
    //rgba.a = clamp(rgba.a, camera_min_opacity, camera_max_opacity);
    return rgba;
}
/*
TODO A priori inexploitable pour faire réapparaitre un fond chroma-keyed car les données sont détruites en amont
uniform float camera_min_opacity;
uniform float camera_max_opacity;
    {
      "name": "camera_min_opacity",
      "label": "Camera minimum opacity",
      "type": "double",
      "slider": true,
      "min": 0.0,
      "max": 1.0,
      "step": 0.01,
      "default": 0.0
    },
    {
      "name": "camera_max_opacity",
      "label": "Camera maximum opacity",
      "type": "double",
      "slider": true,
      "min": 0.0,
      "max": 1.0,
      "step": 0.01,
      "default": 1.0
    },
    */

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
        vertex_shader = VSMirrorAndBorders(v_in);
        pixel_shader = PSEffect(f_in);
    }
}
