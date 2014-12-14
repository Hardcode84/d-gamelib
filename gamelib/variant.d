module gamelib.variant;

public import std.variant;
import std.traits: isSomeFunction, ParameterTypeTuple, Unqual;

auto visit(VariantType, HandlerT...)(VariantType variant, HandlerT handler)
    if (isAlgebraic!VariantType && HandlerT.length > 0)
{
    return visitImpl!(true, VariantType, HandlerT)(variant, handler);
}

auto tryVisit(VariantType, HandlerT...)(VariantType variant, HandlerT handler)
    if (isAlgebraic!VariantType && HandlerT.length > 0)
{
    return visitImpl!(false, VariantType, HandlerT)(variant, handler);
}

private template isAlgebraic(Type)
{
    static if (is(Type _ == VariantN!T, T...))
        enum isAlgebraic = T.length >= 2; // T[0] == maxDataSize, T[1..$] == AllowedTypesX
    else
        enum isAlgebraic = false;
}

private auto visitImpl(bool Strict, VariantType, HandlerT...)(VariantType variant, HandlerT handler)
    if (isAlgebraic!VariantType && HandlerT.length > 0)
{
    alias AllowedTypes = VariantType.AllowedTypes;


    /**
     * Returns: Struct where $(D_PARAM indices)  is an array which
     * contains at the n-th position the index in Handler which takes the
     * n-th type of AllowedTypes. If an Handler doesn't match an
     * AllowedType, -1 is set. If a function in the delegates doesn't
     * have parameters, the field $(D_PARAM exceptionFuncIdx) is set;
     * otherwise it's -1.
     */
    auto visitGetOverloadMap()
    {
        struct Result {
            int[AllowedTypes.length] indices;
            int exceptionFuncIdx = -1;
        }

        Result result;

        foreach(tidx, T; AllowedTypes)
        {
            bool added = false;
            foreach(dgidx, dg; HandlerT)
            {
                // Handle normal function objects
                static if (isSomeFunction!dg)
                {
                    alias Params = ParameterTypeTuple!dg;
                    static if (Params.length == 0)
                    {
                        // Just check exception functions in the first
                        // inner iteration (over delegates)
                        if (tidx > 0)
                            continue;
                        else
                        {
                            if (result.exceptionFuncIdx != -1)
                                assert(false, "duplicate parameter-less (error-)function specified");
                            result.exceptionFuncIdx = dgidx;
                        }
                    }
                    else if (is(Unqual!(Params[0]) == Unqual!T))
                    {
                        if (added)
                            assert(false, "duplicate overload specified for type '" ~ T.stringof ~ "'");

                        added = true;
                        result.indices[tidx] = dgidx;
                    }
                }
                // Handle composite visitors with opCall overloads
                else
                {
                    static assert(false, dg.stringof ~ " is not a function or delegate");
                }
            }

            if (!added)
                result.indices[tidx] = -1;
        }

        return result;
    }

    enum HandlerOverloadMap = visitGetOverloadMap();

    if (!variant.hasValue)
    {
        // Call the exception function. The HandlerOverloadMap
        // will have its exceptionFuncIdx field set to value != -1 if an
        // exception function has been specified; otherwise we just through an exception.
        static if (HandlerOverloadMap.exceptionFuncIdx != -1)
            return handler[ HandlerOverloadMap.exceptionFuncIdx ]();
        else
            throw new VariantException("variant must hold a value before being visited.");
    }

    foreach(idx, T; AllowedTypes)
    {
        import std.stdio;
        if (auto ptr = variant.peek!T)
        {
            enum dgIdx = HandlerOverloadMap.indices[idx];

            static if (dgIdx == -1)
            {
                static if (Strict)
                    static assert(false, "overload for type '" ~ T.stringof ~ "' hasn't been specified");
                else
                {
                    static if (HandlerOverloadMap.exceptionFuncIdx != -1)
                        return handler[ HandlerOverloadMap.exceptionFuncIdx ]();
                    else
                        throw new VariantException("variant holds value of type '" ~ T.stringof ~ "' but no visitor has been provided");
                }
            }
            else
            {
                return handler[ dgIdx ](*ptr);
            }
        }
    }

    assert(false);
}