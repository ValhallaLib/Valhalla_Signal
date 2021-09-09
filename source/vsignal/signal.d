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
