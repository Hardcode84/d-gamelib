module gamelib.types;

import std.range;

public import std.conv: to;
public import std.exception: enforce;

public import derelict.sdl2.sdl;
public import derelict.sdl2.image;

public import gamelib.funcwrapper;
public import gamelib.debugout;

alias SDL_Point Point;
alias SDL_Rect Rect;

struct Size
{
    int w, h;
}

unittest
{
    static assert(0 == SDL_PIXELFORMAT_UNKNOWN);
}
