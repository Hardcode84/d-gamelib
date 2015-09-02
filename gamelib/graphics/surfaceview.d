module gamelib.graphics.surfaceview;

import std.traits;
import gamelib.types;
import gamelib.math;

@nogc:
struct SurfaceView(ElemT,bool Wrap = false)
{
@nogc:
private:
    immutable int    mWidth;
    immutable int    mHeight;
    immutable size_t mPitch;
    enum M = isMutable!ElemT;
    static if(M) void*  mData;
    else   const(void*) mData;
public:
    this(T)(auto ref T surf)
    {
        mWidth  = surf.width;
        mHeight = surf.height;
        mPitch  = surf.pitch;
        mData   = cast(typeof(mData))surf.data;
    }

    this(int width, int height, int pitch, typeof(mData) data)
    {
        mWidth  = width;
        mHeight = height;
        mPitch  = pitch;
        mData   = data;
    }

    auto opIndex(int y) inout pure nothrow
    {
        struct Line
        {
        private:
            static if(Wrap)
            {
                uint wmask;
                uint hmask;
                int  curr_y;
            }
            debug
            {
                int width;
                int height;
                int y;
            }
            size_t pitch;
            ElemT* data;
            
            void checkCoord(int x) const pure nothrow
            {
                assert(x >= 0, debugConv(x));
                debug
                {
                    assert(x < width,  debugConv(x));
                    assert(y >= 0,     debugConv(y));
                    assert(y < height, debugConv(y));
                }
            }
            void correctX(ref int x) const pure nothrow
            {
                static if(Wrap)
                {
                    x &= wmask;
                }
            }
            void correctY(ref int y) const pure nothrow
            {
                static if(Wrap)
                {
                    y &= hmask;
                }
            }
        public:

            auto opIndex(int x) const pure nothrow
            {
                correctX(x);
                checkCoord(x);
                return data[x];
            }

            auto opIndexAssign(T)(in T value, int x) pure nothrow if(M && isAssignable!(ElemT,T))
            {
                correctX(x);
                checkCoord(x);
                return data[x] = value;
            }

            auto opSlice(int x1, int x2) pure nothrow
            {
                assert(x2 >= x1);
                correctX(x1);
                correctX(x2);
                checkCoord(x1);
                debug assert(x2 <= width);
                return data[x1..x2];
            }

            auto opSlice(int x1, int x2) const pure nothrow
            {
                assert(x2 >= x1);
                correctX(x1);
                correctX(x2);
                checkCoord(x1);
                debug assert(x2 <= width);
                return data[x1..x2];
            }

            auto opSliceAssign(T)(in T val, int x1, int x2) pure nothrow if(M && isAssignable!(typeof(data[x1..x2]),T))
            {
                assert(x2 >= x1);
                correctX(x1);
                correctX(x2);
                checkCoord(x1);
                debug assert(x2 <= width, debugConv(x2));
                return data[x1..x2] = val;
            }

            ref auto opUnary(string op)() pure nothrow if(op == "++" || op == "--")
            {
                mixin("data = cast(ElemT*)(cast(byte*)data"~op[0]~" pitch);");
                debug
                {
                    mixin("y"~op~";");
                    correctY(y);
                }
                static if(Wrap)
                {
                    mixin("curr_y"~op~";");
                    const oldy = curr_y;
                    correctY(curr_y);
                    const dy = curr_y - oldy;
                    data = cast(ElemT*)(cast(byte*)data + pitch * dy);
                }
                return this;
            }
        }
        static if(Wrap)
        {
            assert(ispow2(mWidth),  debugConv(mWidth));
            assert(ispow2(mHeight), debugConv(mWidth));
            y &= (mHeight - 1);
        }
        assert(mData);
        Line ret = {pitch: mPitch, data: cast(ElemT*)(mData + mPitch * y) };
        debug
        {
            ret.width  = mWidth;
            ret.height = mHeight;
            ret.y = y;
        }
        static if(Wrap)
        {
            ret.curr_y = y;
            ret.wmask = mWidth  - 1;
            ret.hmask = mHeight - 1;
        }
        return ret;
    }
}

