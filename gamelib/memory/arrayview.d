module gamelib.memory.arrayview;

import std.traits;
import gamelib.types;

struct ArrayView(T)
{
pure nothrow:
private:
    T[] array;
    ptrdiff_t zeroIndex = 0;
public:
    this(T[] src, ptrdiff_t low = 0)
    {
        array = src;
        zeroIndex = low;
    }

    auto opIndex(ptrdiff_t i) const
    {
        return array[i - zeroIndex];
    }

    auto opIndexAssign(U)(U val, ptrdiff_t i) if(isAssignable!(T,U))
    {
        return array[i - zeroIndex] = val;
    }

    auto opSlice(ptrdiff_t i1,ptrdiff_t i2) inout
    {
        return array[i1 - zeroIndex..i2 - zeroIndex];
    }

    auto opSliceAssign(U)(in U val, ptrdiff_t i1,ptrdiff_t i2) if(isAssignable!(T[],U))
    {
        return array[i1 - zeroIndex..i2 - zeroIndex] = val;
    }

    @property low()  const { return zeroIndex; }
    @property high() const { return array.length + zeroIndex; }
}

unittest
{
    alias IntView = ArrayView!int;
    int[] arr = [0,1,2,3,4,5];
    auto arrview = IntView(arr,-2);
    assert(-2 == arrview.low);
    assert(4 == arrview.high);
    assert(0 == arrview[-2]);
    assert(2 == arrview[0]);
    assert(5 == arrview[3]);
    arrview[1] = 7;
    assert(7 == arrview[1]);
    import std.algorithm;
    assert(equal(arrview[-2..4],[0,1,2,7,4,5][]));
    arrview[-2..4] = [5,4,3,2,1,0];
    assert(equal(arrview[-2..4],[5,4,3,2,1,0][]));
}