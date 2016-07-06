module gamelib.graphics.surface;

import std.traits;
import std.format;
import gamelib.types;

import derelict.sdl2.sdl;

struct SurfaceParams
{
    int width;
    int height;
    int depth;
    Uint32 Rmask = 0x000000ff;
    Uint32 Gmask = 0x0000ff00;
    Uint32 Bmask = 0x00ff0000;
    Uint32 Amask = 0xff000000;
}

class Surface
{
package:
    SDL_Surface* mSurface = null;
    bool mOwned = true;
    int mLockCount = 0;
    immutable int mWidth;
    immutable int mHeight;
    void* mData = null;
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
    this(in SurfaceParams params,
         int pitch = 0,
         void* pixels = null)
    {
        if(0 == pitch)
        {
            mSurface = sdlCheckNull!SDL_CreateRGBSurface(0,params.width,params.height,params.depth,params.Rmask,params.Gmask,params.Bmask,params.Amask);
        }
        else
        {
            enforce(params.width > 0 && params.height > 0, std.format.format("Invalid image size: %sx%s",params.width, params.height));
            enforce(0 == params.depth % 8, std.format.format("Invalid depth: %s", params.depth));
            enforce(pitch >= (params.width * (params.depth / 8)), std.format.format("Invalid pitch: %s", pitch));
            if(pixels is null)
            {
                import core.memory;
                enum AlignSize = 64;
                const size = pitch * params.height + AlignSize;
                mData = GC.qalloc(size, GC.BlkAttr.NO_SCAN | GC.BlkAttr.NO_INTERIOR).base;
                import gamelib.memory.utils;
                pixels = alignPointer(mData, AlignSize);
            }
            mSurface = sdlCheckNull!SDL_CreateRGBSurfaceFrom(pixels,params.width,params.height,params.depth,pitch,params.Rmask,params.Gmask,params.Bmask,params.Amask);
        }
        mWidth  = params.width;
        mHeight = params.height;
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
        if(mData !is null)
        {
            //import core.memory;
            //GC.free(mData);
            mData = null;
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
            sdlCheck!SDL_LockSurface(mSurface);
        }
        ++mLockCount;
    }
    @nogc void unlock() nothrow
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
        sdlCheck!SDL_BlitSurface(src.mSurface,null,mSurface,null);
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
         int pitch = 0,
         void* pixels = null)
    {
        enum depth = ColorT.sizeof * 8;
        static if(depth > 8)
        {
            Uint32 Rmask = ColorT.rmask;
            Uint32 Gmask = ColorT.gmask;
            Uint32 Bmask = ColorT.bmask;
            Uint32 Amask = ColorT.amask;
            super(SurfaceParams(width, height, depth, Rmask, Gmask, Bmask, Amask), pitch, pixels);
        }
        else
        {
            super(SurfaceParams(width, height, depth, 0, 0, 0, 0), pitch, pixels);
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
        sdlCheck!SDL_FillRect(mSurface, null, u.i);
    }
}

auto loadSurfaceFromFile(ColT)(in string filename)
{
    import std.string;
    SDL_Surface* surface = null;
    version(UseSDLImage)
    {
        mixin SDL_CHECK_NULL!(`surface = IMG_Load(toStringz(filename))`,"IMG_GetError()");
    }
    else
    {
        mixin SDL_CHECK_NULL!(`surface = SDL_LoadBMP(toStringz(filename))`);
    }
    scope(exit) SDL_FreeSurface(surface);
    auto surf = new FFSurface!ColT(surface.w,surface.h);
    scope(failure) surf.dispose();
    mixin SDL_CHECK!(`SDL_BlitSurface(surface,null,surf.mSurface,null)`);
    return surf;
}