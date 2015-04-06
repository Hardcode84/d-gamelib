module gamelib.memory.saferef;

import std.typetuple;
import std.typecons;
import std.algorithm;
import std.traits;

struct SafeRef(T) if(is(T == class))
{
pure nothrow:
@nogc:
public:
    this() @disable;

    alias data this;

private:
    this(T r)
    in
    {
        assert(r !is null);
    }
    body
    {
        data = r;
    }

    invariant
    {
        assert(data !is null);
    }
    T data;
}

auto makeSafe(T,Args...)(auto ref Args args)
{
    return SafeRef!T(new T(args));
}

auto convertSafe(T)(T r) pure if(is(T == class))
{
    import std.exception: enforce;
    enforce(r !is null, "Null reference");
    return SafeRef!T(r);
}

private auto convertUnsafe(T)(T r) @nogc pure nothrow if(is(T == class))
in
{
    assert(r !is null);
}
body
{
    return SafeRef!T(r);
}

private auto convertUnsafeTuple(T...)(T args) @nogc pure nothrow
{
    import std.string: format;
    import std.range;
    enum string str = iota(args.length).map!(a => format("convertUnsafe(args[%s])",a)).join(",");
    mixin("return tuple("~str~");");
}

bool convertSafe(H,T...)(auto ref H handler, T args)
    if(isCallable!H && args.length > 0 && allSatisfy!(a => is(a == class) ,tuple(args).Types))
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
    if(isCallable!H1 && isCallable!H2 && args.length > 0 && allSatisfy!(a => is(a == class) ,tuple(args).Types))
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
}