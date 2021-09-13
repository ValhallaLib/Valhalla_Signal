module vsignal.utils;

/**
Attempts to forward each parameter. If a parameters cannot be forwarded to F
then the same is treated as an 'lvalue' and copied.

Params:
	F = Function to follow.
	args = a parameter list or an std.meta.AliasSeq.

Returns: An `AliasSeq` of args ready to be correctly forwarded or copied.
*/
package template tryForward(alias F, args...)
{
	import core.lifetime : forward;
	import std.meta : AliasSeq;

	// binary search forwardable params
	template tryForwardImpl(size_t l, size_t r)
	{
		alias fwd = forward!(args[l..r]);

		// Safe clause
		static if (l == r)
			alias tryForwardImpl = AliasSeq!();

		// If it compiles then F(..., (l .. r), ...) can be forwarded
		else static if (__traits(compiles, F(args[0..l], fwd, args[r..$])))
			alias tryForwardImpl = fwd;

		// If we're down to 2 elems just recurse each
		else static if (r - l == 2)
			alias tryForwardImpl = AliasSeq!(tryForwardImpl!(l, r - 1), tryForwardImpl!(r - 1, r));

		// If it didn't compile and we have 1 elem left then treat as `lvalue`
		else static if (r - l == 1)
			alias tryForwardImpl = args[l..r];

		// If all else fails divide in half
		else
			alias tryForwardImpl = AliasSeq!(tryForwardImpl!(l, r / 2), tryForwardImpl!(r / 2, r));
	}

	alias tryForward = tryForwardImpl!(0, args.length);
}

@safe pure nothrow @nogc unittest
{
	class C
	{
		static int foo(int) { return 1; }
		static int foo(ref int) { return 2; }

		static int foo(int, ref int) { return 1; }
		static int foo(ref int, int) { return 2; }

		static int foo(ref int, int, const int, const ref int) { return 2; }
	}

	int foo(Args...)(auto ref Args args)
	{
		return C.foo(tryForward!(C.foo, args));
	}

	int i;

	assert(foo(4) == 1);
	assert(foo(i) == 2);

	assert(foo(4, i) == 1);
	assert(foo(i, 4) == 2);

	assert(foo(i, 4, i, 4) == 2);

	static assert(!__traits(compiles, foo(i, i)));
	static assert(!__traits(compiles, foo(4, 4)));
}

package template from(string mod)
{
	mixin("import from = ", mod, ";");
}

package auto ref invoke(alias F, Args...)(auto ref Args args)
	if (!from!"std.traits".isCallable!F)
{
	// we enter here because F might be a lambda
	// if F is a lambda we know it is not a data member
	return F(tryForward!(F, args));
}

package auto ref invoke(alias F, Args...)(auto ref Args args)
	if (from!"std.traits".isCallable!F)
{
	static if (!Args.length)
		return F();

	else
	{
		alias front = args[0];
		alias FrontType = Args[0];
		alias params = args[1..$];

		static if (is(__traits(parent, F) == FrontType))
		{
			return __traits(child, front, F)(tryForward!(F, params));
		}
		else
		{
			static immutable Tinit = FrontType.init;
			return F(front, tryForward!(F, Tinit, params)[1..$]);
		}
	}
}
