﻿module gamelib.graphics.surface;

import std.traits;
import gamelib.types;

import derelict.sdl2.sdl;

@nogc:
class Surface
{
package:
    SDL_Surface* mSurface = null;
    bool mOwned = true;
    int mLockCount = 0;
    immutable int mWidth;
    immutable int mHeight;
    this(SDL_Surface* surf)
    {
        assert(surf);
        mWidth   = surf.w;
        mHeight  = surf.h;
        mSurface = surf;
        mOwned = false;
    }
public:
final:
    this(int width,
         int height,
         int depth,
         Uint32 Rmask = 0x000000ff,
         Uint32 Gmask = 0x0000ff00,
         Uint32 Bmask = 0x00ff0000,
         Uint32 Amask = 0xff000000,
         void* pixels = null,
         int pitch = 0)
    {
        if(pixels is null)
        {
            mixin SDL_CHECK_NULL!(`mSurface = SDL_CreateRGBSurface(0,width,height,depth,Rmask,Gmask,Bmask,Amask)`);
        }
        else
        {
            mixin SDL_CHECK_NULL!(`mSurface = SDL_CreateRGBSurfaceFrom(pixels,width,height,depth,pitch,Rmask,Gmask,Bmask,Amask)`);
        }
        mWidth = width;
        mHeight = height;
    }
    ~this() const pure nothrow
    {
        assert(!mSurface);
    }

    @nogc void dispose() nothrow 
    {
        if(mSurface)
        {
            assert(0 == mLockCount);
            if(mOwned)
            {
                SDL_FreeSurface(mSurface);
            }
            mSurface = null;
        }
    }

    @nogc @property auto width()  const pure nothrow { return mWidth; }
    @nogc @property auto height() const pure nothrow { return mHeight; }
    @nogc @property auto data()   inout pure nothrow
    {
        assert(mSurface);
        assert(isLocked);
        return mSurface.pixels;
    }
    @nogc @property auto pitch() const pure nothrow
    {
        assert(mSurface);
        assert(isLocked);
        return mSurface.pitch;
    }

    void lock()
    {
        assert(mSurface);
        if(0 == mLockCount)
        {
            mixin SDL_CHECK!(`SDL_LockSurface(mSurface)`);
        }
        ++mLockCount;
    }
    void unlock() nothrow
    {
        assert(mSurface);
        assert(mLockCount > 0);
        if(1 == mLockCount)
        {
            SDL_UnlockSurface(mSurface);
        }
        --mLockCount;
    }
    @nogc @property bool isLocked() const pure nothrow
    {
        assert(mSurface);
        assert(mLockCount >= 0);
        return mLockCount > 0;
    }

    @nogc @property auto format() const pure nothrow
    {
        assert(mSurface);
        return mSurface.format;
    }

    void blit(Surface src)
    {
        assert(mSurface);
        assert(src.mSurface);
        mixin SDL_CHECK!(`SDL_BlitSurface(src.mSurface,null,mSurface,null)`);
    }
}

//Fixed format surface
final class FFSurface(ColorT) : Surface
{
package:
    static assert(ColorT.sizeof <= 4);
    this(SDL_Surface* surf)
    {
        super(surf);
    }
public:
    alias ColorType = ColorT;
    this(int width,
         int height,
         void* pixels = null,
         int pitch = 0)
    {
        enum depth = ColorT.sizeof * 8;
        static if(depth > 8)
        {
            Uint32 Rmask = ColorT.rmask;
            Uint32 Gmask = ColorT.gmask;
            Uint32 Bmask = ColorT.bmask;
            Uint32 Amask = ColorT.amask;
            super(width, height, depth, Rmask, Gmask, Bmask, Amask, pixels, pitch);
        }
        else
        {
            super(width, height, depth, 0, 0, 0, 0, pixels, pitch);
        }
    }

    @nogc final auto opIndex(int y) pure nothrow
    {
        assert(isLocked);
        import gamelib.graphics.surfaceview;
        SurfaceView!ColorT view = this;
        return view[y];
    }

    void fill(T)(in T col) if(isAssignable!(ColorT, T))
    {
        assert(mSurface);
        union tempunion_t
        {
            ColorT c;
            Uint32 i;
        }
        tempunion_t u;
        u.i = 0;
        u.c = col;
        mixin SDL_CHECK!(`SDL_FillRect(mSurface, null, u.i)`);
    }
}