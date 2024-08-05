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
#define POW10_TABLE_VALUES 1,10,100,1000,10000,100000,1000000,10000000,100000000,1000000000
#define POW2FP_INTEG_TABLE_VALUES 1,2,4,8,16,32,64,128,256,512,\
    1024,2048,4096,8192,16384,32768,65536,131072,262144,524288,\
    1048576,2097152,4194304,8388608,16777216,\
    33554432,67108864,134217728,268435456,536870912
#define POW2FP_FRACT_TABLE_VALUES 0,\
    500000000,\
    250000000,\
    125000000,\
     62500000,\
     31250000,\
     15625000,\
      7812500,\
      3906250,\
      1953125,\
       976562,\
       488281,\
       244141,\
       122070,\
        61035,\
        30518,\
        15259,\
         7629,\
         3815,\
         1907,\
          954,\
          477,\
          238,\
          119,\
           60,\
           30,\
           15,\
            7,\
            4,\
            2,\
            1
#ifndef DCB_FONT_VALUES
#define DCB_FONT_GLYPH_WIDTH 4
#define DCB_FONT_GLYPH_HEIGHT 6
#define DCB_FONT_VALUES 2454816.0, 2302576.0, 2441840.0, 7611440.0, 5600320.0,\
    7418928.0, 6370592.0, 7610640.0, 6628656.0, 2450480.0,\
    218448.0, 32.0, 0.0, 28672.0, 152416.0, 2110064.0, 415072.0, 4354592.0, 3416096.0
/* Characters in the font
 * [0] to [9] : 0123456789
 * [10]:'n' [11]:'.' [12]:' ' [13]:'-' [14]:'e' [16]:'i' [17]:'a' [18]:'f' [19]:'?' */
#endif /* DCB_FONT_VALUES */

//TODO Make text_grid more understandable, with digit numbers from right to left
//XXX add rotation or vertical option ? add char offset option ? clarify uv / char args
float2 text_grid(float2 uv, float2 text_right_top_anchor, float text_height, float aspect_ratio) {
    float font_ratio = float(DCB_FONT_GLYPH_HEIGHT)/float(DCB_FONT_GLYPH_WIDTH);
    return (uv - text_right_top_anchor)*float2(aspect_ratio*font_ratio, 1.0)/text_height + float2(19.0, 0.0);
}

// To ease a rudimentary printf("%d",x) this function we will return decimal digit of rank wanted_digit [0;10[
int int_decode_decimal(in int int_to_decode, in int wanted_digit, in int total_digits) {
#ifdef _OPENGL
	const int pow10_table[10] = int[10](POW10_TABLE_VALUES);
#else
	static int pow10_table[10] = {POW10_TABLE_VALUES};
#endif
	if ( wanted_digit > 9 || (9-wanted_digit) > total_digits) {
        return 12; // ' '
    }
	if ( wanted_digit == 0 ) {
		return int_to_decode<0?13:12; // '-' or ' '
	}
    int pow10_next = pow10_table[10-wanted_digit];
    int pow10_curr = pow10_table[9-wanted_digit];
    return ( abs(int_to_decode) % pow10_next ) / pow10_curr;
}

int2 float_decode_fixed_point_table(float mantissa_pow) {
    /*
     * fixed-point as int2. The first is integer part, the second is fractionnal part.
     *   For negative powers, we use a +9 implied decimal fraction digits.
     *   So, to get the normal representation, divide the table value by 10^9.
     */
#ifdef _OPENGL
	const int pow2_table_pos[30] = int[30](POW2FP_INTEG_TABLE_VALUES);
	const int pow2_table_neg[31] = int[31](POW2FP_FRACT_TABLE_VALUES);
#else
	static int pow2_table_pos[30] = {POW2FP_INTEG_TABLE_VALUES};
	static int pow2_table_neg[31] = {POW2FP_FRACT_TABLE_VALUES};
#endif
    /*
     * Why a table ?
     * First: maybe someone will have a better solution than me (ludolpif, not a professionnal graphics programmer)
     * Second: For some cases, we can skip using a table but not all, doing it may slow down things because of
     *   different code paths (in GPU, funcs are inlined, loops are unrolled, same ASM instr is ran on multiple data)
     * Third: it have to work on HLSL and GLSL.
     *   for strictly positive powers, HLSL allows "1<<(i-1)" but it's not implemented in GLSL
     *   pow(2.0,i) may or may not have precision issues because of float->int conversion of the result
     */
    int i = int(mantissa_pow);
    int2 res;
    if ( i < 30 && i >= 0 ) {
        res = int2(pow2_table_pos[i],0);
    } else if ( i < 0 && i > -31 ) {
        res = int2(0,pow2_table_neg[-i]);
    } else {
        res = int2(0,0);
    }
    return res;
}

float printDCB(float2 vStringCoords, int dcb_digit) {
    // TODO update font extractor script
    // TODO don't make y-mirror and remove the 1.0-y here (or keep it for Shadertoy version?)
#ifdef _OPENGL
	const float font[19] = float[19](DCB_FONT_VALUES);
#else
	static float font[19] = {DCB_FONT_VALUES};
#endif
    float w = float(DCB_FONT_GLYPH_WIDTH);
    float h = float(DCB_FONT_GLYPH_HEIGHT);
    int i = (dcb_digit >= 0 && dcb_digit < 19)?dcb_digit:18;
    return floor(fmod((font[i] / pow(2.0, floor(fract(vStringCoords.x) * w) + (floor((1.0-frac(vStringCoords.y)) * h) * w))), 2.0));
}

void float_decode(in float float_to_decode, in int wanted_digit,
        out int sign, out int exp, out int mant, out float expf, out int2 fixed_point, out int dcb_digit)
{
    // Floats numbers are coded in IEEE754 in a way roughly representable as sign*2^expf*(1+mantissa_fractionnal)
    sign = ( float_to_decode < 0.0 || float_to_decode == -0.0)?-1:1; // note: -0.0 is not < +0.0
    // Before exponent extraction, eliminate special cases on which log2(x) will not be useful
    if ( float_to_decode == 0.0 ) {
        expf = -126.0; exp = 0; mant = 0; fixed_point = int2(0,0);
        dcb_digit = (wanted_digit==8 || wanted_digit==10)?0:(wanted_digit==9?11:12); // for 0.0
        return;
    }
    // remark : !isfinite() whould work in HLSL but not defined in GLSL
    if ( isnan(float_to_decode) || isinf(float_to_decode) ) {
        expf = float_to_decode; // non-finite value as a placeholder
        exp = 255; mant = 0; fixed_point = int2(0,0);
        dcb_digit = (wanted_digit>5 && wanted_digit<9)
            ?isnan(float_to_decode)?10:15
            :(wanted_digit==4 && sign==-1)?13:12; // for +/-NaN or +/-inf
        return;
    }
    // We will transform float_to_decode to conviniently decode it, do it in a copy for clarity
    float float_tmp = abs(float_to_decode);

    // Exponent extraction (for all finite cases)
    expf = floor(log2(float_tmp)); // float exponent without -127 offset (out paraeter)
    int expi = int(expf); // int exponent without -127 offset (internal use)
    exp = expi + 127; // IEEE754 encoded 8bits-wide exponent (out parameter)

    // Extract the mantissa bit per bit, compute the fixed_point value simultaneously
    // using only float values that are exactly represented in IEEE754 encoding (powers of two)
    mant = 0; // IEEE754 23bits-wide mantissa as int without the leading implicit one
    fixed_point = float_decode_fixed_point_table(expi); // Limited range fixed point XXX specifiy the right range
    // The 1 is always implicit in the sense that no bit represent it in the mantissa nor exponent bitfields
    float mantissa_implicit_one = pow(2.0, expf);
    for ( float mantissa_pow = expf-1.0; mantissa_pow > expf-24.0; mantissa_pow -= 1.0 ) {
        mant *= 2;
        float mantissa_fractionnal = pow(2.0, mantissa_pow); // All power of two are exactly representable (mant==0, exp varies)
        float crible = mantissa_implicit_one + mantissa_fractionnal;
        if ( float_tmp >= crible ) {
            float_tmp -= mantissa_fractionnal;
            mant += 1;
            // Fixed point is split into integer part and fractionnal part
            // The way the floats are encoded garantee there is not carry to handle between those two parts
            fixed_point += float_decode_fixed_point_table(mantissa_pow);
            //TODO if expf > 23, no fractionnal part will be encoded (all bits for integer part)
            //TODO if expf > 29, fixed_point should use 1.000000e+30 notation ?
        }
    }
    // Manually round fixed_point from 9 to 8 digits because the 9th digit is not exact with the table we have (and can't put 5e9 in int)
    int to_be_rounded = fixed_point[1];
    if ( to_be_rounded % 10 >= 5 ) to_be_rounded += 10;
    fixed_point[1] = to_be_rounded / 10;

    // To ease a rudimentary printf("%f",x) function we will return in dcb_digit a decimal digit of rank wanted_digit [0;18[
    if ( wanted_digit < 0 || wanted_digit > 18 ) {
        dcb_digit = 12; // for ' '
    } else if ( wanted_digit == 0 ) {
        dcb_digit = (sign==-1)?13:12; // for '-' or '+'
    } else if ( wanted_digit == 10 ) {
        dcb_digit = 11; // for '.'
    } else if ( wanted_digit < 10 ) {
        dcb_digit = int_decode_decimal(fixed_point[0], wanted_digit, 9);
    } else {
        dcb_digit = int_decode_decimal(fixed_point[1], wanted_digit-9, 9);
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
    float2 uv_pixel_to_debug = (coord_mode==0)?float2(pixel_u,pixel_v):float2(pixel_x*upixel, pixel_y*vpixel);

    //float4 rgba_pixel_to_debug = image.Sample(textureSampler, uv_pixel_to_debug);
    float4 rgba = image.Sample(textureSampler, uv);

    //TODO generalise use of underscore and not camel case
    float2 vStringCoords = text_grid(uv, float2(1.0,0.0), font_size, vpixel/upixel);

    float4 debug_color1 = float4(1.0-rgba.rgb, rgba.a);
    float4 debug_color2 = float4(frac(vStringCoords.x), frac(vStringCoords.y), 1.0, 1.0);

    // DCB font test display
    if ( insideBox(vStringCoords, float2(0.0, 0.0), float2(19.0, 1.0) ) ) {
        int wanted_digit = int(vStringCoords.x);
        int dcb_digit = wanted_digit;
        rgba = lerp(rgba, debug_color1, printDCB(vStringCoords, dcb_digit) );
    }

    if ( insideBox(vStringCoords, float2(0.0, 1.0), float2(19.0, 4.0) ) ) {
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
        if ( insideBox(vStringCoords, float2(0.0, 3.0), float2(19.0, 4.0) ) ) {
            rgba = lerp(rgba, debug_color2, printDCB(vStringCoords, dcb_digit) );
        }
        if ( insideBox(vStringCoords, float2(0.0, 1.0), float2(10.0, 2.0) ) ) {
            int dcb_digit2 = int_decode_decimal(mant, wanted_digit, 6);
            rgba = lerp(rgba, debug_color2, printDCB(vStringCoords, dcb_digit2) );
        }
        if ( insideBox(vStringCoords, float2(0.0, 2.0), float2(10.0, 3.0) ) ) {
            float_to_decode = expf;
            float_decode(float_to_decode, wanted_digit, sign, exp, mant, expf, fixed_point, dcb_digit);
            rgba = lerp(rgba, debug_color2, printDCB(vStringCoords, dcb_digit) );
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
