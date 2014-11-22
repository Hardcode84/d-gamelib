module gamelib.memory.intrusiveptr;

import gamelib.memory.memory;

struct IntrusivePtr(T) if (!is(T == class))
{
private:
pure nothrow @safe:
    T* payload = null;

    void addRef()
    {
        if(isInitialized)
        {
            payload.addRef();
        }
    }
    void release()
    {
        if(isInitialized)
        {
            payload.release();
            payload = null;
        }
    }
public:
    @property
    bool isInitialized() const
    {
        return payload !is null;
    }

    this(T* ptr)
    {
        payload  = ptr;
    }

    this(this)
    {
        addRef();
    }

    ~this()
    {
        release();
    }

    void opAssign(typeof(this) rhs)
    {
        if(rhs.payload is payload) return;
        release();
        payload = rhs.payload;
        addRef();
    }

    void opAssign(T* rhs)
    {
        if(rhs is payload) return;
        release();
        payload = rhs;
        addRef();
    }

    @property nothrow @safe
    auto ptrPayload() inout
    {
        return payload;
    }

    @property nothrow @safe
    auto ref refPayload() inout
    {
        assert(isInitialized, "Attempted to access an uninitialized payload.");
        return *payload;
    }

    auto ref opUnary(string op : "*")()
    {
        return refPayload();
    }

    alias ptrPayload this;
}

