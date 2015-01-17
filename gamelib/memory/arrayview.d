module gamelib.memory.arrayview;

import std.traits;
import gamelib.types;

struct ArrayView(T)
{
@nogc:
pure nothrow:
private:
    T[] array;
    ptrdiff_t zeroIndex = 0;
public:
    this(T[] src, ptrdiff_t lowInd = 0)
    {
        array = src;
        zeroIndex = lowInd;
    }

    ref auto opIndex(ptrdiff_t i) inout
    in
    {
        assert(i >= low, debugConv(i," ",low," ",high));
        assert(i < high, debugConv(i," ",low," ",high));
    }
    body
    {
        return array[i - zeroIndex];
    }

    auto opSlice(ptrdiff_t i1,ptrdiff_t i2) inout
    in
    {
        assert(i1 >= low,  debugConv(i1," ",i2," ",low," ",high));
        assert(i1 <= high, debugConv(i1," ",i2," ",low," ",high));
        assert(i2 >= low,  debugConv(i1," ",i2," ",low," ",high));
        assert(i2 <= high, debugConv(i1," ",i2," ",low," ",high));
        assert(i2 >= i1,   debugConv(i1," ",i2," ",low," ",high));
    }
    body
    {
        return array[i1 - zeroIndex..i2 - zeroIndex];
    }

    auto opSliceAssign(U)(in U val, ptrdiff_t i1,ptrdiff_t i2) if(isAssignable!(T[],U))
    in
    {
        assert(i1 >= low,  debugConv(i1," ",i2," ",low," ",high));
        assert(i1 <= high, debugConv(i1," ",i2," ",low," ",high));
        assert(i2 >= low,  debugConv(i1," ",i2," ",low," ",high));
        assert(i2 <= high, debugConv(i1," ",i2," ",low," ",high));
        assert(i2 >= i1,   debugConv(i1," ",i2," ",low," ",high));
    }
    body
    {
        return array[i1 - zeroIndex..i2 - zeroIndex] = val;
    }

    @property low()  const { return zeroIndex; }
    @property high() const { return cast(ptrdiff_t)array.length + zeroIndex; }
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