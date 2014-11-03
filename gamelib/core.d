module gamelib.core;

import std.exception : enforce;
import std.conv;

import derelict.sdl2.sdl;
import derelict.sdl2.image;
import gamelib.types;

class Core
{
public:
    this(bool video = true, bool sound = true)
    {
        scope(failure) dispose();
        DerelictSDL2.load();

        Uint32 sdlFlags = 0;
        if(video) sdlFlags |= SDL_INIT_VIDEO;
        if(sound) sdlFlags |= SDL_INIT_AUDIO;

        mixin SDL_CHECK!(`SDL_Init(sdlFlags)`);
        //SDL_LogSetAllPriority(SDL_LOG_PRIORITY_CRITICAL);
        SDL_LogSetOutputFunction(&logFunc, null);
        SDL_LogCritical(SDL_LOG_CATEGORY_ERROR, "testlog");
        version(UseSDLImage)
        {
            DerelictSDL2Image.load();
            auto imgFormats = IMG_INIT_PNG;
            enforce(imgFormats & IMG_Init(imgFormats), "IMG_Init failed: " ~ to!string(IMG_GetError()).idup);
        }
    }

    void dispose()
    {
        version(UseSDLImage)
        {
            if(DerelictSDL2Image.isLoaded)
            {
                IMG_Quit();
                DerelictSDL2Image.unload();
            }
        }

        if(DerelictSDL2.isLoaded)
        {
            SDL_Quit();
            DerelictSDL2.unload();
        }
    }
private:
    static extern( C ) nothrow void logFunc(void* userData, int category, SDL_LogPriority priority, const( char )* message)
    {
        static immutable string[] categories = [
        "application",
        "error",
        "system",
        "audio",
        "video",
        "render",
        "input"];
        static immutable string[] priorities = [
        "none",
        "verbose",
        "debug",
        "info",
        "warn",
        "error",
        "critical"];
        const string cat = (category >= 0 && category < categories.length ? categories[category] : "unknown");
        const string pri = (priority >= 0 && priority < priorities.length ? priorities[priority] : "unknown");
        import std.stdio;
        try
        {
            writefln("SDL log: %s %s: %s", cat, pri, text(message));
        }
        catch(Exception e) {}
    }
}