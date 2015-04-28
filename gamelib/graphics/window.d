module gamelib.graphics.window;

import std.typetuple;
import std.string;
import std.conv;
import std.exception;
import derelict.sdl2.sdl;

import gamelib.types;
import gamelib.graphics.color;
import gamelib.graphics.surface;

version(Windows)
{
    pragma(lib, "Gdi32");
}

class ColorFormatException : Exception
{
    @safe pure nothrow this(string msg, string file = __FILE__, size_t line = __LINE__, Throwable next = null)
    {
        super(msg, file, line, next);
    }
}

final class Window
{
package:
    SDL_Window* mWindow = null;
    Uint32      mWinId = 0;
    Surface mCachedSurf = null;
    version(Windows)
    {
        import core.sys.windows.windows;
        HDC mHDC = null;
    }
public:
    this(in string title, in int width, in int height, Uint32 flags = 0)
    {
        mWindow = sdlCheckNull!SDL_CreateWindow(
            toStringz(title),
            SDL_WINDOWPOS_UNDEFINED,
            SDL_WINDOWPOS_UNDEFINED,
            width,
            height,
            flags);
        SDL_SysWMinfo info;
        sdlCheckBool!SDL_GetWindowWMInfo(mWindow,&info);
        version(Windows)
        {
            mHDC = enforce(GetDC(info.info.win.window), "Unable to get HDC");
        }
        mWinId = SDL_GetWindowID(mWindow);
    }

    ~this() const pure nothrow
    {
        assert(!mWindow);
    }

    @property string title()
    {
        assert(mWindow);
        return to!string(SDL_GetWindowTitle(mWindow)).idup;
    }

    @property void title(in string t) nothrow
    {
        assert(mWindow);
        SDL_SetWindowTitle(mWindow, toStringz(t));
    }

    void setSize(int x, int y) nothrow
    {
        assert(mWindow);
        invalidateSurface();
        SDL_SetWindowSize(mWindow, x, y);
    }

    void invalidateSurface() nothrow
    {
        if(mCachedSurf)
        {
            mCachedSurf.dispose();
            mCachedSurf = null;
        }
    }

    void dispose() nothrow
    {
        if(mWindow)
        {
            version(Windows)
            {
                if(mHDC)
                {
                    SDL_SysWMinfo info;
                    if(SDL_TRUE ==  SDL_GetWindowWMInfo(mWindow,&info))
                    {
                        ReleaseDC(info.info.win.window,mHDC);
                    }
                }
            }
            invalidateSurface();
            SDL_DestroyWindow(mWindow);
            mWindow = null;
        }
    }

    @property auto size() nothrow
    {
        assert(mWindow);
        Point ret;
        SDL_GetWindowSize(mWindow, &ret.x, &ret.y);
        return ret;
    }

    //do not dispose returned surface
    @property auto surface()
    {
        assert(mWindow);
        if(mCachedSurf is null)
        {
            SDL_Surface* surf = null;
            surf = sdlCheckNull!SDL_GetWindowSurface(mWindow);
            const fmt = surf.format;
            //try to create typed surface
            if(1 == fmt.BytesPerPixel)
            {
                mCachedSurf = new FFSurface!ubyte(surf);
            }
            else
            {
                alias Types32 = TypeTuple!(RGBA8888Color,BGRA8888Color); //TODO: more formats
                foreach(f;Types32)
                {
                    if((mCachedSurf is null) &&
                       (f.sizeof == fmt.BytesPerPixel) &&
                       (f.rmask  == fmt.Rmask) &&
                       (f.gmask  == fmt.Gmask) &&
                       (f.bmask  == fmt.Bmask)/* &&
                       (f.amask  == fmt.Amask)*/)
                    {
                        mCachedSurf = new FFSurface!f(surf);
                    }
                }
            }

            if(mCachedSurf is null)
            {
                //unknown format, fallback to untyped
                mCachedSurf =  new Surface(surf);
            }
        }
        return mCachedSurf;
    }

    @property auto surface(T)()
    {
        return enforceEx!ColorFormatException(cast(FFSurface!T)surface(), "Invalid pixel format: "~T.stringof);
    }

    void blit(Surface surf)
    {
        version(Windows)
        {
            assert(mHDC);
            const sz = size;
            const fmt = surf.format;
            struct tempstruct_t
            {
                BITMAPINFO bmi;
                byte[RGBQUAD.sizeof * 255] data;
            }
            tempstruct_t s;
            s.bmi.bmiHeader.biSize = s.bmi.bmiHeader.sizeof;
            s.bmi.bmiHeader.biWidth = sz.x;
            s.bmi.bmiHeader.biHeight = -sz.y;
            s.bmi.bmiHeader.biPlanes = 1;
            s.bmi.bmiHeader.biBitCount = fmt.BitsPerPixel;
            s.bmi.bmiHeader.biCompression = 0;//BI_RGB;
            s.bmi.bmiHeader.biSizeImage = 0;
            s.bmi.bmiHeader.biXPelsPerMeter = 0;
            s.bmi.bmiHeader.biYPelsPerMeter = 0;
            s.bmi.bmiHeader.biClrUsed = 0;
            s.bmi.bmiHeader.biClrImportant = 0;

            if(fmt.BytesPerPixel > 1)
            {
                s.bmi.bmiHeader.biCompression = 3;//BI_BITFIELDS;
                auto masks = cast(uint*)(s.bmi.bmiColors.ptr);
                masks[0] = fmt.Rmask;
                masks[1] = fmt.Gmask;
                masks[2] = fmt.Bmask;
            }
            else
            {
                assert(false);//TODO: paletted formats
            }
            surf.lock;
            scope(exit) surf.unlock;

            enforce(0 != SetDIBitsToDevice(mHDC,
                                           0,//xdest,
                                           0,//ydest,
                                           sz.x,//width,
                                           sz.y,//height,
                                           0,//xsrc,
                                           0,//ysrc,
                                           0,
                                           sz.y,//height,
                                           surf.data,
                                           &s.bmi,
                                           0/*DIB_RGB_COLORS*/));
        }
        else
        {
            surface.blit(surf);
            sdlCheck!SDL_UpdateWindowSurface(mWindow);
        }
    }

    void updateSurface(Surface surf = null)
    {
        assert(mWindow);
        if(surf !is null)
        {
            blit(surf);
        }
        else
        {
            sdlCheck!SDL_UpdateWindowSurface(mWindow);
        }
    }

    @property auto formatString()
    {
        assert(mWindow);
        return text(SDL_GetPixelFormatName(SDL_GetWindowPixelFormat(mWindow))).idup;
    }

    @property bool hidden() nothrow
    {
        assert(mWindow !is null);
        return 0 != (SDL_WINDOW_MINIMIZED & SDL_GetWindowFlags(mWindow)) ||
               0 != (SDL_WINDOW_HIDDEN    & SDL_GetWindowFlags(mWindow));
    }

    @property auto winId() const pure nothrow
    {
        assert(mWindow !is null);
        return mWinId;
    }
}