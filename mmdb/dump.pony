

interface _Paired
	fun pairs(): Iterator[(Stringable, Field)]

primitive Dump
	fun apply(out: OutStream, f: Field, indent: USize = 0) =>
		match f
		| let m: MmdbMap => dump(out, m.data, indent)
		| let a: MmdbArray => dump(out, a.data, indent)
		| let s: Stringable => out.print(s.string())
		end

	fun dump(out: OutStream, m: _Paired val, indent: USize = 0) =>
		for (k, v) in m.pairs() do
			write_indent(out, indent)
			match v
			| let mm: MmdbMap =>
				out.print(k.string() + " => map: " + mm.data.size().string() + " element" + (if mm.data.size() == 1 then "" else "s" end))
				dump(out, mm.data, indent + 1)
			| let a: MmdbArray =>
				out.print(k.string() + " => array: " + a.data.size().string() + " element" + (if a.data.size() == 1 then "" else "s" end))
				dump(out, a.data, indent + 1)
			| let s: Stringable =>
				out.print(k.string() + " => " + s.string())
			end
		end

	fun write_indent(out: OutStream, indent: USize) =>
		var n: USize = 0
		while n < indent do
			out.write(" -> ")
			n = n + 1
		end

