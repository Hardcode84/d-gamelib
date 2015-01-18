module gamelib.memory.memory;

import std.traits;

auto allocate(T,A...)(auto ref A args) if (!is(T == class))
{
    import core.memory : GC;
    import core.stdc.stdlib : malloc;
    import std.conv : emplace;
    //import std.exception : enforce;

    auto ret = cast(T*) malloc(T.sizeof);
    if(ret is null)
    {
        assert(false, "Allocation failed");
    }
    static if (hasIndirections!T)
        GC.addRange(ret, T.sizeof);
    emplace(ret, args);
    return ret;
}

void deallocate(T)(T* ptr) if (!is(T == class))
{
    if(ptr is null) return;
    .destroy(*ptr);
    static if (hasIndirections!T)
    {
        import core.memory : GC;
        GC.removeRange(&_refCounted._store._payload);
    }
    import core.stdc.stdlib : free;
    free(ptr);
}