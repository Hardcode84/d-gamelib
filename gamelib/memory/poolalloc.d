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
            /*EntityRef[] refs;
            refs.length = initialSize;
            refs[0].prev = null;
            foreach(i;1..initialSize)
            {
                refs[i].prev = &refs[i - 1];
            }
            mLast = &refs[$ - 1];*/
        }
    }
    /*EntityRef* allocate()
    {
        if(mLast is null)
        {
            return new EntityRef;
        }
        auto temp = mLast;
        mLast = temp.prev;
        *temp = EntityRef.init;
        return temp;
    }
    
    void free(EntityRef* ptr)
    {
        destruct(*ptr);
        assert(ptr !is null);
        ptr.prev = mLast;
        mLast = ptr;
    }*/
}

unittest
{
    struct Foo { Foo* prev; }
    struct Bar { Bar* prev; }
    auto alloc = new PoolAlloc!(Foo,Bar)(100);
}

