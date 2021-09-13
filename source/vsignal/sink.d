module vsignal.sink;

import vsignal.signal;
import vsignal.slot : Slot, slot_connect = connect;

/**
Connect a listener to a Signal.

A payload can be passed if the function to call is a data member function of the
same or if the function accepts as its first parameter a reference to its type.

Params:
	pred = the listener to connect.
	sink = the Sink that holds the signal.
	instance = the payload to store.

Returns: A Connection of the listener.
*/
Connection connect(alias pred, F)(auto ref Sink!F sink)
{
	sink.disconnect!pred;

	import core.lifetime : move;

	with (sink)
	{
		Slot!F call;
		call.slot_connect!pred;
		signal.calls ~= call.move();

		Slot!(void delegate(void* signal) @safe pure nothrow) conn;
		conn.slot_connect!(release!(pred, F))();

		return Connection(conn.move(), signal);
	}
}

///
Connection connect(alias pred, T, F)(auto ref Sink!F sink, ref T instance)
{
	sink.disconnect!pred(instance);

	import core.lifetime : move;

	with (sink)
	{
		Slot!F call;
		call.slot_connect!pred(instance);
		signal.calls ~= call.move();

		Slot!(void delegate(void* signal) @safe pure nothrow) conn;
		conn.slot_connect!(release!(pred, T, F))(instance);

		return Connection(conn.move(), signal);
	}
}

/++
Disconnects a listener from a Signal. The order is not preserved after the
removal.

Examples:
---
void method() {}
struct Foo { void method() {} }
Foo foo;

/* ... */

// lets assume a signal exists with listeners
sink.disconnect!(Foo.method)(foo); // disconnects Foo.method with payload foo
sink.disconnect!method;            // disconnects method
sink.disconnect(foo);              // disconnects all listeners with payload foo
sink.disconnect();                 // disconnects all listeners
---

Params:
	pred = the listener to disconnect.
	sink = the Sink that holds the signal.
	instance = the payload that composes the listener.
+/
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

///
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

///
void disconnect(T, F)(auto ref Sink!F sink, ref T instance)
{
	import std.algorithm.mutation : remove, SwapStrategy;

	with (sink)
	{
		signal.calls = signal.calls.remove!(call => call.payload is &instance , SwapStrategy.unstable);
	}
}

///
void disconnect(F)(auto ref Sink!F sink)
{
	sinksignal.calls = [];
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
	this(scope Signal!F* sig)
	{
		signal = sig;
	}

	size_t length() const @property
	{
		return signal.length;
	}

	bool empty() const @property
	{
		return signal.empty;
	}

private:
	Signal!F* signal;
}

struct Connection
{
	bool opCast(T : bool)() const
	{
		return disconnect;
	}

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
