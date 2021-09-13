module vsignal.slot;

/**
Binds a function to a Slot. A payload can be passed if the function to call is
a data member function of the same or if the function accepts as its first
parameter a reference to its type.

Params:
	pred = the function to bind.
	slot = the Slot that holds the function.
	instance = the payload to keep.
*/
package void connect(alias pred, F)(auto ref Slot!F slot)
{
	import vsignal.utils : tryForward;

	with(slot)
	{
		payload = null;
		fn = (const scope void*, Parameters args) {
			static if (is(ReturnType == void))
				pred(tryForward!(pred, args));
			else
				return ReturnType(pred(tryForward!(pred, args)));
		};
	}
}

@safe pure nothrow @nogc unittest
{
	Slot!(void delegate(int)) slot;

	class C
	{
		static void opCall(int) {}
		static void fooA(const int) {}
		static void fooB(ref int) {}
		static void fooC(const ref int) {}
	}

	// all lambda listeners can omit the type
	slot.connect!((ref _)       {});
	slot.connect!((const ref _) {});
	slot.connect!((_)           {});
	slot.connect!((const _)     {});

	slot.connect!(C.opCall);
	slot.connect!(C.fooA);
	slot.connect!(C.fooB);
	slot.connect!(C.fooC);
}

///
package void connect(alias pred, T, F)(auto ref Slot!F slot, ref T instance)
{
	with(slot)
	{
		payload = () @trusted { return cast(from!"std.traits".Unqual!T*) &instance; } ();
		fn = (const scope void* payload, Parameters args)
		{
			import core.lifetime : forward;
			import vsignal.utils : invoke;

			T* type = () @trusted { return cast(T*) payload; } ();

			static if (is(ReturnType == void))
				invoke!pred(*type, forward!args);
			else
				return ReturnType(invoke!pred(*type, forward!args));
		};
	}
}

@safe pure nothrow @nogc unittest
{
	Slot!(void delegate(int)) slot;

	struct Listener
	{
		void opCall(int) {}
		void fooA(const int) {}
		void fooB(ref int) {}
		void fooC(const ref int) {}
	}

	Listener listener;

	slot.connect!(Listener.opCall)(listener);
	slot.connect!(Listener.fooA)(listener);
	slot.connect!(Listener.fooB)(listener);
	slot.connect!(Listener.fooC)(listener);
}

package struct Slot(F)
{
	import vsignal.utils : from;

	alias SlotType = F;
	alias ReturnType = from!"std.traits".ReturnType!F;
	alias Parameters = from!"std.traits".Parameters!F;
	alias Function   = from!"std.traits".SetFunctionAttributes!(
		ReturnType delegate(const scope void*, Parameters),
		from!"std.traits".functionLinkage!SlotType,
		from!"std.traits".functionAttributes!SlotType
	);

	auto opCall(Parameters args)
	{
		return fn(payload, from!"core.lifetime".forward!args);
	}

	bool opEquals(F)(const Slot!F other) const
	{
		return fn.funcptr is other.fn.funcptr && payload is other.payload;
	}

	void reset()
	{
		fn = null;
		payload = null;
	}

	bool opCast(T : bool)() const
	{
		return fn.funcptr !is null;
	}

package:
	Function fn;
	void* payload;
}

///
unittest
{
	@safe struct Listener
	{
		int i;

		auto foo(int var) return
		{
			i = var;
			return &this;
		}
	}

	Listener listener;
	alias myfoo = Listener.foo;

	Slot!(Listener* delegate(int) @safe) slot;

	slot.connect!(myfoo)(listener);

	assert(slot(4) is &listener);
	assert(listener.i == 4);
}
