module vsignal.signal;

import vsignal.sink;
import vsignal.slot;

struct Signal(F)
	if (is(F : RT delegate(Args), RT, Args...))
{
	/**
	Publish a signal.

	Params:
		args = the Signal's function parameters to call each listener with.
	*/
	void emit(Slot!F.Parameters args)
	{
		import core.lifetime : forward;

		foreach (call; calls)
			cast(void) call(forward!args);
	}

	/**
	Get a Sink to connect and disconnect listeners from a Signal.

	This function can be @trusted if the lifetime of the Sink does not extend the
	lifetime of the Signal.

	Note: DIP1000 can detect if a reference escapes and as such it can infer @safe.

	Returns: A newly constructed Sink.
	*/
	Sink!F sink(this This)()
	{
		// https://issues.dlang.org/show_bug.cgi?id=22309
		auto sinkImpl = (ref return This signal) => Sink!F(&signal);

		return sinkImpl(this);
	}

	bool empty() const @property
	{
		return !calls.length;
	}

	size_t length() const @property
	{
		return calls.length;
	}

package:
	Slot!F[] calls;
}

///
unittest
{
	Signal!(void delegate(int) @safe pure nothrow) signal;
	Signal!(void delegate(ref int) @safe pure nothrow) signalRef;

	static struct Listener
	{
		int i;
		void opCall()(const ref int)
		{
			i++;
		}
	}

	Listener listener;

	signal.sink.connect!(Listener.opCall)(listener);
	signalRef.sink.connect!(Listener.opCall)(listener);

	int var;

	signal.emit(var);
	signalRef.emit(var);

	assert(listener.i == 2);
}

///
unittest
{
	Signal!(void delegate(int)) signal;
	int var = 35;

	signal.sink.connect!((ref i, const int x) {
		assert(&i is &var);
		i += x;
	})(var);

	signal.emit(3);

	assert(var == 38);
}

unittest
{
	Signal!(void delegate(int)) sig;

	struct Listener
	{
		int i;
		void opCall(int var) { i = var; }
	}

	Listener listener;

	Slot!(void delegate(int)) slotA;
	Slot!(void delegate(int)) slotB;

	slotA.connect!(Listener.opCall)(listener);
	slotB.connect!((ref i) => listener.i++ );

	sig.calls = [
		slotA,
		slotB
	];

	sig.emit(5);
	assert(listener.i == 6);
}
