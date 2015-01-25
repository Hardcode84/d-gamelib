module gamelib.memory.poolalloc;

import std.traits;
import std.typetuple;

import gamelib.memory.utils;

final class PoolAlloc(Types...) if(Types.length > 0)
{
pure nothrow:
private:
    static genDecl()
    {
        import std.conv;
        string ret;
        foreach(i,T;Types)
        {
            ret ~= "static assert(is(Types["~text(i)~"] == struct));\n";
            ret ~= "Unqual!(Types["~text(i)~"]*) mLast"~text(i)~" = null;\n";
        }
        return ret;
    }
    mixin(genDecl());
    @nogc auto ref getLast(T)() inout
    {
        enum Ind = staticIndexOf!(T,Types);
        static assert(Ind >= 0);
        import std.conv;
        mixin("return mLast"~text(Ind)~";");
    }
public:
    this(size_t initialSize)
    {
        if(initialSize > 0)
        {
            foreach(T;Types)
            {
                T[] arr;
                arr.length = initialSize;
                arr[0].prev = null;
                foreach(i;1..initialSize)
                {
                    arr[i].prev = &arr[i - 1];
                }
                getLast!T() = &arr[$ - 1];
            }
        }
    }
    auto allocate(T)() if(is(T == struct))
    out(result)
    {
        assert(result !is null);
    }
    body
    {
        if(getLast!T() is null)
        {
            return new T;
        }
        T* temp = getLast!T();
        getLast!T() = temp.prev;
        *temp = T.init;
        return temp;
    }
    void free(T)(T* ptr) if(is(T == struct))
    {
        assert(ptr !is null);
        destruct(*ptr);
        ptr.prev = getLast!T();
        getLast!T() = ptr;
    }
}

unittest
{
    struct Foo { Foo* prev; }
    struct Bar { Bar* prev; }
    auto alloc = new PoolAlloc!(Foo,Bar)(100);
    {
        auto f = alloc.allocate!Foo();
        auto b = alloc.allocate!Bar();
        alloc.free(f);
        alloc.free(b);
    }
    {
        auto f1 = alloc.allocate!Foo();
        auto f2 = alloc.allocate!Foo();
        assert(f1 !is f2);
    }
}

