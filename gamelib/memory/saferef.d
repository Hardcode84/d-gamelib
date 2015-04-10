module gamelib.memory.saferef;

import std.typetuple;
import std.typecons;
import std.algorithm;
import std.traits;

struct SafeRef(T)
{
pure nothrow:
@nogc:
@safe:
public:
    this() @disable;

    alias get this;

    auto get() inout { return mData; }

private:
    static if(is(T == class) || is(T == interface))
    {
        T mData;
        this(T r) { mData = r; }
    }
    else
    {
        T* mData;
        this(T* r) { mData = r; }
    }

    invariant
    {
        assert(mData !is null);
    }
}

auto makeSafe(T,Args...)(auto ref Args args)
{
    return SafeRef!T(new T(args));
}

auto convertSafe(T)(T r) pure
{
    import std.exception: enforce;
    enforce(r !is null, "Null reference");
    return SafeRef!T(r);
}

private template removePointer(T)
{
    static if( isPointer!T )
    {
        alias removePointer = pointerTarget!T;
    }
    else
    {
        alias removePointer = T;
    }
}

private auto convertUnsafe(T)(T r) @nogc pure nothrow
in
{
    assert(r !is null);
}
body
{
    return SafeRef!(removePointer!T)(r);
}

private auto convertUnsafeTuple(T...)(T args) @nogc pure nothrow
{
    import std.string: format;
    import std.range;
    enum string str = iota(args.length).map!(a => format("convertUnsafe(args[%s])",a)).join(",");
    mixin("return tuple("~str~");");
}

bool convertSafe(H,T...)(auto ref H handler, T args)
    if(isCallable!H && args.length > 0)
{
    foreach(ref a;args)
    {
        if(a is null)
        {
            return false;
        }
    }
    handler(convertUnsafeTuple(args).expand);
    return true;
}

auto convertSafe2(H1,H2,T...)(auto ref H1 handler1, auto ref H2 handler2, T args)
    if(isCallable!H1 && isCallable!H2 && args.length > 0)
{
    foreach(ref a;args)
    {
        if(a is null)
        {
            return handler2();
        }
    }
    return handler1(convertUnsafeTuple(args).expand);
}

version(unittest)
{
    private class Foo
    {
    @nogc:
        bool flag = false;
        this() {}
        this(int) {}

        void set() { flag = true; }
        void reset() { flag = false; }
        void test() { assert(flag); }
    }
}

unittest
{
    {
        auto r = makeSafe!Foo();
        r = makeSafe!Foo(1);
        r.set();
        r.test();
        auto f = new Foo;
        r = convertSafe(f);
    }

    auto f = new Foo;
    auto f1 = new Foo;
    void test1() @nogc
    {
        assert(convertSafe((SafeRef!Foo a,SafeRef!Foo b) @nogc { a.set(); b.set(); }, f, f1));
        f.test();
        f1.test();
        Foo f2 = null;
        assert(!convertSafe((SafeRef!Foo a,SafeRef!Foo b) @nogc { a.set(); b.set(); }, f, f2));
    }
    test1();
    f.reset();
    f1.reset();
    void test2() @nogc
    {
        assert(convertSafe2(
                (SafeRef!Foo a,SafeRef!Foo b) @nogc { a.set(); b.set(); return true; },
                () @nogc { return false; },
                f, f1));
        f.test();
        f1.test();
        Foo f2 = null;
        assert(!convertSafe2(
                (SafeRef!Foo a,SafeRef!Foo b) @nogc { a.set(); b.set(); return true; },
                () @nogc { return false; },
                f, f2));
    }
    test2();

    int i = 0;
    int* pi = &i;
    assert(convertSafe((SafeRef!int a) @nogc { *a = 1; }, pi));
    assert(i == 1);
}