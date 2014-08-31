module gamelib.types;

public import std.conv: to;
public import std.exception: enforce;

public import derelict.sdl2.sdl;
public import derelict.sdl2.image;

alias SDL_Point Point;
alias SDL_Rect Rect;

void debugOut(T)(auto ref T val) pure nothrow @trusted
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

auto debugConv(T)(auto ref T val) pure nothrow @trusted
{
    debug
    {
        import std.conv;
        try
        {
            return text(val);
        }
        catch(Exception e) {}
    }
    return "";
}

struct Size
{
    int w, h;
}

struct Color
{
    ubyte r = 255;
    ubyte g = 255;
    ubyte b = 255;
    ubyte a = SDL_ALPHA_OPAQUE;
    enum format = SDL_PIXELFORMAT_RGBA8888;
    enum Uint32 rmask = 0x000000ff;
    enum Uint32 gmask = 0x0000ff00;
    enum Uint32 bmask = 0x00ff0000;
    enum Uint32 amask = 0xff000000;
    static Color lerp(T)(in Color col1, in Color col2, in T coeff) pure nothrow
    {
        //assert(coeff >= (0), debugConv(coeff));
        //assert(coeff <= (1), debugConv(coeff));
        Color ret;
        import std.typetuple, std.string;
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
    static Color average(in Color col1,in Color col2) pure nothrow
    {
        return Color.fromRaw(((col1.toRaw() & 0xfefefefe) >> 1) +
                             ((col2.toRaw() & 0xfefefefe) >> 1));
    }
}

enum Color ColorWhite = {r:255,g:255,b:255};
enum Color ColorBlack = {r:0  ,g:0  ,b:0  };
enum Color ColorGreen = {r:0  ,g:255,b:0  };
enum Color ColorRed   = {r:255,g:0  ,b:0  };
enum Color ColorBlue  = {r:0  ,g:0  ,b:255};
enum Color ColorTransparentWhite = {r:255,g:255,b:255, a: 0};

template Tuple(E...)
{
    alias E Tuple;
}

mixin template SDL_CHECK(string S, string getErr = "SDL_GetError()")
{
    auto temp = enforce(0 == (mixin(S)), "\"" ~ S ~ "\" failed: " ~ to!string(mixin(getErr)).idup);
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
alias RGBA8888Color = Color;

unittest
{
    static assert(0 == SDL_PIXELFORMAT_UNKNOWN);
}
