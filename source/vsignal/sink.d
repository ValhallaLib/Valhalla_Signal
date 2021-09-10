module vsignal.sink;

import vsignal.signal;
import vsignal.slot : Slot, slot_connect = connect;

struct Sink(F)
{
private:
	Signal!F* signal;
}

struct Connection
{
	void release()()
	{
		if (disconnect)
		{
			disconnect(signal);
			disconnect.reset();
		}
	}

private:
	Slot!(void delegate(void*) @safe pure nothrow) disconnect;
	void* signal;
}
