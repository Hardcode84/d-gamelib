module gamelib.graphics.surfaceview;

import std.traits;
import gamelib.types;

@nogc:
struct SurfaceView(ElemT,int TileW = 1,int TileH = 1)
{
@nogc:
private:
    static assert(TileW > 0);
    static assert(TileH > 0);
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
        mData   = surf.data;
    }

    auto opIndex(int y) inout pure nothrow
    {
        struct Line
        {
        private:
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
                assert(x >= 0);
                debug
                {
                    assert(x < width,  debugConv(x));
                    assert(y >= 0,     debugConv(y));
                    assert(y < height, debugConv(y));
                }
            }
        public:
            
            auto opIndex(int x) const pure nothrow
            {
                checkCoord(x);
                return data[x];
            }

            static if(M) auto opIndexAssign(T)(in T value, int x) pure nothrow if(isAssignable!(ElemT,T))
            {
                checkCoord(x);
                return data[x] = value;
            }

            auto opSlice(int x1, int x2) pure nothrow
            {
                checkCoord(x1);
                assert(x2 >= x1);
                debug assert(x2 <= width);
                return data[x1..x2];
            }

            auto opSlice(int x1, int x2) const pure nothrow
            {
                checkCoord(x1);
                assert(x2 >= x1);
                debug assert(x2 <= width);
                return data[x1..x2];
            }

            static if(M) auto opSliceAssign(T)(in T val, int x1, int x2) pure nothrow if(isAssignable!(ElemT,T))
            {
                checkCoord(x1);
                assert(x2 >= x1);
                debug assert(x2 <= width);
                return data[x1..x2] = val;
            }

            ref auto opUnary(string op)() pure nothrow if(op == "++" || op == "--")
            {
                mixin("data = cast(ElemT*)(cast(byte*)data"~op[0]~" pitch);");
                debug
                {
                    mixin("y"~op~";");
                }
                return this;
            }
        }

        assert(mData);
        Line ret = {pitch: mPitch, data: cast(ElemT*)(mData + mPitch * y) };
        debug
        {
            ret.width = mWidth;
            ret.height = mHeight;
            ret.y = y;
        }
        return ret;
    }
}

