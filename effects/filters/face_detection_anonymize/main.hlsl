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

// Specific parameters of the face detection feature (enabled in meta.json with "input_facedetection": true)
uniform float2 fd_leye_1;
uniform float2 fd_leye_2;
uniform float2 fd_reye_1;
uniform float2 fd_reye_2;
uniform float2 fd_face_1;
uniform float2 fd_face_2;
uniform texture2d fd_points_tex;

// Specific parameters of the shader. They must be defined in the meta.json file next to this one.
uniform int anon_mode;
uniform int noface_mode;

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

bool inside_box(float2 v, float2 topLeft, float2 bottomRight) {
    float2 s = step(topLeft, v) - step(bottomRight, v);
    return s.x * s.y != 0.0;
}

//----------------------------------------------------------------------------------------------------------------------
// Note : float2x2 matrix is supported by OBS-SL parser but not translated, only float3x3, 3x4 and 4x4 are usable.
float2 rotate2d(float2 p, float angle) {
    float c = cos(angle);
    float s = sin(angle);
    return float2(
        p.x*c - p.y*s,
        p.x*s + p.y*c
    );
}
float4 EffectLinear(float2 uv)
{
    float aspect_ratio = vpixel/upixel;
    float2 ortho_correction = float2(aspect_ratio, 1.0);
    float2 uv_ortho = uv * ortho_correction;

    float2 fd_leye_center = ((fd_leye_1 + fd_leye_2) / 2.0) * ortho_correction;
    float2 fd_reye_center = ((fd_reye_1 + fd_reye_2) / 2.0) * ortho_correction;

    float2 eyes_center = (fd_leye_center + fd_reye_center) / 2.0;

    fd_leye_center -= eyes_center;
    fd_reye_center -= eyes_center;
    float2 uv_ortho_rotated = uv_ortho - eyes_center;

    float angle = -atan2((fd_reye_center.y - fd_leye_center.y), (fd_reye_center.x - fd_leye_center.x));
    
    uv_ortho_rotated = rotate2d(uv_ortho_rotated, angle);
    fd_leye_center = rotate2d(fd_leye_center, angle);
    fd_reye_center = rotate2d(fd_reye_center, angle);

    float fd_eyes_dist = distance(fd_leye_center, fd_reye_center);

    fd_leye_center -= float2(fd_eyes_dist * 0.68, 0.0);
    fd_reye_center += float2(fd_eyes_dist * 0.68, 0.0);
    fd_leye_center -= float2(0.0, (fd_reye_center.x - fd_leye_center.x) * 0.12);
    fd_reye_center += float2(0.0, (fd_reye_center.x - fd_leye_center.x) * 0.12);

    float2 uv_squares = 16.0*ortho_correction;
    float2 uv_pixelate = floor(uv*uv_squares+0.5)/uv_squares;
    bool no_face = (fd_face_1.x == -1.0); // All fd_* are set to (-1.0,-1.0) if no face detected
    bool drop = false;
    bool pixelate = false;

    if ( anon_mode == 0 /* Black rectangle over eyes */) {
        if ( no_face ) {
            // Drop every pixel if "No face detected mode" is "Anonymize the whole picture"
            drop = (noface_mode==0);
        } else if (inside_box(uv_ortho_rotated, fd_leye_center, fd_reye_center)) {
            // TODO make inside test with uv_pixelate and the best coords
            drop = true;
        }
    } else /* anon_mode == 1, Pixelate whole face */ {
        if ( no_face ) {
            // Pixelate every pixel if "No face detected mode" is "Anonymize the whole picture"
            pixelate = (noface_mode==0);
        } else if (inside_box(uv, fd_face_1, fd_face_2)) {
            pixelate = true;
        }
    }
    float4 rgba = image.Sample(textureSampler, pixelate?uv_pixelate:uv);
    return drop?float4(0.0, 0.0, 0.0, 1.0):rgba;
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
