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
#ifndef PRINT_VALUE_FONT_GLYPHS
#define PRINT_VALUE_FONT_GLYPH_WIDTH 4
#define PRINT_VALUE_FONT_GLYPH_HEIGHT 6
#define PRINT_VALUE_FONT_GLYPHS \
        /*" "*/ 0.0, \
        /* + */ 320512.0, \
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
/* Note : '+' is 4514880.0 from the x11 font + script, but it's ugly, manually changed here. */

//TODO make all javadoc style explanation of all functions and parameters
//TODO choose a common prefix to not pollute namespace, add guards as if each func will be in a separate file in lib
//TODO text position depends on font_size somehow
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

bool print_glyph(float2 text_coords, int glyph_index) {
#ifdef _OPENGL
    const float font[24] = float[24](PRINT_VALUE_FONT_GLYPHS);
#else
    static float font[24] = {PRINT_VALUE_FONT_GLYPHS};
#endif
    float w = float(PRINT_VALUE_FONT_GLYPH_WIDTH);
    float h = float(PRINT_VALUE_FONT_GLYPH_HEIGHT);
    int i = (glyph_index >= 0 && glyph_index < 24)?glyph_index:23;
    return fmod(font[i] / pow(2.0, floor( frac(text_coords.x)*w ) + floor( frac(text_coords.y)*h )*w), 2.0) >= 1.0;
}

int print_float_special_values(in int sign, in int3 glyphs, in int wanted_digit) {
    return
        wanted_digit==2?(sign==-1?22:1): // for '-' or '+'
        wanted_digit==1?glyphs[0]:
        wanted_digit==0?glyphs[1]:
        wanted_digit==-1?glyphs[2]:
        0;
}

// To ease a rudimentary printf("%d",x) this function return the character index to display at wanted_digit position
int decode_int_decimal_fixed(in int int_to_decode, in int wanted_digit, in int total_digits) {
#ifdef _OPENGL
    const int pow10_table[10] = int[10](POW10_TABLE_VALUES);
#else
    static int pow10_table[10] = {POW10_TABLE_VALUES};
#endif
    int glyph_index = 0; // for ' '
    if ( total_digits < 2 ) total_digits=1;
    if ( wanted_digit == total_digits ) {
        glyph_index = int_to_decode<0?22:1; // for '-' or '+'
    } else if ( wanted_digit >= 0 && wanted_digit < total_digits) {
        int pow10_next = pow10_table[wanted_digit+1];
        int pow10_curr = pow10_table[wanted_digit];
        glyph_index = 3 + ( abs(int_to_decode) % pow10_next ) / pow10_curr;
    }
    return glyph_index;
}

int decode_int_decimal(in int int_to_decode, in int wanted_digit) {
    // Note: total_digits estimation is not always exact, may a leading 0 could appear
    int total_digits = 1 + int(log2(abs(int_to_decode))/log2(10));
    return decode_int_decimal_fixed(int_to_decode, wanted_digit, total_digits);
}

//TODO add decode_int_hex() and decode_int_binary()
// To ease a rudimentary printf("%x",x) this function return the character index to display at wanted_digit position
int decode_int_hexadecimal_fixed(in int int_to_decode, in int wanted_digit, in int total_digits) {
    int glyph_index = 0; // for ' '
    if ( total_digits < 2 ) total_digits=1;
    if ( wanted_digit == total_digits+1 ) {
        glyph_index = 3; // for '0'
    } else if ( wanted_digit == total_digits ) {
        glyph_index = 21; // for 'x'
    } else if ( wanted_digit >= 0 && wanted_digit < total_digits) {
        glyph_index = 3 + (int_to_decode >> (wanted_digit*4)) % 16; // for [0-9a-f]
    }
    return glyph_index;
}
int decode_int_binary_fixed(in int int_to_decode, in int wanted_digit, in int total_digits) {
    int glyph_index = 0; // for ' '
    if ( total_digits < 2 ) total_digits=1;
    if ( wanted_digit == total_digits+1 ) {
        glyph_index = 3; // for '0'
    } else if ( wanted_digit == total_digits ) {
        glyph_index = 14; // for 'b'
    } else if ( wanted_digit >= 0 && wanted_digit < total_digits) {
        glyph_index = 3 + (int_to_decode >> wanted_digit) % 2; // for '0' or '1'
    }
    return glyph_index;
}

int decode_float_sign(in float float_to_decode) {
    return
        float_to_decode < 0.0?-1:
        float_to_decode > 0.0?1:
        (1.0 / float_to_decode < 1.0)?-1:
        1; // note: -0.0 is not < +0.0 if using comparison operators
}

/*
 * fixed-point as int2. The first is integer part, the second is fractionnal part.
 *   For negative powers, we use a +9 implied decimal fraction digits.
 *   So, to get the normal representation, divide the table value by 10^9.
 */
int2 decode_float_mantissa_to_fixed_point(float mantissa_pow) {
    int fpart = int(max(0.0, -mantissa_pow));
    int ipart = int(max(0.0, mantissa_pow));
    return int2( 1 << ipart >> fpart, (1000000000 >> fpart)%1000000000);
}

void decode_float(in float float_to_decode, in int wanted_digit,
        out int sign, out int exp, out int mant, out float expf, out int2 fixed_point, out int glyph_index)
{
    // Floats numbers are coded in IEEE754 in a way roughly representable as sign*2^expf*(1+mantissa_fractionnal)
    sign = decode_float_sign(float_to_decode);
    // Before exponent extraction, eliminate special cases on which log2(x) will not be useful
    if ( float_to_decode == 0.0 ) {
        expf = -126.0; exp = 0; mant = 0; fixed_point = int2(0,0);
        glyph_index = print_float_special_values(sign, int3(3,2,3), wanted_digit); // for " +0.0 "
        return;
    }
    if ( isnan(float_to_decode) || isinf(float_to_decode) ) {
        expf = float_to_decode; // non-finite value as a placeholder
        exp = 255; mant = 0; fixed_point = int2(0,0);
        int3 glyphs = isnan(float_to_decode)?int3(20,13,20):int3(19,20,18); // for "nan" or "inf"
        glyph_index = print_float_special_values(sign, glyphs, wanted_digit);
        return;
    }
    // We will transform float_to_decode to conveniently decode it, do it in a copy for clarity
    float float_tmp = abs(float_to_decode);

    // Exponent extraction (for all finite cases)
    expf = floor(log2(float_tmp)); // float exponent without -127 offset (out parameter)
    exp = int(expf) + 127; // IEEE754 encoded 8bits-wide exponent (out parameter)

    // Extract the mantissa bit per bit, compute the fixed_point value simultaneously
    // using only float values that are exactly represented in IEEE754 encoding (powers of two)
    mant = 0; // IEEE754 23bits-wide mantissa as int without the leading implicit one
    //fixed_point: limited range fixed point representation with 8 decimals for floats in [-10e9-1 ; 10e9-1]
    fixed_point = decode_float_mantissa_to_fixed_point(expf);
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
            fixed_point += decode_float_mantissa_to_fixed_point(mantissa_pow);
            //TODO if expf > 23, no fractionnal part will be encoded (all bits for integer part)
            //TODO if expf > 29, fixed_point should use 1.000000e+30 notation ?
        }
    }
    //TODO may the user want to round are arbitraty number of digit, allow it
    // Manually round fixed_point fractionnal part from 9 to 8 digits because the 9th digit
    //  is not always exact with the table we use (and we can't put 5e9 in int)
    int to_be_rounded = fixed_point[1];
    if ( to_be_rounded % 10 >= 5 ) to_be_rounded += 10;
    fixed_point[1] = to_be_rounded / 10;

    // To ease a rudimentary printf("%f",x) this function output glyph_index, the character index to display at wanted_digit position
    if ( wanted_digit < -8 || wanted_digit > 11 ) {
        glyph_index = 0; // for ' '
    } else if ( wanted_digit > 0 ) {
        glyph_index = decode_int_decimal(sign*fixed_point[0], wanted_digit-1);
    } else if ( wanted_digit == 0 ) {
        glyph_index = 2; // for '.'
    } else /* ( wanted_digit < 0 ) */ {
        glyph_index = decode_int_decimal_fixed(fixed_point[1], wanted_digit+8, 8);
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

    float4 debug_color2 = float4(1.0, 0.0, 0.0, 1.0);

    float2 text_coords = text_coords_from_uv(uv, float2(0.5,0.0), vpixel/upixel, font_size, float2(0.0,1.0) );

    //TODO explain .25 and .166 or use the right constants
    if ( inside_box(text_coords, float2(-12.0, 0.0), float2(13.25, 9.166) ) ) {
        rgba = lerp(rgba, float4(0.0,0.0,0.0,1.0), print_text_grid(text_coords));
    }

    // font test display
    if ( inside_box(text_coords, float2(-12.0, 0.0), float2(12.0, 1.0) ) ) {
        int glyph_index = int(12-text_coords.x);
        rgba = print_glyph(text_coords, glyph_index)?debug_color2:rgba;
    }

    // decode_float() in:
    float float_to_decode = debug_value + time;
    int wanted_digit = int(round(text_coords.x-0.5));
    // wanted_digit: floor() will make a double wanted_digit==0 for text_coords in [-1.0;1.0], round() will not
    // decode_float() out:
    int sign, exp, mant, glyph_index;
    float expf;
    int2 fixed_point;
    // decode_float() call only when needed
    if ( inside_box(text_coords, float2(-12.0, 1.0), float2(13.0, 6.0) ) ) {
        decode_float(float_to_decode, wanted_digit, sign, exp, mant, expf, fixed_point, glyph_index);
        // displaying result
        if ( inside_box(text_coords, float2(-8.0, 1.0), float2(12.0, 2.0) ) ) {
            rgba = print_glyph(text_coords, glyph_index)?debug_color2:rgba;
        }
        // and inner details as an API demo
        if ( inside_box(text_coords, float2(0.0, 2.0), float2(8.0, 3.0) ) ) {
            glyph_index = decode_int_decimal(mant, wanted_digit);
            rgba = print_glyph(text_coords, glyph_index)?debug_color2:rgba;
        }
        if ( inside_box(text_coords, float2(-12.0, 3.0), float2(13.0, 4.0) ) ) {
            glyph_index = decode_int_binary_fixed(mant, wanted_digit+12, 23);
            rgba = print_glyph(text_coords, glyph_index)?debug_color2:rgba;
        }
        if ( inside_box(text_coords, float2(0.0, 4.0), float2(8.0, 5.0) ) ) {
            glyph_index = decode_int_hexadecimal_fixed(mant, wanted_digit, 6);
            rgba = print_glyph(text_coords, glyph_index)?debug_color2:rgba;
        }
        if ( inside_box(text_coords, float2(0.0, 5.0), float2(4.0, 6.0) ) ) {
            glyph_index = decode_int_decimal(exp, wanted_digit);
            rgba = print_glyph(text_coords, glyph_index)?debug_color2:rgba;
        }
    }

    // Decoding for special float values should work too
    if ( inside_box(text_coords, float2(-8.0, 6.0), float2(11.0, 7.0) ) ) {
        float_to_decode = -1.0/0.0; // Should be -inf
        decode_float(float_to_decode, wanted_digit, sign, exp, mant, expf, fixed_point, glyph_index);
        rgba = print_glyph(text_coords, glyph_index)?debug_color2:rgba;
    }
    if ( inside_box(text_coords, float2(-8.0, 7.0), float2(11.0, 8.0) ) ) {
        float_to_decode = sqrt(-1.0); // Maybe +nan
        decode_float(float_to_decode, wanted_digit, sign, exp, mant, expf, fixed_point, glyph_index);
        rgba = print_glyph(text_coords, glyph_index)?debug_color2:rgba;
    }
    if ( inside_box(text_coords, float2(-8.0, 8.0), float2(11.0, 9.0) ) ) {
        float_to_decode = -0.0; // -0.0 == 0.0 when compared but it's a different binary representation
        decode_float(float_to_decode, wanted_digit, sign, exp, mant, expf, fixed_point, glyph_index);
        rgba = print_glyph(text_coords, glyph_index)?debug_color2:rgba;
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
