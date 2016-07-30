module gamelib.asserthandler;

import std.stdio;
import core.runtime;
import core.stdc.stdlib;

version(GamelibHandleAssert)
{
pragma(inline, false):
extern(C):
    void _d_assertm(immutable(ModuleInfo)* m, uint line)
    {
        myAssertHandler(m.name, line, 1);
    }

    void _d_assert_msg(string msg, string file, uint line)
    {
        myAssertHandler(file, line, msg, 1);
    }

    void _d_assert(string file, uint line)
    {
        myAssertHandler(file, line, 1);
    }

    void _d_array_bounds(immutable(ModuleInfo)* m, uint line)
    {
        myRangeErrorHandler(m.name, line, 1);
    }

    void _d_arraybounds(string file, uint line)
    {
        myRangeErrorHandler(file, line, 1);
    }

    void _d_switch_error(immutable(ModuleInfo)* m, uint line)
    {
        mySwitchErrorHandler(m.name, line, 1);
    }
}

pragma(inline, false):
void printStacktrace(size_t skipFrames) nothrow
{
    try
    {
        foreach(i,const f; defaultTraceHandler)
        {
            if(i >= skipFrames)
            {
                writeln(f);
            }
        }
    }
    catch(Throwable t)
    {
        try
        {
            writeln("Unable to print stacktrace: ", t);
        }
        catch(Throwable)
        {
        }
    }
}

private:
void mySwitchErrorHandler(string file, size_t line, size_t skipFrames) nothrow
{
    myAssertHandler(file, line, "No appropriate switch clause found", skipFrames + 1);
}

void myRangeErrorHandler(string file, size_t line, size_t skipFrames) nothrow
{
    myAssertHandler(file, line, "Range violation", skipFrames + 1);
}

void myAssertHandler(string file, size_t line, size_t skipFrames) nothrow
{
    myAssertHandler(file, line, "Assertion failure", skipFrames + 1);
}

void myAssertHandler(string file, size_t line, string msg, size_t skipFrames) nothrow
{
    try
    {
        writefln("%s(%s): %s", file, line, msg);
        printStacktrace(skipFrames + 1);
    }
    catch(Throwable)
    {
    }
    abort();
}
