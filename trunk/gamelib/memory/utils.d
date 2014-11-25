module gamelib.memory.utils;

import gamelib.types;

@nogc:
pure nothrow:

T* alignPointer(T)(void* ptr)
{
    return cast(T*)((cast(size_t)ptr + (T.alignof - 1)) & ~(T.alignof - 1));
}

