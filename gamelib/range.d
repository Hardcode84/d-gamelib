module gamelib.range;

import std.range;

auto adjacent(R)(R range)
{
    return zip(range,range.drop(1));
}

unittest
{
    import std.typecons;
    static if( __VERSION__ >= 2067 )
    {
        import std.algorithm.comparison;
    }
    assert(adjacent([1,2][0..0]).empty);
    assert(adjacent([1]).empty);
    assert(adjacent([1,2]).equal([tuple(1,2)]));
    assert(adjacent([1,2,3]).equal([tuple(1,2),tuple(2,3)]));
    assert(adjacent([1,2,3,4]).equal([tuple(1,2),tuple(2,3),tuple(3,4)]));
}