module vsignal.signal;

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
