module vsignal.sink;

import vsignal.signal;

struct Sink(F)
{
private:
	Signal!F* signal;
}

struct Connection
{
private:
	Slot!(void delegate(void*) @safe pure nothrow) disconnect;
	void* signal;
}
