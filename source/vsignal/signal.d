module vsignal.signal;

struct Signal(F)
	if (is(F : RT delegate(Args), RT, Args...))
{

}
