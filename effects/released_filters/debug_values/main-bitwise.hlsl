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
*/
// int font_width = 4;
// int font_height = 6;
float printValue_digitBin(int x) {
    return (
        /* . */ x==46?32.0:
        /* 0 */ x==48?2454816.0:
        /* 1 */ x==49?2302576.0:
        /* 2 */ x==50?2441840.0:
        /* 3 */ x==51?7611440.0:
        /* 4 */ x==52?5600320.0:
        /* 5 */ x==53?7418928.0:
        /* 6 */ x==54?6370592.0:
        /* 7 */ x==55?7610640.0:
        /* 8 */ x==56?6628656.0:
        /* 9 */ x==57?2450480.0:
        /* ? */ x==63?3416096.0:
        /* a */ x==97?415072.0:
        /* b */ x==98?1266992.0:
        /* c */ x==99?397664.0:
        /* d */ x==100?4609376.0:
        /* e */ x==101?152416.0:
        /* f */ x==102?4354592.0:
        /* g */ x==103?415299.0:
        /* h */ x==104?1267024.0:
        /* i */ x==105?2110064.0:
        /* j */ x==106?4211779.0:
        /* k */ x==107?1389904.0:
        /* l */ x==108?3285616.0:
        /* m */ x==109?357712.0:
        /* n */ x==110?218448.0:
        /* o */ x==111?152864.0:
        /* p */ x==112?217873.0:
        /* q */ x==113?415076.0:
        /* r */ x==114?340240.0:
        /* s */ x==115?406576.0:
        /* t */ x==116?2564672.0:
        /* u */ x==117?349536.0:
        /* v */ x==118?349472.0:
        /* w */ x==119?350032.0:
        /* x */ x==120?336464.0:
        /* y */ x==121?349763.0:
        /* z */ x==122?475760.0:
        /* - */ x==45?28672.0:
        /* default: ? */ 3416096.0
    );
}
/*
    Each magic number represents all bits in a grid of size font_width*font_height
    HLSL functions mostly need floats. IEEE754 single precision floats have 24 bits for mantissa.
    So, maximum font size is 6x4 with this encoding. For more, use double (51 bits) or a proper texture.
    The chosen encoding use exponent = 0, so the mantissa and the standard int encoding are the same.
    Example with '7' : float 7610640.0. Take the int32 encoding of 7610640, as binary :
    7610640 <=> 0000 0000 0111 0100 0010 0001 0001 0000
    Each group of font_width bits is a line of the character, keep only the font_height last lines
    0111
    0100
    0010
    0001
    0001
    0000
    Mirror horizontally
    1110
    0010
    0100
    1000
    1000
    0000
*/

/**
 * Print a numerical value in the rectangle with it top-right at the coordinates uv
 * @param uv coordinates of the top right pixel of the debug area, in UV coordinates
 * @param value numerical value to print
 * @param nbDecimal number of decimals to print
 * @param fontSize size of the font, 1.0 meaning the full height of the image texture
 * @return true if the pixel located at uv is a debug pixel, false otherwise
 * @example
 * // float2(1.0, 0.0) is top right uv coordinate of the image
 * if (printValue(uv, 42.23, float2(1.0, 0.0), 3, 0.2)) {
 *     // current pixel is a debug one, print it as full red
 *     return float4(1.0, 0.0, 0.0, 1.0);
 * }
 * else {
 *     // actual shader code
 * }
 */
bool printValue(float2 uv, float value_to_debug, float2 area_topRight, int nbDecimal, float fontSize) {
    nbDecimal = max(0, nbDecimal);
    if ((uv.y < 0.0) || (uv.y >= 1.0) || (uv.x < 0.0) || (uv.x >= 1.0)) {
        return false;
    }
    int font_width = 4;
    int font_height = 6;

    bool isNegative = (value_to_debug < 0.0);
    bool hasDecimals = (nbDecimal > 0);
    value_to_debug = abs(value_to_debug);
    float log10Value = log2(abs(value_to_debug)) / log2(10.0);
    int biggestIndex = int(max(0.0, floor(max(log10Value, 0.0))));

    float square_height = fontSize / font_height;
    float square_width = square_height * upixel/vpixel;

    float area_height = font_height * square_height;
    float area_width = font_width * square_width * (nbDecimal + (hasDecimals ? 1 : 0) + (1 + biggestIndex) + (isNegative ? 1 : 0));
    float2 area_bottomLeft = area_topRight + float2(-area_width, area_height);

    if (insideBox(uv, area_topRight, area_bottomLeft)) {
        uv -= float2(area_bottomLeft.x, area_topRight.y);
        int square_u = int(uv.x / square_width);
        int square_v = int(uv.y / square_height);

        int digitIndex = square_u / font_width;
        int digit_u = square_u - digitIndex * font_width;

        float digitBin = 0.0;
        if (isNegative) {
            digitIndex--;
        }
        if (isNegative && digitIndex == -1) {
            digitBin = printValue_digitBin(45);
        }
        else if (hasDecimals && digitIndex == biggestIndex + 1) {
            digitBin = printValue_digitBin(46);
        }
        else {
            if (hasDecimals && digitIndex > biggestIndex) {
                digitIndex--;
                value_to_debug = fract( value_to_debug );
            }
            int currentDigitNegativeIndex = digitIndex-biggestIndex;
            float currentDigitFloat = fmod(value_to_debug * pow(10.0, currentDigitNegativeIndex), 10.0);
            int currentDigit;
            if ( (digitIndex == biggestIndex + nbDecimal) && (currentDigitFloat < 9.0) ) {
                currentDigit = int(round(currentDigitFloat));
            }
            else {
                currentDigit = int(currentDigitFloat);
            }
            digitBin = printValue_digitBin(48+currentDigit);
        }

        return fmod(digitBin / pow(2.0, (font_height-square_v) * font_width + digit_u), 2.0) >= 1.0;
    }

    return false;
}

//FIXME finir le passage de uv à vStringCoords
float printDCB(float2 vStringCoords, int dcb_digit) {
    float font_width = 4.0;
    float font_height = 6.0;
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

    int char_idx = ( dcb_digit >= 0 && dcb_digit < 20)?dcb_digit:19;
    return floor(mod((font[char_idx] / pow(2.0, floor(fract(vStringCoords.x) * font_width) + (floor((1.0-vStringCoords.y) * font_height) * font_width))), 2.0));
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

int float_decode_pow10_table(int expf) {
	return
        expf==9?1000000000:
        expf==8?100000000:
        expf==7?10000000:
        expf==6?1000000:
        expf==5?100000:
        expf==4?10000:
        expf==3?1000:
        expf==2?100:
        expf==1?10:
        expf==0?1:
		0;
}

int2 float_decode_fixed_point_table(float expf) {
    return
		expf>0.0?int2(int(pow(2.0,expf)),0): // Not exact if pow > 23 ?
		/*
        expf==+29.0?int2(536870912,0):
        expf==+28.0?int2(268435456,0):
        expf==+27.0?int2(134217728,0):
        expf==+26.0?int2(67108864,0):
        expf==+25.0?int2(33554432,0):
        expf==+24.0?int2(16777216,0):
        expf==+23.0?int2(8388608,0):
        expf==+22.0?int2(4194304,0):
        expf==+21.0?int2(2097152,0):
        expf==+20.0?int2(1048576,0):
        expf==+19.0?int2(524288,0):
        expf==+18.0?int2(262144,0):
        expf==+17.0?int2(131072,0):
        expf==+16.0?int2(65536,0):
        expf==+15.0?int2(32768,0):
        expf==+14.0?int2(16384,0):
        expf==+13.0?int2(8192,0):
        expf==+12.0?int2(4096,0):
        expf==+11.0?int2(2048,0):
        expf==+10.0?int2(1024,0):
        expf==+ 9.0?int2(512,0):
        expf==+ 8.0?int2(256,0):
        expf==+ 7.0?int2(128,0):
        expf==+ 6.0?int2(64,0):
        expf==+ 5.0?int2(32,0):
        expf==+ 4.0?int2(16,0):
        expf==+ 3.0?int2(8,0):
        expf==+ 2.0?int2(4,0):
        expf==+ 1.0?int2(2,0):*/
        expf==+ 0.0?int2(1,0):
        expf==- 1.0?int2(0,500000000):
        expf==- 2.0?int2(0,250000000):
        expf==- 3.0?int2(0,125000000):
        expf==- 4.0?int2(0, 62500000):
        expf==- 5.0?int2(0, 31250000):
        expf==- 6.0?int2(0, 15625000):
        expf==- 7.0?int2(0,  7812500):
        expf==- 8.0?int2(0,  3906250):
        expf==- 9.0?int2(0,  1953125):
        expf==-10.0?int2(0,   976562):
        expf==-11.0?int2(0,   488281):
        expf==-12.0?int2(0,   244141):
        expf==-13.0?int2(0,   122070):
        expf==-14.0?int2(0,    61035):
        expf==-15.0?int2(0,    30518):
        expf==-16.0?int2(0,    15259):
        expf==-17.0?int2(0,     7629):
        expf==-18.0?int2(0,     3815):
        expf==-19.0?int2(0,     1907):
        expf==-20.0?int2(0,      954):
        expf==-21.0?int2(0,      477):
        expf==-22.0?int2(0,      238):
        expf==-23.0?int2(0,      119):
        expf==-24.0?int2(0,       60):
        expf==-25.0?int2(0,       30):
        expf==-26.0?int2(0,       15):
        expf==-27.0?int2(0,        7):
        expf==-28.0?int2(0,        4):
        expf==-29.0?int2(0,        2):
        expf==-30.0?int2(0,        1):
        int2(0,0);
}

// dcb_digit is encoded with some extensions to 4-bits DCB: 0-9:digit, 10:NaN, 11:'.', 12:' ', 13:'-', 14:'e', 15:inf
int float_decode(in float x, in int wanted_digit, out int exp, out int sign, out float expf, out int2 fixed_point, out int dcb_digit)
{
    // Floats numbers are coded in IEEE754 in a way roughly representable as sign*2^expf*(1+mantissa_fractionnal)
	// sign extraction then work only with positive numbers everywhere
	sign = (x<0.f || x==-0.f)?-1:1; // note: -0.0 is not < +0.0 
    x = abs(x);
    // Before exponent extraction, eliminate special cases on which log2(x) will not be useful
    if ( x == 0 ) {
        expf = -126.0;
        exp = 0; 
        fixed_point = int2(0,0);
        dcb_digit = (wanted_digit==8 || wanted_digit==10)?0:(wanted_digit==9?11:12); // for 0.0
        return 0;
    }
    if ( isnan(x) || isinf(x) ) {
        expf = x;
        exp = 255;
        fixed_point = int2(0,0);
		dcb_digit = (wanted_digit>5 && wanted_digit<9)?(isnan(x)?10:15):((wanted_digit==4 && sign==-1)?13:12); // for +/-NaN or +/-inf
        return 0;
    }
    expf = floor(log2(x)); // float exponent without -127 offset
    exp = int(expf)+127; // IEEE754 encoded 8bits-wide exponent

	// Extract the mantissa bit per bit, compute the fixed_point value simultaneously
	// using only float values that are exactly represented in IEEE754 encoding (powers of two)
    int extracted_mantissa = 0; // IEEE754 23bits-wide mantissa as int
    fixed_point = float_decode_fixed_point_table(expf); // Limited range fixed point XXX specifiy the right range
    // The 1 is always implicit in the sense that no bit represent it in the mantissa nor exponent bitfields
    float mantissa_implicit_one = pow(2.0, expf);
    for ( float mantissa_pow = expf-1.0; mantissa_pow > expf-24.0; mantissa_pow -= 1.0 ) {
        extracted_mantissa *= 2;
        float mantissa_fractionnal = pow(2.0, mantissa_pow);
        float crible = mantissa_implicit_one + mantissa_fractionnal;
        if ( x >= crible ) {
            x -= mantissa_fractionnal;
            extracted_mantissa += 1;
			// Fixed point is split into integer part and fractionnal part
			// The way the floats are encoded garantee there is not carry to handle between those two parts
            fixed_point += float_decode_fixed_point_table(mantissa_pow);
        }
    }
	// To ease a rudimentary printf("%f",x) function we will return in dcb_digit a decimal digit of rank wanted_digit [0;18[
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
		int pow10_next = float_decode_pow10_table(9-wanted_digit);
		int pow10_curr = float_decode_pow10_table(8-wanted_digit);
		dcb_digit = ( fixed_point[0] % pow10_next ) / pow10_curr;
	} else {
		int pow10_next = float_decode_pow10_table(19-wanted_digit);
		int pow10_curr = float_decode_pow10_table(18-wanted_digit);
		dcb_digit = ( fixed_point[1] % pow10_next ) / pow10_curr;
	}
    return extracted_mantissa;
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
        mant = float_decode(float_to_decode, wanted_digit, exp, sign, expf, fixed_point, dcb_digit);
        // displaying parts of the result
        if ( printDCB(vStringCoords, dcb_digit) == 1.0 ) {
            return color_red;
        }
    }

    // First example : print a uniform variable with 3 decimals at top right corner of the image
    // (note : you can't print value that depends on pixel shader's uv)
    if ( printValue(uv, debug_value, float2(1.0, 0.8), 3, font_size) ) {
        return color_cyan;
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
