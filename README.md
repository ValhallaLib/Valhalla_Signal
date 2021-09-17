# VSignal

A Signals/Slots implementation in D. This implementation is based on the pattern
used in [ENTT](https://github.com/skypjack/entt/wiki/Crash-Course:-events,-signals-and-everything-in-between#signals).

---

A Signal is declared with a **delegate**:

```d
Signal!(void delegate(int)) sig;
```

To connect listeners a function pointer, lambda, or delegate can be passed:

```d
void foo(const int) {}

sig.sink.connect!((int) {});
sig.sink.connect!foo;
```

---

Forward is applied when possible. However, in D `forward` treats `lvalues` as `rvalues` to fix the ambiguity problem (see [here](https://druntime.dpldocs.info/core.lifetime.forward.html#examples)). To go around the situations when trying to `move` does not work, Signal fallsback to the normal execution for **that** variable and does a **copy**.

This can cause a slight bump in the execution speed when using a `Signal!(void delegate(int))` and connecting a `void delegate(ref int)` listener for example.

---

When connecting lambdas the parameters can be omitted:

```d
sig.sink.connect((_) {});
sig.sink.connect((const _) {});
sig.sink.connect((ref _) {});
sig.sink.connect((ref const _) {});
```

Signal also accepts connecting listeners from instances:

```d
struct Listener
{
	void opCall(const int) {}
}

Listener listener;

sig.sink.connect!(Listener.opCall)(listener);
```

---

As seen above, it is possible to attach an instance to a **Slot**. This also has some advantages for structuring the code internally. It also allows the user to specify a listener that receives a `ref`. Take a look at the following:

```d
void bar(immutable ref int, int) {}
immutable int var = 5;

sig.sink.connect!bar(var);
sig.emit(45);
```

As seen, the **Signal** is still `void delegate(int)` however, the **Slot** that contains the listener `bar` also has attached the payload `var`, which will be passed to the function's first argument.

---

Listener connection must be executed with **Sink**. As seen throughout this explanation, all examples use `sink` before connecting a listener. This allows for **Signal** to be declared privately internally to omit `emit` functionality to the user. The user receives a **Sink** a works with it to `connect` and `disconnect` listeners. The **Sink** also returns another data structure to help managing listeners. The **Connection** structure is returned every time a connection is made. **Connection** allows the user to break a connection without having to rely on managing **Signal** or **Sink** instances.

---

## Signal usage example:

```d
@safe void foo(immutable ref Listener, int) {}
@safe void bar(int) {}

@safe struct Listener
{
	void opCall(const int) {}
}

void main() @safe
{
	Signal!(void delegate(int) @safe) sig;

	// this can be @trusted because sink's lifetime is lower than sig's.
	auto sink = () @trusted { return sig.sink; } ();

	with (sig.sink)
	{

		Listener listener;

		// connecting
		sink.connect!(Listener.opCall)(listener);
		sink.connect!foo(listener);
		sink.connect!bar;
		auto connection = sink.connect!((ref _) {});

		sig.emit(45);

		// disconnect a listener with an instance
		sink.disconnect!(Listener.opCall)(instance);

		// disconnect a listener
		sink.disconnect!bar;

		// disconnect all listeners with an instance
		sink.disconnect(listener);

		// disconnect all listeners
		sink.disconnect();

		// for lambdas the connection must be used
		connection.release();
	}
}
```

## Licensed under:
* [MIT license](https://github.com/ValhalaLib/valhala_ecs/blob/master/LICENSE)

## Contribution:
If you are interested in project and want to improve it, creating issues and
pull requests are highly appretiated!
