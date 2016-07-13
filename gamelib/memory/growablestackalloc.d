module gamelib.memory.growablestackalloc;

import std.traits;
import core.stdc.stdlib;
import core.exception;

import gamelib.math;
import gamelib.types;
import gamelib.memory.utils;

final class GrowableStackAlloc
{
pure nothrow @nogc:
private:
    enum MaxBlocks = ((void*).sizeof * 8);
    alias MemRange = void[];
    MemRange[MaxBlocks] mMemory;
    void*  mPtr = null;
    size_t mCapacity = 0;
    int mCurrentBlock = 0;
    int mTotalBlocks = 0;
    debug
    {
        int mLastAllocIndex = 0;
    }

    @property auto currentMemBlock() inout
    {
        assert(mCurrentBlock >= 0);
        assert(mCurrentBlock < mMemory.length);
        assert(mCurrentBlock < mTotalBlocks);
        assert(mMemory[mCurrentBlock].length > 0);
        return mMemory[mCurrentBlock][];
    }

    extern(C)
    {
        alias malloc_t = void* function(size_t) pure nothrow @nogc;
        alias free_t = void function(void*) pure nothrow @nogc;
    }

    void allocNextBlock(size_t size)
    {
        assert(size > 0);
        assert(ispow2(size));
        assert(mTotalBlocks < (mMemory.length - 1));
        auto newBlock = (cast(malloc_t)&malloc)(size); //cast to make it pure
        if(newBlock is null)
        {
            onOutOfMemoryError(); //must throw
            assert(false);
        }
        mMemory[mTotalBlocks] = newBlock[0..size];
        ++mTotalBlocks;
        mCapacity += size;
    }
public:
    this(size_t initialBytes)
    {
        import std.algorithm;
        allocNextBlock(uppow2(max(16,initialBytes)));
        mPtr = mMemory[0].ptr;
    }

    ~this()
    {
        foreach(i;0..mTotalBlocks)
        {
            assert(mMemory[i].ptr !is null);
            (cast(free_t)&free)(mMemory[i].ptr);
            mMemory[i] = MemRange.init;
        }
    }

    struct State
    {
        size_t val;
        debug
        {
            void* ptr;
            int block;
            int index;
        }
    }

    @property State state()
    {
        assert(ispow2(mMemory[0].length));
        assert(mPtr >= currentMemBlock.ptr);
        const ptrdiff_t dptr = (mPtr - currentMemBlock.ptr);
        assert(dptr >= 0);
        assert(cast(size_t)dptr < cast(size_t)(mMemory[0].length << mCurrentBlock));
        const val = (mMemory[0].length << mCurrentBlock) + dptr;
        assert(0 != val);
        debug
        {
            return State(val, mPtr, mCurrentBlock,mLastAllocIndex++);
        }
        else
        {
            return State(val);
        }
    }

    void restoreState(State s)
    {
        debug
        {
            assert(s.index == (mLastAllocIndex - 1));
            --mLastAllocIndex;
        }
        import core.bitop;
        assert(0 != s.val);
        assert(ispow2(mMemory[0].length));
        const val = bsr(s.val);
        mCurrentBlock = val - bsr(mMemory[0].length);
        debug assert(mCurrentBlock == s.block);
        assert(mCurrentBlock >= 0);
        assert(mCurrentBlock < mTotalBlocks);
        mPtr = currentMemBlock.ptr + (s.val - (mMemory[0].length << mCurrentBlock));
        debug assert(mPtr == s.ptr);
        assert(mPtr >= mMemory[mCurrentBlock].ptr);
        assert(mPtr <= (mMemory[mCurrentBlock].ptr + mMemory[mCurrentBlock].length));
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
        while(true)
        {
            auto mem = currentMemBlock;
            assert(mPtr >= mem.ptr);
            auto ptr = alignPointer!T(mPtr);
            assert(ptr >= mem.ptr);
            const ptrdiff_t totalSize = size * count;
            const ptrdiff_t sizeAvail = mem.length - (ptr - mem.ptr);
            if(totalSize > sizeAvail)
            {
                if(mMemory[mCurrentBlock + 1].length == 0)
                {
                    allocNextBlock(capacity);
                }
                ++mCurrentBlock;
                mPtr = currentMemBlock.ptr;
                continue;
            }
            assert(cast(void*)ptr >= currentMemBlock.ptr);
            assert(cast(void*)ptr < (currentMemBlock.ptr + currentMemBlock.length));
            mPtr = cast(void*)ptr + totalSize;
            assert(mPtr >= cast(void*)ptr);
            return (cast(T*)ptr)[0..count];
        }
        assert(false);
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
        return mCapacity;
    }

    //TODO: size

}
//TODO: tests
