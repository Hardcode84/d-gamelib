module gamelib.graphics.renderer2d.texture;

import std.string;

import gamelib.types;
import gamelib.graphics.renderer2d.renderer;
import gamelib.graphics.surface;

import derelict.sdl2.sdl;
import derelict.sdl2.image;

struct TextureProps
{
    Uint32 format = SDL_PIXELFORMAT_UNKNOWN;
    bool isStreaming = false;
    int width = 0;
    int height = 0;
}

final class Texture
{
package:
    SDL_Texture* mTexture = null;
public:
    this(Renderer ren, in TextureProps props)
    {
        assert(ren);
        assert(ren.mRenderer);
        immutable int access = (props.isStreaming ? SDL_TEXTUREACCESS_STREAMING : SDL_TEXTUREACCESS_STATIC);
        mTexture = sdlCheckNull!SDL_CreateTexture(ren.mRenderer, props.format, access, props.width, props.height);
    }
    this(Renderer ren, in string file)
    {
        SDL_Surface* surface = null;
        version(UseSDLImage)
        {
            mixin SDL_CHECK_NULL!(`surface = IMG_Load(toStringz(file))`,"IMG_GetError()");
        }
        else
        {
            surface = sdlCheckNull!SDL_LoadBMP(toStringz(file));
        }
        scope(exit) SDL_FreeSurface(surface);
        mTexture = sdlCheckNull!SDL_CreateTextureFromSurface(ren.mRenderer, surface);
    }
    this(Renderer ren, Surface surf)
    {
        assert(surf !is null);
        assert(surf.mSurface !is null);
        mTexture = sdlCheckNull!SDL_CreateTextureFromSurface(ren.mRenderer, surf.mSurface);
    }
    ~this() const pure nothrow
    {
        assert(!mTexture);
    }

    void dispose() nothrow
    {
        if(mTexture)
        {
            SDL_DestroyTexture(mTexture);
            mTexture = null;
        }
    }

    @property TextureProps props()
    {
        assert(mTexture);
        TextureProps ret;
        int access;
        sdlCheck!SDL_QueryTexture(mTexture, &ret.format, &access, &ret.width, &ret.height);
        ret.isStreaming = (SDL_TEXTUREACCESS_STREAMING == access);
        return ret;
    }

    @property void colorMod(ColT)(in ColT col)
    {
        assert(mTexture);
        sdlCheck!SDL_SetTextureColorMod(mTexture, col.r, col.g, col.b);
    }

}

