module gamelib.graphics.memsurface;

import gamelib.types;

final class MemSurface(ElemT, int TileW = 1, int TileH = 1)
{
private:
    static assert(TileW > 0);
    static assert(TileH > 0);
    immutable int    mWidth;
    immutable int    mHeight;
    immutable size_t mPitch;
    ElemT*           mData;
public:
    this(int w, int h)
    in
    {
        assert(w > 0);
        assert(h > 0);
    }
    body
    {
        mData = new ElemT[w * h].ptr;
        mWidth = w;
        mHeight = h;
        mPitch = ElemT.sizeof * mWidth;
    }
    @property auto   width()  const pure nothrow { return mWidth; }
    @property auto   height() const pure nothrow { return mHeight; }
    @property size_t pitch()  const pure nothrow { return mPitch; }
    @property auto   data()   inout const pure nothrow { return mData; }

    final auto opIndex(int y) pure nothrow
    {
        import gamelib.graphics.surfaceview;
        SurfaceView!(ElemT,TileW,TileH) view = this;
        return view[y];
    }
    
    void fill(T)(in T val) pure nothrow if(isAssignable!(ElemT, T))
    {
        ElemT* d = data;
        data[0..mWidth] = val;
        foreach(i;1..mHeight)
        {
            d = cast(ElemT*)(cast(byte*)d + mPitch);
            d[0..mWidth] = data[0..mWidth];
        }
    }
}

