module vsignal.slot;

package void connect(alias pred, F)(auto ref Slot!F slot)
{
	import vsignal.utils : tryForward;

	with(slot)
	{
		payload = null;
		fn = (const scope void*, Parameters args) {
			static if (is(ReturnType == void))
				pred(tryForward!(pred, args));
			else
				return ReturnType(pred(tryForward!(pred, args)));
		};
	}
}

package struct Slot(F)
{
	import vsignal.utils : from;

	alias SlotType = F;
	alias ReturnType = from!"std.traits".ReturnType!F;
	alias Parameters = from!"std.traits".Parameters!F;
	alias Function   = from!"std.traits".SetFunctionAttributes!(
		ReturnType delegate(const scope void*, Parameters),
		from!"std.traits".functionLinkage!SlotType,
		from!"std.traits".functionAttributes!SlotType
	);

	auto opCall(Parameters args)
	{
		return fn(payload, from!"core.lifetime".forward!args);
	}

package:
	Function fn;
	void* payload;
}
