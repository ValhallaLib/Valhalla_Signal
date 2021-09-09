module vsignal.slot;

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
