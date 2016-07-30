module gamelib.asserthandler;

import std.stdio;
import core.runtime;
import core.stdc.stdlib;

version(GamelibHandleAssert)
{
extern(C):
    void _d_assertm(immutable(ModuleInfo)* m, uint line)
    {
        myAssertHandler(m.name, line);
    }

    void _d_assert_msg(string msg, string file, uint line)
    {
        myAssertHandler(file, line, msg);
    }

    void _d_assert(string file, uint line)
    {
        myAssertHandler(file, line);
    }
}

void printStacktrace()
{
    try
    {
        defaultTraceHandler.writeln;
    }
    catch(Throwable t)
    {
        writeln("Unable to print stacktrace: ", t);
    }
}

private:
void myAssertHandler(string file, size_t line)
{
    myAssertHandler(file, line, "Assertion failure");
}

void myAssertHandler(string file, size_t line, string msg)
{
    writefln("%s(%s): %s", file, line, msg);
    printStacktrace();
    abort();
}
