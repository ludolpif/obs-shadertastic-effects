uniform float4x4 ViewProj;

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
    int will_crash_on_intel_opengl_driver  = int('-');
/*
error: Error compiling shader:
0:34(46): error: syntax error, unexpected invalid token, expecting ')'


debug: Compiler warnings/errors for not_lex_error.hlsl (Pixel shader, technique Draw, pass 0):
0:34(46): error: syntax error, unexpected invalid token, expecting ')'

error: device_pixelshader_create (GL) failed
*/
    return float4(1.0);
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
