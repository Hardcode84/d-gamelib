module gamelib.memory.utils;

import gamelib.types;

@nogc T* alignPointer(T)(void* ptr) pure nothrow
{
    return cast(T*)((cast(size_t)ptr + (T.alignof - 1)) & ~(T.alignof - 1));
}

void destruct(T)(ref T obj) if(is(T == struct))
{
    call_dtor(obj);
    auto buf = (cast(ubyte*) &obj)[0 .. T.sizeof];
    auto init = cast(ubyte[])typeid(T).init();
    if(init.ptr is null) // null ptr means initialize to 0s
    {
        buf[] = 0;
    }
    else
    {
        buf[] = init[];
    }
}

private void call_dtor(T)(ref T obj) if(is(T == struct))
{
    static if(is(typeof(obj.__dtor)))
    {
        obj.__dtor;
    }
    foreach_reverse(t;obj.tupleof)
    {
        static if(is(typeof(t) == struct))
        {
            call_dtor(t);
        }
    }
}

unittest
{
    struct Foo
    {
    align(4):
        char i;
    }
    auto ptr = alignPointer!Foo(cast(void*)0x1);
    assert(cast(void*)0x4 == ptr,debugConv(ptr));
}

unittest
{
    struct Foo
    {
        bool* b;
        ~this()
        {
            if( b )
            {
                *b = true;
            }
        }
    }
    struct Bar
    {
        bool* b;
        Foo f;
        ~this()
        {
            if( b )
            {
                *b = true;
            }
        }
    }
    struct Baz
    {
    }
    bool b1 = false;
    bool b2 = false;
    bool b3 = false;
    Foo foo;
    foo.b = &b1;
    Bar bar;
    bar.b = &b2;
    bar.f.b = &b3;
    Baz baz;
    assert(!b1 && !b2 && !b3);
    destruct(foo);
    destruct(bar);
    destruct(baz);
    assert(b1 && b2 && b3,debugConv(b1," ",b2, " ",b3));
    @nogc void test() pure nothrow
    {
        struct Foobar
        {
            @nogc ~this() pure nothrow
            {
            }
        }

        Foobar foobar;
        destruct(foobar);
    }
    test();
}

