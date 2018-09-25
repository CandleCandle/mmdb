use "../mmdb"
use "ponytest"
use "logger"


actor ReaderTest is TestList
	new create(env: Env) => PonyTest(env, this)
	new make() => None
	fun tag tests(test: PonyTest) =>
		test(_ReaderOfMinimalDb)

primitive _Markers
	fun data(): Array[U8] val =>
		recover val Array[U8].init(0x00, 16) end
	fun metadata(): Array[U8] val =>
		[0xAB; 0xCD; 0xEF; 0x4D; 0x61; 0x78; 0x4D; 0x69; 0x6E; 0x64; 0x2E; 0x63; 0x6F; 0x6D]

primitive _Metadata
	fun apply(node_count: U32, record_size: U16): Array[U8] val =>
		[
			0b111_00010
			0b010_01010;'n';'o';'d';'e';'_';'c';'o';'u';'n';'t'
			0b110_00100
					((node_count >> 24) and 0xFF).u8()
					((node_count >> 16) and 0xFF).u8()
					((node_count >> 8) and 0xFF).u8()
					(node_count and 0xFF).u8()
			0b010_01011;'r';'e';'c';'o';'r';'d';'_';'s';'i';'z';'e'
			0b101_00010
					((record_size >> 8) and 0xFF).u8()
					(record_size and 0xFF).u8()
		]
//	fun pack[T: (Shiftable[T] & Integer[T] & Unsigned val)](i: T): Array[U8] val =>
//		recover val
//			var result: Array[U8]()
//		end

class _ReaderOfMinimalDb is UnitTest
	fun name(): String => "reader/0-entries"
	fun apply(h: TestHelper) =>
		let data: Array[U8] val = recover val
			let t: Array[U8] = [0x1; 0x1]
			let d: Array[U8] = []
			let m: Array[U8] val = _Metadata(1, 8)
			Array[U8](t.size() + d.size() + m.size())
				.>append(t)
				.>append(_Markers.data())
				.>append(d)
				.>append(_Markers.metadata())
				.>append(m)
		end
		let logger = StringLogger(Fine, h.env.out)
		let parser = recover val Parser(data, logger) end
		try
			let undertest = recover val Reader(parser, logger)? end
			h.assert_eq[U32](1, undertest.node_count)
			h.assert_eq[U16](8, undertest.record_size)
			h.assert_eq[USize](18, undertest.data_section_offset)
			Dump(h.env.out, parser.read_map(undertest.metadata_start_offset, undertest.data_section_offset)._2)
		else
			h.fail("error received")
		end

