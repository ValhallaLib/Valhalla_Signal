module vsignal.signal;

import vsignal.slot;

struct Signal(F)
	if (is(F : RT delegate(Args), RT, Args...))
{

}
