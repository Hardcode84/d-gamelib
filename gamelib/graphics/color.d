module gamelib.graphics.color;

import std.traits;
import std.algorithm;
import std.range;
import std.typetuple;

import gamelib.math;
import gamelib.types;

struct Color(bool bgra = false)
{
pure nothrow:
    import std.string;
    static if(bgra)
    {
        ubyte b = 255;
        ubyte g = 255;
        ubyte r = 255;
        ubyte a = SDL_ALPHA_OPAQUE;
    }
    else
    {
        ubyte r = 255;
        ubyte g = 255;
        ubyte b = 255;
        ubyte a = SDL_ALPHA_OPAQUE;
    }
    //enum format = SDL_PIXELFORMAT_RGBA8888;
    static if(bgra)
    {
        enum uint bmask = 0x000000ff;
        enum uint gmask = 0x0000ff00;
        enum uint rmask = 0x00ff0000;
        enum uint amask = 0xff000000;
    }
    else
    {
        enum uint rmask = 0x000000ff;
        enum uint gmask = 0x0000ff00;
        enum uint bmask = 0x00ff0000;
        enum uint amask = 0xff000000;
    }

    private void assign(U)(in U x)
    {
        static if(isColor!U)
        {
            foreach(c;TypeTuple!('r','g','b','a'))
            {
                mixin(format("%1$s = x.%1$s;",c));
            }
        }
        else static if(isTemplateColor!U)
        {
            foreach(c;TypeTuple!('r','g','b','a'))
            {
                mixin("enum HasProp = (U."~c~"mask != 0);");
                static if(HasProp)
                {
                    uint value;
                    mixin("value = x."~c~";");
                    value *= 255;
                    mixin("value /= U."~c~"max;");
                    assert(value <= 255);
                    mixin(format("%1$s = cast(ubyte)value;",c));
                }
            }
        }
        else
        {
            static assert(false);
        }
    }

    ref Color opAssign(U)(in U x)
    {
        assign(x);
        return this;
    }

    static Color lerp(T)(in Color col1, in Color col2, in T coeff)
    {
        assert(coeff >= (0), debugConv(coeff));
        assert(coeff <= (1), debugConv(coeff));
        Color ret;
        foreach(c;TypeTuple!('r','g','b'))
        {
            enum str = format("ret.%1$s = cast(ubyte)(col2.%1$s*(cast(T)1 - coeff) + col1.%1$s*coeff);",c);
            mixin(str);
        }
        return ret;
    }

    auto distanceSquared(in Color col) const
    {
        return (r - col.r)^^2 + (g - col.g)^^2 + (b - col.b)^^2 + (a - col.a)^^2;
    }

    auto distance(in Color col) const
    {
        return sqrt(distanceSquared(col));
    }

    auto toRaw() const
    {
        static assert(this.sizeof == uint.sizeof);
        union U
        {
            Color c;
            uint i;
        }
        U u = void;
        u.c = this;
        return u.i;
    }
    static auto fromRaw(in uint i)
    {
        union U
        {
            Color c;
            uint i;
        }
        U u = void;
        u.i = i;
        return u.c;
    }
    auto opBinary(string op : "+")(in Color rhs) const
    {
        return fromRaw(toRaw() + rhs.toRaw());
    }

    auto opBinary(string op : "*",T)(in T rhs) const if(isFloatingPoint!T || isIntegral!T)
    {
        Color ret;
        foreach(c;TypeTuple!('r','g','b'))
        {
            enum str = format("ret.%1$s = cast(ubyte)(%1$s*rhs);",c);
            mixin(str);
        }
        return ret;
    }

    auto opBinary(string op : "*",T)(in T rhs) const if(isColor!T || isTemplateColor!T)
    {
        Color src;
        src = rhs;
        Color ret;
        foreach(c;TypeTuple!('r','g','b'))
        {
            mixin(format("const val = (%1$s*rhs.%1$s/255);",c));
            assert(val >= 0 && val < 256, debugConv(val));
            mixin(format("ret.%1$s = cast(ubyte)val;",c));
        }
        return ret;
    }

    static Color average(in Color col1,in Color col2)
    {
        return Color.fromRaw(((col1.toRaw() & 0xfefefefe) >> 1) +
            ((col2.toRaw() & 0xfefefefe) >> 1));
    }

    @nogc static void interpolateLine(int LineSize, Rng)(Rng rng, in Color col1, in Color col2)
    if(isRandomAccessRange!Rng)
    {
        /*foreach(i;0..LineSize)
        {
            rng[i] = lerp(col2,col1, cast(float)i / cast(float)LineSize);
        }*/
        static if(8 == LineSize) //hack
        {
            rng[0] = col1;
            rng[4] = average(col1,col2);
            rng[2] = average(col1,rng[4]);
            rng[1] = average(col1,rng[2]);
            rng[3] = average(rng[2],rng[4]);
            rng[6] = average(rng[4],col2);
            rng[5] = average(rng[4],rng[6]);
            rng[7] = average(rng[6],col2);
        }
        else static if(LineSize > 1)
        {
            enum pos = LineSize / 2;
            rng[pos] = average(col1,col2);
            interpolateLine!(pos)(rng[0..pos],col1,rng[pos]);
            interpolateLine!(LineSize - pos)(rng[pos..$],rng[pos],col2);
        }
        else
        {
            rng[0] = average(col1,col2);
        }
    }

    @nogc static void interpolateLine(Rng)(int lineSize, Rng rng, in Color col1, in Color col2)
    if(isRandomAccessRange!Rng)
    {
        assert(lineSize >= 0);
        alias fn_pt = typeof(&interpolateLine!(0,Rng));
        static immutable fn_pt[9] f = [
            &interpolateLine!(0,Rng),
            &interpolateLine!(1,Rng),
            &interpolateLine!(2,Rng),
            &interpolateLine!(3,Rng),
            &interpolateLine!(4,Rng),
            &interpolateLine!(5,Rng),
            &interpolateLine!(6,Rng),
            &interpolateLine!(7,Rng),
            &interpolateLine!(8,Rng),];
        if(lineSize <= 8)
        {
            f[lineSize](rng, col1, col2);
        }
        else
        {
            interpolateLineImpl(lineSize, rng, col1, col2);
        }
    }

    @nogc private static void interpolateLineImpl(Rng)(int lineSize, Rng rng, in Color col1, in Color col2)
    if(isRandomAccessRange!Rng)
    {
        /*foreach(i;0..lineSize)
        {
            rng[i] = lerp(col2,col1, cast(float)i / cast(float)lineSize);
        }*/
        if(lineSize <= 1) return;
        const center = lineSize / 2;
        const col = average(col1, col2);
        rng[center] = col;
        interpolateLine(center, rng[0..center],col1,col);
        interpolateLine(lineSize - center, rng[center..$],col ,col2);
    }
}

private void isColorImpl(bool b)(in Color!b c) {}

template isColor(T) {
    enum isColor = is(typeof(isColorImpl(T.init)));
}

unittest
{
    static assert(isColor!(Color!true));
    static assert(isColor!(Color!false));
    static assert(!isColor!(uint));
    Color!true  col1;
    Color!false col2;
    col1 = col2;
    col2 = col1;
}

enum Color!true ColorWhite   = {r:255,g:255,b:255};
enum Color!true ColorSilver  = {r:0xc0,g:0xc0,b:0xc0};
enum Color!true ColorGray    = {r:0x80,g:0x80,b:0x80};
enum Color!true ColorBlack   = {r:0  ,g:0  ,b:0  };
enum Color!true ColorYellow  = {r:0xff,g:0xff,b:0x00};
enum Color!true ColorCyan    = {r:0x00,g:0xff,b:0xff};
enum Color!true ColorMagenta = {r:0xff,g:0x00,b:0xff};
enum Color!true ColorGreen   = {r:0  ,g:255,b:0  };
enum Color!true ColorRed     = {r:255,g:0  ,b:0  };
enum Color!true ColorBlue    = {r:0  ,g:0  ,b:255};
enum Color!true ColorTransparentWhite = {r:255,g:255,b:255, a: 0};

alias RGBA8888Color = Color!false;
alias BGRA8888Color = Color!true;

struct TemplateColor(int Size, uint rm = 0, uint gm = 0, uint bm = 0, uint am = 0)
{
@nogc:
pure nothrow:
    import core.bitop;
    static assert(Size > 0);
    static if     (1 == Size) alias DataType = ubyte;
    else static if(2 == Size) alias DataType = ushort;
    else static if(4 == Size) alias DataType = uint;
    else static assert(false, "Invalid color size: "~text(Size));
    enum uint rmask = rm;
    enum uint gmask = gm;
    enum uint bmask = bm;
    enum uint amask = am;
    DataType data = (rmask|gmask|bmask|amask);
    static if(rmask != 0)
    {
        enum uint rshift  = bsf(rmask);
        enum DataType rmax = (rmask >> rshift);
    }
    static if(gmask != 0)
    {
        enum uint gshift = bsf(gmask);
        enum DataType gmax = (gmask >> gshift);
    }
    static if(bmask != 0)
    {
        enum uint bshift = bsf(bmask);
        enum DataType bmax = (bmask >> bshift);
    }
    static if(amask != 0)
    {
        enum uint ashift = bsf(amask);
        enum DataType amax = (amask >> ashift);
    }

    private template IsValidProp(string s)
    {
        static if(1 == s.length && "rgba".find(s[0]))
        {
            mixin("enum bool IsValidProp = ("~s[0]~"mask != 0);");
        }
        else
        {
            enum bool IsValidProp = false;
        }
    }
    unittest
    {
        alias Col1 = TemplateColor!(4,0xFF000000,0xFF0000,0xFF00,0xFF);
        static assert(Col1.IsValidProp!"r");
        static assert(Col1.IsValidProp!"g");
        static assert(Col1.IsValidProp!"b");
        static assert(Col1.IsValidProp!"a");
    }

    @property opDispatch(string s)(in DataType value) if(IsValidProp!s)
    {
        assert(value >= 0);
        mixin("assert(value <= "~s[0]~"max);");
        mixin("data = (data & ~"~s[0]~"mask) | (value << "~s[0]~"shift);");
    }
    @property opDispatch(string s)() const if(IsValidProp!s)
    {
        mixin("return (("~s[0]~"mask & data) >> "~s[0]~"shift);");
    }
}

private void isTemplateColorImpl(int Size, uint rm, uint gm, uint bm, uint am)(in TemplateColor!(Size,rm,gm,bm,am) c) {}

template isTemplateColor(T) {
    enum isTemplateColor = is(typeof(isTemplateColorImpl(T.init)));
}

unittest
{
    alias Col1 = TemplateColor!(4,0xFF000000,0xFF0000,0xFF00,0xFF);
    static assert(isTemplateColor!Col1);
    static assert(!isTemplateColor!uint);
    static assert(!isTemplateColor!(Color!true));
    foreach(s;TypeTuple!('r','g','b','a'))
    {
        mixin("const m = Col1."~s~"max;");
        static assert(m == 255);
    }
    static assert(Col1.rshift == 24);
    static assert(Col1.gshift == 16);
    static assert(Col1.bshift == 8);
    static assert(Col1.ashift == 0);

    Col1       col1;
    Color!true col2 = {a:0,r:0,g:0,b:0};
    col2 = col1;
    assert(col2 == ColorWhite, debugConv(col2));
    col1.r = 255;
    col1.g = 0;
    col1.b = 0;
    col2 = col1;
    assert(col2 == ColorRed, debugConv(col2));
}