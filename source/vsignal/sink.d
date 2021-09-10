module vsignal.sink;

import vsignal.signal;
import vsignal.slot : Slot, slot_connect = connect;

void disconnect(alias pred, F)(auto ref Sink!F sink)
{
	import std.algorithm.mutation : remove, SwapStrategy;
	import std.algorithm.searching : countUntil;

	Slot!F call;
	call.slot_connect!pred;

	with (sink)
	{
		const index = signal.calls.countUntil(call);

		if (index > -1)
			signal.calls = signal.calls.remove!(SwapStrategy.unstable)(index);
	}
}

void disconnect(alias pred, T, F)(auto ref Sink!F sink, ref T instance)
{
	import std.algorithm.mutation : remove, SwapStrategy;
	import std.algorithm.searching : countUntil;

	Slot!F call;
	call.slot_connect!pred(instance);

	with (sink)
	{
		const index = signal.calls.countUntil(call);

		if (index > -1)
			signal.calls = signal.calls.remove!(SwapStrategy.unstable)(index);
	}
}

private void release(alias pred, F)(void* signal)
{
	Sink!F(() @trusted { return cast(Signal!F*) signal; } ()).disconnect!pred();
}

private void release(alias pred, T, F)(ref T instance, void* signal)
{
	Sink!F(() @trusted { return cast(Signal!F*) signal; } ()).disconnect!pred(instance);
}

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
