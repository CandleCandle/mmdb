use "collections"
use "ponytest"
use "format"

primitive _DataDump
	fun val apply(arr: Array[U8] val): String val =>
		recover val
			try
				var result: String ref = String.create(10)
				result.append("[")
				let iter = arr.values()
				while iter.has_next() do
					result.append(Format.int[U8](iter.next()? where fmt=FormatBinary))
					if iter.has_next() then result.append("; ") end
				end
				result.append("]")
				consume result
			else
				"err"
			end
		end

actor Main is TestList
	new create(env: Env) => PonyTest(env, this)
	new make() => None
	fun tag tests(test: PonyTest) =>
		test(_UnsignedTests[U16]("parse/field/u16/0-byte", 0, 1, [0b10100000; 0x99]))
		test(_UnsignedTests[U16]("parse/field/u16/1-byte", 42, 2, [0b10100001; 0x2A]))
		test(_UnsignedTests[U16]("parse/field/u16/2-byte", 16962, 3, [0b10100010; 0x42; 0x42]))
		test(_UnsignedTests[U32]("parse/field/u32/0-byte", 0, 1, [0b11000000; 0x99]))
		test(_UnsignedTests[U32]("parse/field/u32/1-byte", 66, 2, [0b11000001; 0x42]))
		test(_UnsignedTests[U32]("parse/field/u32/2-byte", 36878, 3, [0b11000010; 0x90; 0x0E]))
		test(_UnsignedTests[U32]("parse/field/u32/3-byte", 8522552, 4, [0b11000011; 0x82; 0x0b; 0x38]))
		test(_UnsignedTests[U32]("parse/field/u32/4-byte", 1563489448, 5, [0b11000100; 0x5d; 0x30; 0xf4; 0xa8]))
		test(_UnsignedTests[U64]("parse/field/u64/1-byte", 55, 3, [0b00000001; 0b00000010; 0x37]))
		test(_UnsignedTests[U128]("parse/field/u128/1-byte", 56, 3, [0b00000001; 0b00000011; 0x38]))

		test(_UTF8StringTests("parse/field/string/0-byte", "", [0b01000000]))
		test(_UTF8StringTests("parse/field/string/1-byte", "a", [0b01000001; 0x61]))
		test(_UTF8StringTests("parse/field/string/9-byte", "012345678", [0b01001001; 0x30; 0x31; 0x32; 0x33; 0x34; 0x35; 0x36; 0x37; 0x38]))
		test(_MetadataBytes("parse/metadata/metadata/1-byte", 1, [0b01000001]))
		test(_MetadataBytes("parse/metadata/metadata/2-byte", 2, [0b00000000; 0b00000011]))
		test(_LengthBytes("parse/metadata/length/0-byte", 0, [0b01000000]))
		test(_LengthBytes("parse/metadata/length/1-byte", 0, [0b01011000]))
		test(_LengthBytes("parse/metadata/length/2-byte", 1, [0b01011101; 0b00000011]))
		test(_LengthBytes("parse/metadata/length/3-byte", 2, [0b01011110; 0b00000011; 0b00000011]))
		test(_LengthBytes("parse/metadata/length/4-byte", 3, [0b01011111; 0b00000011; 0b00000011; 0b00000011]))
		test(_DataLength("parse/metadata/data length/0-byte", 0, [0b01000000]))
		test(_DataLength("parse/metadata/data length/1-byte", 24, [0b01011000]))
		test(_DataLength("parse/metadata/data length/2-byte", 32, [0b01011101; 0b00000011]))
		test(_DataLength("parse/metadata/data length/3-byte", 1056, [0b01011110; 0b00000011; 0b00000011]))
		test(_DataLength("parse/metadata/data length/4-byte", 263200, [0b01011111; 0b00000011; 0b00000011; 0b00000011]))
		test(_UTF8StringTests("parse/field/string/42-byte", "0123456789abcdefghijABCDEFGHIJklmnopqrstKL", [0b01011101; 0b00001101; 0x30; 0x31; 0x32; 0x33; 0x34; 0x35; 0x36; 0x37; 0x38; 0x39; 0x61; 0x62; 0x63; 0x64; 0x65; 0x66; 0x67; 0x68; 0x69; 0x6a; 0x41; 0x42; 0x43; 0x44; 0x45; 0x46; 0x47; 0x48; 0x49; 0x4a; 0x6b; 0x6c; 0x6d; 0x6e; 0x6f; 0x70; 0x71; 0x72; 0x73; 0x74; 0x4b; 0x4c]))
		test(_MapZeroTest)
		test(_MapOneTest)
		test(_MapTwoTest)
		test(_MapTwoMixedContentTest)
		test(_DataType("parse/metadata/type/string", 2, [0b01000000]))
		test(_DataType("parse/metadata/type/u16", 5, [0b10100000]))
		test(_DataType("parse/metadata/type/u32", 6, [0b11000000]))
		test(_DataType("parse/metadata/type/i32", 8, [0b0; 0b1]))
		test(_DataType("parse/metadata/type/u64", 9, [0b0; 0b10]))
		test(_DataType("parse/metadata/type/u128", 10, [0b0; 0b11]))
		test(_MapWithinMapTest)
		test(_ArrayWithMultipleElements)
		test(_ReadInitialNode8)
		test(_ReadSecondNode8)
		test(_ReadInitialNode16)
		test(_ReadViaPointer)
		test(_RFindFound)
		test(_RFindNotFound)

class iso _UnsignedTests[T: (_Shiftable[T] & Integer[T] & Unsigned val)] is UnitTest
	let _name: String val
	let _input: Array[U8] val
	let _result: T
	let _length: USize
	new iso create(name': String, result': T, length': USize, input': Array[U8] val) =>
		_name = name'
		_input = input'
		_result = result'
		_length = length'
	fun name(): String => _name
	fun apply(h: TestHelper) =>
		let undertest = Parser(_input)
		h.assert_eq[USize](undertest.read_unsigned[USize](0)._1, _length)
		h.assert_eq[T](undertest.read_unsigned[T](0)._2, _result)

class iso _UTF8StringTests is UnitTest
	let _name: String val
	let _input: Array[U8] val
	let _result: String
	new iso create(name': String, result': String, input': Array[U8] val) =>
		_name = name'
		_input = input'
		_result = result'
//		@printf[None]("total input length: %d\n".cstring(), _input.size())
	fun name(): String => _name
	fun apply(h: TestHelper) =>
		let undertest = Parser(_input)
		h.assert_eq[String](undertest.read_string(0)._2, _result)

class iso _MetadataBytes is UnitTest
	let _name: String val
	let _input: Array[U8] val
	let _result: USize
	new iso create(name': String, result': USize, input': Array[U8] val) =>
		_name = name'
		_input = input'
		_result = result'
	fun name(): String => _name
	fun apply(h: TestHelper) =>
		let undertest = Parser(_input)
		h.assert_eq[USize](undertest._metadata_bytes(0), _result)

class iso _LengthBytes is UnitTest
	let _name: String val
	let _input: Array[U8] val
	let _result: USize
	new iso create(name': String, result': USize, input': Array[U8] val) =>
		_name = name'
		_input = input'
		_result = result'
	fun name(): String => _name
	fun apply(h: TestHelper) =>
		let undertest = Parser(_input)
		h.assert_eq[USize](undertest._length_bytes(0), _result)

class iso _DataLength is UnitTest
	let _name: String val
	let _input: Array[U8] val
	let _result: USize
	new iso create(name': String, result': USize, input': Array[U8] val) =>
		_name = name'
		_input = input'
		_result = result'
	fun name(): String => _name
	fun apply(h: TestHelper) =>
		let undertest = Parser(_input)
		h.assert_eq[USize](undertest._length(0), _result)

class iso _DataType is UnitTest
	let _name: String val
	let _input: Array[U8] val
	let _result: U16
	new iso create(name': String, result': U16, input': Array[U8] val) =>
		_name = name'
		_input = input'
		_result = result'
	fun name(): String => _name
	fun apply(h: TestHelper) =>
		let undertest = Parser(_input)
		h.assert_eq[U16](undertest._get_type(0), _result)

class iso _MapZeroTest is UnitTest
	fun name(): String => "parse/field/map/0-element"
	fun apply(h: TestHelper) =>
		let arr: Array[U8] val = [0b11100000]
		@printf[None]("length: %d %s\n".cstring(), arr.size(), _DataDump(arr).cstring())
		let undertest = Parser([0b11100000])
		h.assert_eq[USize](undertest.read_map(0, 0)._2.data.size(), 0)

class iso _MapOneTest is UnitTest
	fun name(): String => "parse/field/map/1-element"
	fun apply(h: TestHelper) =>
		let arr: Array[U8] val = [0b11100001; 0b01000001; 0x61; 0b01000001; 0x62]
		@printf[None]("length: %d %s\n".cstring(), arr.size(), _DataDump(arr).cstring())
		let undertest = Parser(arr)
		let result: Map[String val, Field val] val = undertest.read_map(0, 0)._2.data
		h.assert_eq[USize](result.size(), 1)
		try
			let value: String = match result.apply("a")?
				| let s: String => s
				else "error" end
			h.assert_eq[String](value, "b")
		else
			h.fail("no key 'a'")
		end

class iso _MapTwoTest is UnitTest
	fun name(): String => "parse/field/map/2-element"
	fun apply(h: TestHelper) =>
		let arr: Array[U8] val = [0b11100010; 0b01000001; 0x61; 0b01000001; 0x62; 0b01000001; 0x62; 0b01000001; 0x63]
		@printf[None]("length: %d %s\n".cstring(), arr.size(), _DataDump(arr).cstring())
		let undertest = Parser(arr)
		let result: Map[String val, Field val] val = undertest.read_map(0, 0)._2.data
		h.assert_eq[USize](result.size(), 2)
		try
			let value: String = match result.apply("a")?
				| let s: String => s
				else "error" end
			h.assert_eq[String](value, "b")
		else
			h.fail("no key 'a'")
		end
		try
			let value: String = match result.apply("b")?
				| let s: String => s
				else "error" end
			h.assert_eq[String](value, "c")
		else
			h.fail("no key 'b'")
		end

class iso _MapTwoMixedContentTest is UnitTest
	fun name(): String => "parse/field/map/2-element/mixed-content"
	fun apply(h: TestHelper) =>
		let arr: Array[U8] val = [0b11100010; 0b01000001; 0x61; 0b01000001; 0x62; 0b01000001; 0x62; 0b10100001; 0x2A]
		@printf[None]("length: %d %s\n".cstring(), arr.size(), _DataDump(arr).cstring())
		let undertest = Parser(arr)
		let result: Map[String val, Field val] val = undertest.read_map(0, 0)._2.data
		h.assert_eq[USize](result.size(), 2)
		try
			let value: String = match result.apply("a")?
				| let s: String => s
				else "error" end
			h.assert_eq[String](value, "b")
		else
			h.fail("no key 'a'")
		end
		try
			let value: U16 = match result.apply("b")?
				| let s: U16 => s
				else 0xFFFF end
			h.assert_eq[U16](value, 42)
		else
			h.fail("no key 'b'")
		end

class iso _MapWithinMapTest is UnitTest
	fun name(): String => "parse/field/map/2-element/nested-map"
	fun apply(h: TestHelper) =>
		let arr: Array[U8] val = [0b11100010; 0b01000001; 0x61; 0b01000001; 0x62; 0b01000001; 0x62; 0b11100001; 0b01000001; 0x63; 0b10100001; 0x2A]
		@printf[None]("length: %d %s\n".cstring(), arr.size(), _DataDump(arr).cstring())
		let undertest = Parser(arr)
		(let len: USize, let result': MmdbMap) = undertest.read_map(0, 0)
		let result: Map[String val, Field val] val = result'.data
		h.assert_eq[USize](len, 12)
		h.assert_eq[USize](result.size(), 2)
		try
			let value: String = match result.apply("a")?
				| let s: String => s
				else "error" end
			h.assert_eq[String](value, "b")
		else
			h.fail("no key 'a'")
		end
		try
			let value_a: Map[String val, Field val] val = match result.apply("b")?
				| let m: MmdbMap => m.data
				else recover val Map[String, Field] end end

			h.assert_eq[USize](value_a.size(), 1)
			let value_b: U16 = match value_a.apply("c")?
				| let u: U16 => u
				else 0xFFFF end
			h.assert_eq[U16](value_b, 42)
		else
			h.fail("no key 'b'")
		end

class iso _ArrayWithMultipleElements is UnitTest
	fun name(): String => "parse/field/array/multi-element"
	fun apply(h: TestHelper) =>
		let arr: Array[U8] val = [0b00001000; 0x04; 0x42; 0x64; 0x65; 0x42; 0x65; 0x6E; 0x42; 0x65; 0x73; 0x42; 0x66; 0x72; 0x42; 0x6A; 0x61; 0x45; 0x70; 0x74; 0x2D; 0x42; 0x52; 0x42; 0x72; 0x75; 0x45; 0x7A; 0x68; 0x2D; 0x43; 0x4E]
		@printf[None]("length: %d %s\n".cstring(), arr.size(), _DataDump(arr).cstring())
		let undertest = Parser(arr)
		(let bytes_read: USize, let result': MmdbArray) = undertest.read_array(0, 0)
		let result: Array[Field] val = result'.data
		h.assert_eq[USize](bytes_read, 32)
		h.assert_eq[USize](result.size(), 8)
		let expected: Array[String] = ["de"; "en"; "es"; "fr"; "ja"; "pt-BR"; "ru"; "zh-CN"]
		for (i, s) in expected.pairs() do
			try
				match result(i)?
				| let f: String =>h.assert_eq[String](f, s)
				else
					h.fail("Could not match at index: " + i.string() + " with value: " + s)
				end
			else
				h.fail("array index failure at idx: " + i.string())
			end
		end

class iso _ReadInitialNode8 is UnitTest
	fun name(): String => "parse/node/initial/8"
	fun apply(h: TestHelper) =>
		let arr: Array[U8] val = [0x01; 0x02; 0x03; 0x04]
		let undertest = Parser(arr)
		(let first: U32, let second: U32) = undertest.read_node(0, 8)
		h.assert_eq[U32](first, 1)
		h.assert_eq[U32](second, 2)

class iso _ReadSecondNode8 is UnitTest
	fun name(): String => "parse/node/second/8"
	fun apply(h: TestHelper) =>
		let arr: Array[U8] val = [0x01; 0x02; 0x03; 0x04]
		let undertest = Parser(arr)
		(let first: U32, let second: U32) = undertest.read_node(1, 8)
		h.assert_eq[U32](first, 3)
		h.assert_eq[U32](second, 4)

class iso _ReadInitialNode16 is UnitTest
	fun name(): String => "parse/node/initial/16"
	fun apply(h: TestHelper) =>
		let arr: Array[U8] val = [0x01; 0x02; 0x03; 0x04]
		let undertest = Parser(arr)
		(let first: U32, let second: U32) = undertest.read_node(0, 16)
		h.assert_eq[U32](first, 258)
		h.assert_eq[U32](second, 772)

class iso _ReadViaPointer is UnitTest
	fun name(): String => "parse/field/pointer/string"
	fun apply(h: TestHelper) =>
		let arr: Array[U8] val = [0x20; 0x04; 0xFF; 0xFF; 0x41; 0x61]
		let undertest = Parser(arr)
		(let bytes_read: USize, let result: Field) = undertest.read_pointer(0, 0)
		h.assert_eq[USize](bytes_read, 2)
		let value: String = match result
			| let s: String => s
			else "error" end
		h.assert_eq[String](value, "a")

class iso _RFindFound is UnitTest
	fun name(): String => "parse/rfind/found"
	fun apply(h: TestHelper) ? =>
		let arr: Array[U8] val = [0x20; 0x04; 0xFF; 0xFF; 0x41; 0x61]
		let undertest = Parser(arr)
		let search: Array[U8] val = [0xFF; 0xFF]
		let result = undertest.rfind(search)?
		h.assert_eq[USize](2, result)

class iso _RFindNotFound is UnitTest
	fun name(): String => "parse/rfind/not_found"
	fun apply(h: TestHelper) =>
		let arr: Array[U8] val = [0x20; 0x04; 0xFF; 0xFF; 0x41; 0x61]
		let undertest = Parser(arr)
		let search: Array[U8] val = [0xAA; 0xAA]
//		var f: USize = 10
//		while f >= 0 do
//			@printf[None]("f: %d\n".cstring(), f)
//			f = f - 1
//		end
		h.assert_error({() ? => undertest.rfind(search)? })
