module gamelib.funcwrapper;

auto checkedCall(alias FUN,alias CHECKER,ARGS...)(ARGS Args)
{
    auto result = FUN(Args);
    CHECKER(result);
    return result;
}

private
{
    import derelict.sdl2.sdl;
    import std.exception: enforce;
    import std.conv: text;
    void sdlChecker(alias FUN)(int val)
    {
        enforce(0 == val, "\"" ~ __traits(identifier, FUN) ~ "\" failed: " ~ text(SDL_GetError()).idup);
    }
    void sdlBoolChecker(alias FUN)(SDL_bool val)
    {
        enforce(SDL_TRUE == val, "\"" ~ __traits(identifier, FUN) ~ "\" failed: " ~ text(SDL_GetError()).idup);
    }
    void sdlNullChecker(alias FUN)(void* val)
    {
        enforce(val !is null, "\"" ~ __traits(identifier, FUN) ~ "\" failed: " ~ text(SDL_GetError()).idup);
    }
}

auto sdlCheck(alias FUN,ARGS...)(ARGS Args)     { return checkedCall!(FUN,sdlChecker!FUN)(Args); }
auto sdlCheckBool(alias FUN,ARGS...)(ARGS Args) { return checkedCall!(FUN,sdlBoolChecker!FUN)(Args); }
auto sdlCheckNull(alias FUN,ARGS...)(ARGS Args) { return checkedCall!(FUN,sdlNullChecker!FUN)(Args); }


version(unittest)
{
private:
    void checker(alias FUN)(string str)
    {
        assert(__traits(identifier, FUN) == str);
    }
    auto foo()
    {
        return "foo";
    }
    auto bar(int i, float f, string str)
    {
        return "bar";
    }
}

unittest
{
    cast(void)checkedCall!(foo,checker!foo)();
    cast(void)checkedCall!(bar,checker!bar)(1,2.0f,"3");
}