module vsignal.sink;

import vsignal.signal;

struct Sink(F)
{
private:
	Signal!F* signal;
}
