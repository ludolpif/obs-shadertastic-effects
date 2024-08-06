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

/* #include "../../shadertastic-lib/geometry/inside_box.hlsl" */
#ifndef _INSIDE_BOX_HLSL
#define _INSIDE_BOX_HLSL
/**
 * Returns true if v is included in the rectangle defined by left_top (inclusive) and right_bottom (exclusive)
 * Alternative definition : with left_top.x <= right_bottom.x and left_top.y <= right_bottom.y,
 *  it returns ( left_top.x <= v.x < right_bottom.x && left_top.y <= v.y < right_bottom.y )
 * Behavior on limits is tricky if left_top.x > right_bottom.x or left_top.y > right_bottom.y
 * @param v coordinates of a point to test
 * @param left_top coordinates of the top left corner of the rectangle
 * @param right_bottom coordinates of the bottom right corner of the rectangle
 */
bool inside_box(float2 v, float2 left_top, float2 right_bottom) {
    float2 s = step(left_top, v) - step(right_bottom, v);
    return s.x * s.y != 0.0;
}
#endif /* _INSIDE_BOX_HLSL */

/* #include "../../shadertastic-lib/debug/print_value.hlsl" */
#ifndef _PRINT_VALUE_HLSL
#define _PRINT_VALUE_HLSL
/* Inspired from https://www.shadertoy.com/view/3lGBDm ; Licensed under CC BY-NC-SA 3.0
    Font extracted with : zcat /usr/share/fonts/X11/misc/4x6.pcf.gz | pcf2bdf
    See : https://github.com/ludolpif/obs-shadertastic-effects/blob/main/utils/x11-bitmap-font-extractor.sh
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
#ifndef PRINT_VALUE_FONT_GLYPHS
#define PRINT_VALUE_FONT_GLYPH_WIDTH 4
#define PRINT_VALUE_FONT_GLYPH_HEIGHT 6
#define PRINT_VALUE_FONT_GLYPHS \
        /*" "*/ 0.0, \
        /* + */ 4514880.0, \
        /* . */ 4194304.0, \
        /* 0 */ 4909632.0, \
        /* 1 */ 14961728.0, \
        /* 2 */ 14953024.0, \
        /* 3 */ 12731104.0, \
        /* 4 */ 2288288.0, \
        /* 5 */ 12765408.0, \
        /* 6 */ 4900960.0, \
        /* 7 */ 8930016.0, \
        /* 8 */ 13257312.0, \
        /* 9 */ 12741184.0, \
        /* a */ 6989312.0, \
        /* b */ 13282432.0, \
        /* c */ 6850048.0, \
        /* d */ 6989344.0, \
        /* e */ 7119872.0, \
        /* f */ 4514848.0, \
        /* i */ 14991424.0, \
        /* n */ 11185152.0, \
        /* x */ 10766848.0, \
        /* - */ 57344.0, \
        /* ? */ 4211392.0
#endif /* PRINT_VALUE_FONT_GLYPHS */

float2 text_coords_from_uv(in float2 uv, in float2 uv_grid_origin, in float uv_aspect_ratio, in float uv_line_height, in float2 char_offset) {
    float font_ratio = float(PRINT_VALUE_FONT_GLYPH_HEIGHT)/float(PRINT_VALUE_FONT_GLYPH_WIDTH);
    return (uv - uv_grid_origin)*float2(-uv_aspect_ratio*font_ratio, 1.0)/uv_line_height - char_offset*float2(-1.0,1.0);
}

float print_text_grid(in float2 text_coords) {
    float2 line_width = 1.0/float2(PRINT_VALUE_FONT_GLYPH_WIDTH,PRINT_VALUE_FONT_GLYPH_HEIGHT);
    if ( frac(text_coords.x) < line_width.x || frac(text_coords.y) < line_width.y ) {
        return 0.3;
    }
    if ( inside_box(text_coords, float2(0.0, 0.0), float2(1.0, 1.0) ) ) return 0.8;
    return 0.0;
}

// To ease a rudimentary printf("%d",x) this function return the character index to display at wanted_digit position
int int_decode_decimal_fixed(in int int_to_decode, in int wanted_digit, in int total_digits) {
#ifdef _OPENGL
    const int pow10_table[10] = int[10](POW10_TABLE_VALUES);
#else
    static int pow10_table[10] = {POW10_TABLE_VALUES};
#endif
    if ( total_digits < 2 ) total_digits=1;
    int glyph_index = 0; // for ' '
    if ( wanted_digit == total_digits+1 ) {
        glyph_index = int_to_decode<0?22:1; // for '-' or '+'
    } else if ( wanted_digit > 0 && wanted_digit <= total_digits) {
        int pow10_next = pow10_table[wanted_digit];
        int pow10_curr = pow10_table[wanted_digit-1];
        glyph_index = 3 + ( abs(int_to_decode) % pow10_next ) / pow10_curr;
    }
    return glyph_index;
}

int int_decode_decimal(in int int_to_decode, in int wanted_digit) {
    int total_digits = 1 + int(log2(abs(int_to_decode))/log2(10));
    return int_decode_decimal_fixed(int_to_decode, wanted_digit, total_digits);
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

float print_glyph(float2 text_coords, int glyph_index) {
#ifdef _OPENGL
    const float font[24] = float[24](PRINT_VALUE_FONT_GLYPHS);
#else
    static float font[24] = {PRINT_VALUE_FONT_GLYPHS};
#endif
    float w = float(PRINT_VALUE_FONT_GLYPH_WIDTH);
    float h = float(PRINT_VALUE_FONT_GLYPH_HEIGHT);
    int i = (glyph_index >= 0 && glyph_index < 24)?glyph_index:23;
    return floor(fmod(font[i] / pow(2.0, floor( frac(text_coords.x)*w ) + floor( frac(text_coords.y)*h )*w), 2.0));
}

int float_sign(in float float_to_decode) {
    return ( float_to_decode < 0.0 || float_to_decode == -0.0)?-1:1; // note: -0.0 is not < +0.0
}

int float_print_special(in int sign, in int3 glyphs, in int wanted_digit) {
    return
        wanted_digit==2?(sign==-1?22:1): // for '-' or '+'
        wanted_digit==1?glyphs[0]:
        wanted_digit==0?glyphs[1]:
        wanted_digit==-1?glyphs[2]:
        0;
}

void float_decode(in float float_to_decode, in int wanted_digit,
        out int sign, out int exp, out int mant, out float expf, out int2 fixed_point, out int glyph_index)
{
    // Floats numbers are coded in IEEE754 in a way roughly representable as sign*2^expf*(1+mantissa_fractionnal)
    sign = float_sign(float_to_decode);
    // Before exponent extraction, eliminate special cases on which log2(x) will not be useful
    if ( float_to_decode == 0.0 ) {
        expf = -126.0; exp = 0; mant = 0; fixed_point = int2(0,0);
        glyph_index = float_print_special(sign, int3(3,2,3), wanted_digit); // for " +0.0 "
        return;
    }
    if ( isnan(float_to_decode) || isinf(float_to_decode) ) {
        expf = float_to_decode; // non-finite value as a placeholder
        exp = 255; mant = 0; fixed_point = int2(0,0);
        int3 glyphs = isnan(float_to_decode)?int3(20,13,20):int3(19,20,18); // for "nan" or "inf"
        glyph_index = float_print_special(sign, glyphs, wanted_digit);
        return;
    }
    // We will transform float_to_decode to conveniently decode it, do it in a copy for clarity
    float float_tmp = abs(float_to_decode);

    // Exponent extraction (for all finite cases)
    expf = floor(log2(float_tmp)); // float exponent without -127 offset (out parameter)
    int expi = int(expf); // int exponent without -127 offset (internal use)
    exp = expi + 127; // IEEE754 encoded 8bits-wide exponent (out parameter)

    // Extract the mantissa bit per bit, compute the fixed_point value simultaneously
    // using only float values that are exactly represented in IEEE754 encoding (powers of two)
    mant = 0; // IEEE754 23bits-wide mantissa as int without the leading implicit one
    //fixed_point: limited range fixed point representation with 8 decimals for floats in [-10e9-1 ; 10e9-1]
    fixed_point = float_decode_fixed_point_table(expi);
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
    //TODO may the use want to round are arbitraty number of digit, allow it
    // Manually round fixed_point fractionnal part from 9 to 8 digits because the 9th digit
    //  is not always exact with the table we use (and we can't put 5e9 in int)
    int to_be_rounded = fixed_point[1];
    if ( to_be_rounded % 10 >= 5 ) to_be_rounded += 10;
    fixed_point[1] = to_be_rounded / 10;

    // To ease a rudimentary printf("%f",x) this function output glyph_index, the character index to display at wanted_digit position
    if ( wanted_digit < -8 || wanted_digit > 11 ) {
        glyph_index = 0; // for ' '
    } else if ( wanted_digit > 0 ) {
        glyph_index = int_decode_decimal(sign*fixed_point[0], wanted_digit);
    } else if ( wanted_digit == 0 ) {
        glyph_index = 2; // for '.'
    } else /* ( wanted_digit < 0 ) */ {
        glyph_index = int_decode_decimal_fixed(fixed_point[1], wanted_digit+9, 8);
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

    float4 rgba_pixel_to_debug = image.Sample(textureSampler, uv_pixel_to_debug);
    float4 rgba = image.Sample(textureSampler, uv);

    float4 debug_color0 = float4(0.0, 0.0, 0.0, 1.0);
    float4 debug_color1 = float4(1.0-rgba.rgb, rgba.a);
    float4 debug_color2 = float4(1.0, 0.0, 0.0, 1.0);

    //TODO lerp() is bad for mixing with alpha as used for now
    float2 text_coords = text_coords_from_uv(uv, float2(0.5,0.0), vpixel/upixel, font_size, float2(0.0,1.0) );

    if ( inside_box(text_coords, float2(-12.0, 0.0), float2(12.25, 8.166) ) ) {
        rgba = lerp(rgba, debug_color0, print_text_grid(text_coords));
    }

    // font test display
    if ( inside_box(text_coords, float2(-12.0, 0.0), float2(12.0, 1.0) ) ) {
        int wanted_digit = int(12-text_coords.x);
        int glyph_index = wanted_digit;
        rgba = lerp(rgba, debug_color2, print_glyph(text_coords, glyph_index) );
    }

    if ( inside_box(text_coords, float2(-8.0, 1.0), float2(11.0, 6.0) ) ) {
        // float_decode() in:
        float float_to_decode = debug_value;
        //float float_to_decode = time;
        int wanted_digit = text_coords.x>0.0?int(text_coords.x):int(text_coords.x)-1; // TODO try to simplify ?
        // float_decode() out:
        int sign, exp, mant, glyph_index;
        float expf;
        int2 fixed_point;
        // float_decode() call:
        float_decode(float_to_decode, wanted_digit, sign, exp, mant, expf, fixed_point, glyph_index);
        // displaying parts of the result
        if ( inside_box(text_coords, float2(-8.0, 3.0), float2(11.0, 4.0) ) ) {
            rgba = lerp(rgba, debug_color2, print_glyph(text_coords, glyph_index) );
        }
        if ( inside_box(text_coords, float2(1.0, 1.0), float2(9.0, 2.0) ) ) {
            glyph_index = int_decode_decimal(mant, wanted_digit);
            rgba = lerp(rgba, debug_color2, print_glyph(text_coords, glyph_index) );
        }
        if ( inside_box(text_coords, float2(1.0, 2.0), float2(5.0, 3.0) ) ) {
            glyph_index = int_decode_decimal(int(expf), wanted_digit);
            rgba = lerp(rgba, debug_color2, print_glyph(text_coords, glyph_index) );
        }
        if ( inside_box(text_coords, float2(-8.0, 4.0), float2(11.0, 5.0) ) ) {
            float_to_decode = -1.0/0.0; // Should be -inf
            float_decode(float_to_decode, wanted_digit, sign, exp, mant, expf, fixed_point, glyph_index);
            rgba = lerp(rgba, debug_color2, print_glyph(text_coords, glyph_index) );
        }
        if ( inside_box(text_coords, float2(-8.0, 5.0), float2(11.0, 6.0) ) ) {
            float_to_decode = sqrt(-1.0); // Maybe +nan (GLSL) or +1 (HLSL WTF)
            float_decode(float_to_decode, wanted_digit, sign, exp, mant, expf, fixed_point, glyph_index);
            rgba = lerp(rgba, debug_color2, print_glyph(text_coords, glyph_index) );
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
