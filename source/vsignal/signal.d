module vsignal.signal;

import vsignal.sink;
import vsignal.slot;

struct Signal(F)
	if (is(F : RT delegate(Args), RT, Args...))
{
	void emit(Slot!F.Parameters args)
	{
		import core.lifetime : forward;

		foreach (call; calls)
			cast(void) call(forward!args);
	}

	Sink!F sink(this This)()
	{
		// https://issues.dlang.org/show_bug.cgi?id=22309
		auto sinkImpl = (ref return This signal) => Sink!F(&signal);

		return sinkImpl(this);
	}

package:
	Slot!F[] calls;
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
