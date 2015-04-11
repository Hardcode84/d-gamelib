module gamelib.debugout;

debug
{
    import std.stdio;
}

static if( __VERSION__ < 2066 )
{
    enum HasNogc = false;
    enum nogc = 1;
}
else
{
    enum HasNogc = true;
}

private void outImpl(T...)(in T args) pure nothrow @trusted
{
    debug
    {
        try
        {
            import std.stdio;
            writeln(args);
        }
        catch(Exception e) {}
    }
}

private void foutImpl(T...)(in T args) pure nothrow @trusted
{
    debug
    {
        try
        {
            import std.stdio;
            writefln(args);
        }
        catch(Exception e) {}
    }
}

private string convImpl(T...)(in T args) pure nothrow @trusted
{
    static assert(args.length > 0);
    debug
    {
        try
        {
            import std.array;
            import std.conv;
            string[args.length] ret;
            foreach(i,a;args)
            {
                ret[i] = text(a);
            }
            return ret[].join;
        }
        catch(Exception e) { return ""; }
    }
    else return "";
}


debug
{
    @nogc pure nothrow @trusted:
    void debugOut(T...)(in T args)
    {
        static if(HasNogc)
        {
            //dirty hack to shut up compiler
            mixin(`
            alias fn_t = string function(in T) pure nothrow @nogc;
            cast(void)(cast(fn_t)&outImpl!T)(args); //hack to add @nogc`);
        }
        else
        {
            outImpl(args);
        }
    }
    
    void debugfOut(T...)(in T args)
    {
        static if(HasNogc)
        {
            //dirty hack to shut up compiler
            mixin(`
            alias fn_t = string function(in T) pure nothrow @nogc;
            cast(void)(cast(fn_t)&foutImpl!T)(args); //hack to add @nogc`);
        }
        else
        {
            foutImpl(args);
        }
    }
    
    auto debugConv(T...)(in T args)
    {
        static if(HasNogc)
        {
            //dirty hack to shut up compiler
            mixin(`
            alias fn_t = string function(in T) pure nothrow @nogc;
            return (cast(fn_t)&convImpl!T)(args); //hack to add @nogc`);
        }
        else
        {
            return convImpl(args);
        }
    }
}
else
{
    @nogc pure nothrow @trusted:
    void debugOut(T...)(in T args) {}
    void debugfOut(T...)(in T args) {}
    auto debugConv(T...)(in T args) { return ""; }
    void debugOut(T...)(in ref T args) {}
    void debugfOut(T...)(in ref T args) {}
    auto debugConv(T...)(in ref T args) { return ""; }
}

debug unittest
{
    assert("10" == debugConv("10"));
    assert("10" == debugConv(10));
    assert("1.1" == debugConv(1.1f));
    assert("110foo" == debugConv(1,10,"foo"));
    
    debugOut("test debug out");
    debugOut(1);
    debugOut(1.1f);
    debugOut(1,2,3);
    debugOut(1.0,2.0,3.0);
    debugOut("1","2","3");
    debugfOut("test formatted debug out %s, %s, %s", 1, 2.0, "3");
}