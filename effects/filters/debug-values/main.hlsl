/*
 * This shader contains code from ShaderToy, licensed as CC BY-NC-SA 3.0.
 * So this shader is also CC BY-NC-SA 3.0
 */

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
uniform int pixel_x;
uniform int pixel_y;
uniform float font_size;

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

// From https://www.shadertoy.com/view/3lGBDm
float DigitBin( int x )
{
    return x==0?480599.0:x==1?139810.0:x==2?476951.0:x==3?476999.0:x==4?350020.0:x==5?464711.0:x==6?464727.0:x==7?476228.0:x==8?481111.0:x==9?481095.0:0.0;
}

float PrintValue( vec2 vStringCoords, float fValue, float fMaxDigits, float fDecimalPlaces )
{
    if ((vStringCoords.y < 0.0) || (vStringCoords.y >= 1.0)) return 0.0;

    bool bNeg = ( fValue < 0.0 );
	fValue = abs(fValue);

	float fLog10Value = log2(abs(fValue)) / log2(10.0);
	float fBiggestIndex = max(floor(fLog10Value), 0.0);
	float fDigitIndex = fMaxDigits - floor(vStringCoords.x);
	float fCharBin = 0.0;
	if(fDigitIndex > (-fDecimalPlaces - 1.01)) {
		if(fDigitIndex > fBiggestIndex) {
			if((bNeg) && (fDigitIndex < (fBiggestIndex+1.5))) fCharBin = 1792.0;
		} else {
			if(fDigitIndex == -1.0) {
				if(fDecimalPlaces > 0.0) fCharBin = 2.0;
			} else {
                float fReducedRangeValue = fValue;
                if(fDigitIndex < 0.0) { fReducedRangeValue = fract( fValue ); fDigitIndex += 1.0; }
				float fDigitValue = (abs(fReducedRangeValue / (pow(10.0, fDigitIndex))));
                fCharBin = DigitBin(int(floor(mod(fDigitValue, 10.0))));
			}
        }
	}
    return floor(mod((fCharBin / pow(2.0, floor(fract(vStringCoords.x) * 4.0) + (floor(vStringCoords.y * 5.0) * 4.0))), 2.0));
}

float4 EffectLinear(float2 uv)
{
    /* TODO : move those computed uniform values out of the pixel shader */
    // iResX=1/upixel, so aspect_ratio=iResX/iResY=(1/upixel)/(1/vpixel)=vpixel/upixel
    float aspect_ratio = vpixel/upixel;
    float2 vFontSize = font_size * vec2(1.0, aspect_ratio);

    float4 rgba = image.Sample(textureSampler, uv);
    float2 uv_pixel_to_debug = float2(pixel_x*upixel, pixel_y*vpixel);
    float4 rgba_pixel_to_debug = image.Sample(textureSampler, uv_pixel_to_debug);

    float3 vColour = rgba.rgb;
    float fDigits;
    float fDecimalPlaces;

    if ( uv[0] > 0.75 && uv[0] < 0.85 && uv[1] > 0.45 && uv[1] < 0.55 ) {
        return rgba_pixel_to_debug;
    }

    // Print pixel_to_debug red component
    fDigits = 6.0;
    fDecimalPlaces = 3.0;
	float2 vPixelCoord1 = vec2(0.0, 0.0);
	float fDebugValue1 = rgba_pixel_to_debug.r*256.0;
    float2 fragCoord = uv / float2(upixel,-vpixel);
    float2 vStringCoords = (fragCoord - vPixelCoord1 - (0.0, -font_size*aspect_ratio)) / vFontSize;
	float fIsDigit1 = PrintValue(vStringCoords, fDebugValue1, fDigits, fDecimalPlaces);
	rgba = mix(rgba, vec4(0.0, 1.0, 1.0, 1.0), fIsDigit1);

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
