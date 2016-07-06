module gamelib.memory.utils;

import gamelib.types;

@nogc auto alignPointer(inout(void)* ptr, size_t size) pure nothrow
{
    import gamelib.math;
    assert(size > 0);
    assert(ispow2(size));
    return cast(void*)((cast(size_t)ptr + (size - 1)) & ~(size - 1));
}

@nogc auto alignPointer(T)(inout(void)* ptr) pure nothrow
{
    return cast(inout(T)*)alignPointer(ptr, T.alignof);
}

@nogc auto alignSize(T)(in T val, size_t size) pure nothrow
{
    assert(size > 0);
    return cast(T)(((val + size - 1) / size) * size);
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
    foreach_reverse(ref t;obj.tupleof)
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
    assert(1 == alignSize(1, 1));
    assert(5 == alignSize(1, 5));
    assert(0xff == alignSize(1, 0xff));

    assert(4 == alignSize(1, 4));
    assert(4 == alignSize(4, 4));
    assert(8 == alignSize(5, 4));
    assert(8 == alignSize(8, 4));
    assert(12 == alignSize(9, 4));
    assert(15 == alignSize(13, 5));
}

unittest
{
    class C {}
    interface I {}
    struct Foo
    {
        bool* b;
        C c;
        I i;
        @disable this(this);
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
        C c;
        I i;
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

