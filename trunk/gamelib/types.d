module gamelib.types;

import std.range;

public import std.conv: to;
public import std.exception: enforce;

public import derelict.sdl2.sdl;
public import derelict.sdl2.image;

alias SDL_Point Point;
alias SDL_Rect Rect;

private string convImpl(T)(in T val) pure nothrow @trusted
{
    debug
    {
        try
        {
            import std.conv;
            return text(val);
        }
        catch(Exception e) {}
    }
    return "";            
}

@nogc:
void debugOut(T)(in T val) pure nothrow @trusted
{
    debug
    {
        import std.stdio;
        try
        {
            writeln(val);
        }
        catch(Exception e) {}
    }
}

auto debugConv(T)(in T val) pure nothrow @trusted
{
    debug
    {
        alias fn_t = string function(in T) pure nothrow @nogc;
        return (cast(fn_t)&convImpl!T)(val); //hack to add @nogc
    }
    return "";
}
@nogc:

struct Size
{
    int w, h;
}

struct Color(bool bgra = false)
{
    import std.typetuple, std.string;
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
        enum Uint32 bmask = 0x000000ff;
        enum Uint32 gmask = 0x0000ff00;
        enum Uint32 rmask = 0x00ff0000;
        enum Uint32 amask = 0xff000000;
    }
    else
    {
        enum Uint32 rmask = 0x000000ff;
        enum Uint32 gmask = 0x0000ff00;
        enum Uint32 bmask = 0x00ff0000;
        enum Uint32 amask = 0xff000000;
    }
    ref Color opAssign(U)(in U x) pure nothrow
    {
        foreach(c;TypeTuple!('r','g','b','a'))
        {
            mixin(format("%1$s = x.%1$s;",c));
        }
        return this;
    }

    static Color lerp(T)(in Color col1, in Color col2, in T coeff) pure nothrow
    {
        //assert(coeff >= (0), debugConv(coeff));
        //assert(coeff <= (1), debugConv(coeff));
        Color ret;
        foreach(c;TypeTuple!('r','g','b'))
        {
            enum str = format("ret.%1$s = cast(ubyte)(col2.%1$s*(cast(T)1 - coeff) + col1.%1$s*coeff);",c);
            mixin(str);
        }
        return ret;
    }

    auto toRaw() const pure nothrow
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
    static auto fromRaw(in uint i) pure nothrow
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
    auto opBinary(string op : "+")(in Color rhs) const pure nothrow
    {
        return fromRaw(toRaw() + rhs.toRaw());
    }

    auto opBinary(string op : "*",T)(in T rhs) const pure nothrow
    {
        Color ret;
        foreach(c;TypeTuple!('r','g','b'))
        {
            enum str = format("ret.%1$s = cast(ubyte)(%1$s*rhs);",c);
            mixin(str);
        }
        return ret;
    }

    static Color average(in Color col1,in Color col2) pure nothrow
    {
        return Color.fromRaw(((col1.toRaw() & 0xfefefefe) >> 1) +
                             ((col2.toRaw() & 0xfefefefe) >> 1));
    }

    static void interpolateLine(int LineSize, Rng)(auto ref Rng rng, in Color col1, in Color col2) pure nothrow 
        if(isRandomAccessRange!Rng)
    {
        /*foreach(i;0..LineSize)
        {
            rng[i] = lerp(col2,col1, cast(float)i / cast(float)LineSize);
        }*/
        import gamelib.math;
        static assert(ispow2(LineSize));
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
            interpolateLine!(pos)(rng[pos..$],rng[pos],col2);
        }
        else
        {
            rng[0] = average(col1,col2);
        }
    }

    static void interpolateLine(Rng)(int lineSize, auto ref Rng rng, in Color col1, in Color col2) pure nothrow 
        if(isRandomAccessRange!Rng)
    {
        if(lineSize <= 1) return;
        const col = average(col1, col2);
        const center = lineSize / 2;
        rng[center] = col;
        interpolateLine(center, rng[0..center],col1,col);
        interpolateLine(center, rng[center..$],col,col2);
    }
}

enum Color!true ColorWhite = {r:255,g:255,b:255};
enum Color!true ColorBlack = {r:0  ,g:0  ,b:0  };
enum Color!true ColorGreen = {r:0  ,g:255,b:0  };
enum Color!true ColorRed   = {r:255,g:0  ,b:0  };
enum Color!true ColorBlue  = {r:0  ,g:0  ,b:255};
enum Color!true ColorTransparentWhite = {r:255,g:255,b:255, a: 0};

template Tuple(E...)
{
    alias E Tuple;
}

mixin template SDL_CHECK(string S, string getErr = "SDL_GetError()")
{
    auto temp = enforce(0 == (mixin(S)), "\"" ~ S ~ "\" failed: " ~ to!string(mixin(getErr)).idup);
}

mixin template SDL_CHECK_BOOL(string S, string getErr = "SDL_GetError()")
{
    auto temp = enforce(SDL_TRUE == (mixin(S)), "\"" ~ S ~ "\" failed: " ~ to!string(mixin(getErr)).idup);
}

mixin template SDL_CHECK_NULL(string S, string getErr = "SDL_GetError()")
{
    auto temp = enforce(null != (mixin(S)), "\"" ~ S ~ "\" failed: " ~ to!string(mixin(getErr)).idup);
}

struct TemplateColor(int Size, uint rm = 0, uint gm = 0, uint bm = 0, uint am = 0)
{
    static assert(Size > 0);
    static if(1 == Size)      ubyte data;
    else static if(2 == Size) ushort data;
    else static if(4 == Size) uint data;
    else static assert(false, "Invalid color size: "~to!string(Size));
    enum Uint32 rmask = rm;
    enum Uint32 gmask = gm;
    enum Uint32 bmask = bm;
    enum Uint32 amask = am;
}

alias I8Color = TemplateColor!1;
alias RGBA8888Color = Color!false;
alias BGRA8888Color = Color!true;

unittest
{
    static assert(0 == SDL_PIXELFORMAT_UNKNOWN);
}
