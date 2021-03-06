﻿module gamelib.memory.stackalloc;

import std.traits;

import gamelib.types;
import gamelib.memory.utils;

final class StackAlloc
{
pure nothrow:
private:
    void[] mMemory;
    void*  mPtr = null;
public:
    this(size_t bytes)
    {
        mMemory.length = bytes;
        mPtr = mMemory.ptr;
    }

@nogc:

    alias State = void*;

    @property State state()
    {
        return mPtr;
    }

    void restoreState(State s)
    in
    {
        assert(s !is null);
        assert(s >= mMemory.ptr);
        assert(s <  mMemory.ptr + mMemory.length);
    }
    body
    {
        mPtr = s;
    }

    auto alloc(T)(size_t count)
    in
    {
        assert(count >= 0);
    }
    body
    {
        static assert(__traits(isPOD,T));
        enum size = T.sizeof;
        auto ptr = alignPointer!T(mPtr);
        auto ptrEnd = ptr + size * count;
        const memEnd = mMemory.ptr + mMemory.length;
        assert(ptr >= mMemory.ptr);
        assert(ptr < memEnd);
        assert(ptrEnd < memEnd);
        mPtr = ptrEnd;
        return (cast(T*)ptr)[0..count];
    }

    auto alloc(T)(size_t count, T val)
    {
        auto res = alloc!T(count);
        res[] = val;
        return res;
    }

    auto alloc(T)()
    {
        return alloc!T(1).ptr;
    }

    auto capacity() const
    {
        return mMemory.length;
    }

    auto size() const
    {
        return mPtr - mMemory.ptr;
    }
}
//TODO: tests

