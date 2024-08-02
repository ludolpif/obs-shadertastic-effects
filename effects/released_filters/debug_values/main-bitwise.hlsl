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
uniform float debug_value;
uniform float font_size;
uniform int coord_mode;
uniform float pixel_u;
uniform float pixel_v;
uniform int pixel_x;
uniform int pixel_y;

/* #include "../../shadertastic-lib/geometry/inside-box.hlsl" */
#ifndef _INSIDE_BOX_HLSL
#define _INSIDE_BOX_HLSL
/**
 * Returns true if v is included in the rectangle defined by topLeft (inclusive) and bottomRight (exclusive)
 * Alternative definition : with topLeft.x <= bottomRight.x and topLeft.y <= bottomRight.y,
 *  it returns ( topLeft.x <= v.x < bottomRight.x && topLeft.y <= v.y < bottomRight.y )
 * Behavior on limits is messy if topLeft.x > bottomRight.x or topLeft.y > bottomRight.y
 * @param v coordinates of a point to test
 * @param topLeft coordinates of the top left corner of the rectangle
 * @param bottomRight coordinates of the bottom right corner of the rectangle
 */
bool insideBox(float2 v, float2 topLeft, float2 bottomRight) {
    float2 s = step(topLeft, v) - step(bottomRight, v);
    return s.x * s.y != 0.0;
}

#endif /* _INSIDE_BOX_HLSL */

/* #include "../../shadertastic-lib/debug/print-value.hlsl" */
#ifndef _PRINT_VALUE_HLSL
#define _PRINT_VALUE_HLSL
/* Inspired from https://www.shadertoy.com/view/3lGBDm ; Licensed under CC BY-NC-SA 3.0
    Font extracted with : zcat /usr/share/fonts/X11/misc/4x6.pcf.gz | pcf2bdf
    See : https://github.com/ludolpif/obs-shadertastic-effects/blob/main/utils/x11-bitmap-font-extractor.sh

    dcb_digit is encoded with some extensions to 4-bits DCB: 0-9:digit, 10:NaN, 11:'.', 12:' ', 13:'-', 14:'e', 15:inf
*/
int2 float_decode_fixed_point_table(int i) {
    int pow2_table_pos[30];
    int pow2_table_neg[31];
    pow2_table_pos[0]  =         1;
    pow2_table_pos[1]  =         2;
    pow2_table_pos[2]  =         4;
    pow2_table_pos[3]  =         8;
    pow2_table_pos[4]  =        16;
    pow2_table_pos[5]  =        32;
    pow2_table_pos[6]  =        64;
    pow2_table_pos[7]  =       128;
    pow2_table_pos[8]  =       256;
    pow2_table_pos[9]  =       512;
    pow2_table_pos[10] =      1024;
    pow2_table_pos[11] =      2048;
    pow2_table_pos[12] =      4096;
    pow2_table_pos[13] =      8192;
    pow2_table_pos[14] =     16384;
    pow2_table_pos[15] =     32768;
    pow2_table_pos[16] =     65536;
    pow2_table_pos[17] =    131072;
    pow2_table_pos[18] =    262144;
    pow2_table_pos[19] =    524288;
    pow2_table_pos[20] =   1048576;
    pow2_table_pos[21] =   2097152;
    pow2_table_pos[22] =   4194304;
    pow2_table_pos[23] =   8388608;
    pow2_table_pos[24] =  16777216;
    pow2_table_pos[25] =  33554432;
    pow2_table_pos[26] =  67108864;
    pow2_table_pos[27] = 134217728;
    pow2_table_pos[28] = 268435456;
    pow2_table_pos[29] = 536870912;
    pow2_table_neg[1]  = 500000000;
    pow2_table_neg[2]  = 250000000;
    pow2_table_neg[3]  = 125000000;
    pow2_table_neg[4]  =  62500000;
    pow2_table_neg[5]  =  31250000;
    pow2_table_neg[6]  =  15625000;
    pow2_table_neg[7]  =   7812500;
    pow2_table_neg[8]  =   3906250;
    pow2_table_neg[9]  =   1953125;
    pow2_table_neg[10] =    976562;
    pow2_table_neg[11] =    488281;
    pow2_table_neg[12] =    244141;
    pow2_table_neg[13] =    122070;
    pow2_table_neg[14] =     61035;
    pow2_table_neg[15] =     30518;
    pow2_table_neg[16] =     15259;
    pow2_table_neg[17] =      7629;
    pow2_table_neg[18] =      3815;
    pow2_table_neg[19] =      1907;
    pow2_table_neg[20] =       954;
    pow2_table_neg[21] =       477;
    pow2_table_neg[22] =       238;
    pow2_table_neg[23] =       119;
    pow2_table_neg[24] =        60;
    pow2_table_neg[25] =        30;
    pow2_table_neg[26] =        15;
    pow2_table_neg[27] =         7;
    pow2_table_neg[28] =         4;
    pow2_table_neg[29] =         2;
    pow2_table_neg[30] =         1;

    if ( i < 30.0 && i >= 0.0 ) {
        return int2(pow2_table_pos[i],0);
    }
    if ( i < 0.0 && i > -31.0 ) {
        return int2(0,pow2_table_neg[-i]);
    }
    return int2(0,0);
}

float printDCB(float2 vStringCoords, int dcb_digit) {
    float2 glyph_size = float2(4.0,6.0);
    float font[20];
    font[0] = 2454816.0;    /* 0 */
    font[1] = 2302576.0;    /* 1 */
    font[2] = 2441840.0;    /* 2 */
    font[3] = 7611440.0;    /* 3 */
    font[4] = 5600320.0;    /* 4 */
    font[5] = 7418928.0;    /* 5 */
    font[6] = 6370592.0;    /* 6 */
    font[7] = 7610640.0;    /* 7 */
    font[8] = 6628656.0;    /* 8 */
    font[9] = 2450480.0;    /* 9 */
    font[10] = 4551952.0;   /* N */
    font[11] = 32.0;        /* . */
    font[12] = 0.0;         /*   */
    font[13] = 28672.0;     /* - */
    font[14] = 152416.0;    /* e */
    font[15] = 2110064.0;   /* i */
    font[16] = 415072.0;    /* a */
    font[17] = 4354592.0;   /* f */
    font[18] = 218448.0;    /* n */
    font[19] = 3416096.0;   /* ? */

    float w = glyph_size[0];
    float h = glyph_size[1];
    int i = (dcb_digit >= 0 && dcb_digit < 20)?dcb_digit:19;
    return floor(mod((font[i] / pow(2.0, floor(fract(vStringCoords.x) * w) + (floor((1.0-vStringCoords.y) * h) * w))), 2.0));
}

void float_decode(in float float_to_decode, in int wanted_digit,
        out int sign, out int exp, out int mant, out float expf, out int2 fixed_point, out int dcb_digit)
{
    // Floats numbers are coded in IEEE754 in a way roughly representable as sign*2^expf*(1+mantissa_fractionnal)
	sign = ( float_to_decode < 0.0 || float_to_decode == -0.0)?-1:1; // note: -0.0 is not < +0.0
    // Before exponent extraction, eliminate special cases on which log2(x) will not be useful
    if ( float_to_decode == 0.0 ) {
        expf = -126.0;
        exp = 0;
        fixed_point = int2(0,0);
        dcb_digit = (wanted_digit==8 || wanted_digit==10)?0:(wanted_digit==9?11:12); // for 0.0
        return;
    }
    if ( isnan(float_to_decode) || isinf(float_to_decode) ) {
        expf = float_to_decode; // non-finite value as a placeholder
        exp = 255;
        fixed_point = int2(0,0);
		dcb_digit = (wanted_digit>5 && wanted_digit<9)
            ?isnan(float_to_decode)?10:15
            :(wanted_digit==4 && sign==-1)?13:12; // for +/-NaN or +/-inf
        return;
    }
    // Exponent extraction (for all finite cases)
    float float_tmp = abs(float_to_decode);
    expf = floor(log2(float_tmp)); // float exponent without -127 offset (out paraeter)
    int expi = int(expf); // int exponent without -127 offset (internal use)
    exp = expi + 127; // IEEE754 encoded 8bits-wide exponent (out parameter)

	// Extract the mantissa bit per bit, compute the fixed_point value simultaneously
	// using only float values that are exactly represented in IEEE754 encoding (powers of two)
    mant = 0; // IEEE754 23bits-wide mantissa as int without the leading implicit one
    fixed_point = float_decode_fixed_point_table(expi); // Limited range fixed point XXX specifiy the right range
    // The 1 is always implicit in the sense that no bit represent it in the mantissa nor exponent bitfields
    float mantissa_implicit_one = pow(2.0, expf);
    // TODO loop on int as all uses of mantissa_pow are casted to int. use expi also.
    for ( float mantissa_pow = expf-1.0; mantissa_pow > expf-24.0; mantissa_pow -= 1.0 ) {
        mant *= 2;
        float mantissa_fractionnal = pow(2.0, mantissa_pow); // TODO precision loss here probably, use table ?
        float crible = mantissa_implicit_one + mantissa_fractionnal;
        if ( float_tmp >= crible ) {
            float_tmp -= mantissa_fractionnal;
            mant += 1;
			// Fixed point is split into integer part and fractionnal part
			// The way the floats are encoded garantee there is not carry to handle between those two parts
            fixed_point += float_decode_fixed_point_table(int(mantissa_pow));
        }
    }
	// To ease a rudimentary printf("%f",x) function we will return in dcb_digit a decimal digit of rank wanted_digit [0;18[
    // TODO make this in a int_decode() function to allow user print ints and floats
    int pow10_table[10];
    pow10_table[0] = 1;
    pow10_table[1] = 10;
    pow10_table[2] = 100;
    pow10_table[3] = 1000;
    pow10_table[4] = 10000;
    pow10_table[5] = 100000;
    pow10_table[6] = 1000000;
    pow10_table[7] = 10000000;
    pow10_table[8] = 100000000;
    pow10_table[9] = 1000000000;

	if ( wanted_digit < 0 || wanted_digit > 18 ) {
        dcb_digit = 11; // for ' '
    } else if ( wanted_digit == 0 ) {
		dcb_digit = (sign==-1)?13:12; // for '-' or '+'
	} else if ( wanted_digit == 9 ) {
		dcb_digit = 11; // for '.'
	} else if ( wanted_digit < 9 ) {
		int pow10_next = pow10_table[9-wanted_digit];
		int pow10_curr = pow10_table[8-wanted_digit];
		dcb_digit = ( fixed_point[0] % pow10_next ) / pow10_curr;
	} else {
		int pow10_next = pow10_table[19-wanted_digit];
		int pow10_curr = pow10_table[18-wanted_digit];
		dcb_digit = ( fixed_point[1] % pow10_next ) / pow10_curr;
	}
}
#endif /* _PRINT_VALUE_HLSL */

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
    float aspect_ratio = vpixel/upixel;
    float4 color_red  = float4(1.0,0.0,0.0,1.0);
    float4 color_cyan = float4(0.0,1.0,1.0,1.0);
	float4 color_light_gray = float4(0.75,0.75,0.75,1.0);

    float2 uv_pixel_to_debug = (coord_mode==0)?float2(pixel_u,pixel_v):float2(pixel_x*upixel, pixel_y*vpixel);

    //float4 rgba_pixel_to_debug = image.Sample(textureSampler, uv_pixel_to_debug);
    float4 rgba = image.Sample(textureSampler, uv);

    float font_ratio = 6.0 / 4.0;
    float2 text_right_top_anchor = float2(1.0,0.0);
    vec2 vStringCoords = (uv - text_right_top_anchor)*vec2(aspect_ratio*font_ratio, 1.0)/font_size + float2(19.0, 0.0);

    // TODO use 9 digits internally if usefull to have good precision, but only display digits known to be exact
    if ( insideBox(vStringCoords, float2(0.0, 0.0), float2(19.0, 1.0) ) ) {
        // float_decode() in:
        float float_to_decode = debug_value;
        //float float_to_decode = time;
        int wanted_digit = int(vStringCoords.x);
        // float_decode() out:
        int sign, exp, mant, dcb_digit;
        float expf;
        int2 fixed_point;
        // float_decode() call:
        float_decode(float_to_decode, wanted_digit, sign, exp, mant, expf, fixed_point, dcb_digit);
        // displaying parts of the result
        if ( printDCB(vStringCoords, dcb_digit) == 1.0 ) {
            return color_red;
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
