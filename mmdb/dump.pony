

interface _Paired
	fun pairs(): Iterator[(Stringable, Field)]

primitive Dump
	fun apply(out: (OutStream | String ref), f: Field, indent: USize = 0) =>
		match f
		| let m: MmdbMap => dump(out, m.data, indent)
		| let a: MmdbArray => dump(out, a.data, indent)
		| let s: Stringable => _print(out, s.string())
		end

	fun dump(out: (OutStream | String ref), m: _Paired val, indent: USize = 0) =>
		for (k, v) in m.pairs() do
			write_indent(out, indent)
			match v
			| let mm: MmdbMap =>
				_print(out, k.string() + " => map: " + mm.data.size().string() + " element" + (if mm.data.size() == 1 then "" else "s" end))
				dump(out, mm.data, indent + 1)
			| let a: MmdbArray =>
				_print(out, k.string() + " => array: " + a.data.size().string() + " element" + (if a.data.size() == 1 then "" else "s" end))
				dump(out, a.data, indent + 1)
			| let s: Stringable =>
				_print(out, k.string() + " => " + s.string())
			end
		end

	fun write_indent(out: (OutStream | String ref), indent: USize) =>
		var n: USize = 0
		while n < indent do
			_write(out, " -> ")
			n = n + 1
		end
	
	fun _write(out: (OutStream | String ref), content: String) =>
		match out
		| let o: OutStream => o.write(content)
		| let s: String ref => s.append(content.array())
		end

	fun _print(out: (OutStream | String ref), content: String) =>
		match out
		| let o: OutStream => o.print(content)
		| let s: String ref => s.append(content.array()); s.append("\n".array())
		end

