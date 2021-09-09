module vsignal.utils;

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
