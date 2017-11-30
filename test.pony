use "ponytest"

actor Main is TestList
	new create(env: Env) => PonyTest(env, this)
	new make() => None
	fun tag tests(test: PonyTest) =>
		test(_UnsignedTests[U16]("parse/field/u16/0-byte", 0, [0b10100000; 0x99]))
		test(_UnsignedTests[U16]("parse/field/u16/1-byte", 42, [0b10100001; 0x2A]))
		test(_UnsignedTests[U16]("parse/field/u16/2-byte", 16962, [0b10100010; 0x42; 0x42]))
		test(_UnsignedTests[U32]("parse/field/u32/0-byte", 0, [0b11000000; 0x99]))
		test(_UnsignedTests[U32]("parse/field/u32/1-byte", 66, [0b11000001; 0x42]))
		test(_UnsignedTests[U32]("parse/field/u32/2-byte", 36878, [0b11000010; 0x90; 0x0E]))
		test(_UnsignedTests[U32]("parse/field/u32/3-byte", 8522552, [0b11000011; 0x82; 0x0b; 0x38]))
		test(_UnsignedTests[U32]("parse/field/u32/4-byte", 1563489448, [0b11000100; 0x5d; 0x30; 0xf4; 0xa8]))
		test(_UnsignedTests[U64]("parse/field/u64/1-byte", 55, [0b00000001; 0b00000010; 0x37]))
		test(_UnsignedTests[U128]("parse/field/u128/1-byte", 56, [0b00000001; 0b00000011; 0x38]))

		test(_UTF8StringTests("parse/field/string/0-byte", "", [0b01000000]))
		test(_UTF8StringTests("parse/field/string/1-byte", "a", [0b01000001; 0x61]))
		test(_UTF8StringTests("parse/field/string/9-byte", "012345678", [0b01001001; 0x30; 0x31; 0x32; 0x33; 0x34; 0x35; 0x36; 0x37; 0x38]))
		test(_MetadataBytes("parse/metadata/metadata/1-byte", 1, [0b01000001]))
		test(_UTF8StringTests("parse/field/string/42-byte", "0123456789abcdefghijABCDEFGHIJklmnopqrstKL", [0b01011101; 0b00001101; 0x30; 0x31; 0x32; 0x33; 0x34; 0x35; 0x36; 0x37; 0x38; 0x39; 0x61; 0x62; 0x63; 0x64; 0x65; 0x66; 0x67; 0x68; 0x69; 0x6a; 0x41; 0x42; 0x43; 0x44; 0x45; 0x46; 0x47; 0x48; 0x49; 0x4a; 0x6b; 0x6c; 0x6d; 0x6e; 0x6f; 0x70; 0x71; 0x72; 0x73; 0x74; 0x4b]))

class iso _UnsignedTests[T: (_Shiftable[T] & Integer[T] & Unsigned val)] is UnitTest
	let _name: String val
	let _input: Array[U8] val
	let _result: T
	new iso create(name': String, result': T, input': Array[U8] val) =>
		_name = name'
		_input = input'
		_result = result'
	fun name(): String => _name
	fun apply(h: TestHelper) =>
		let undertest = Parser(_input)
		h.assert_eq[T](undertest.read_unsigned[T](0), _result)

class iso _UTF8StringTests is UnitTest
	let _name: String val
	let _input: Array[U8] val
	let _result: String
	new iso create(name': String, result': String, input': Array[U8] val) =>
		_name = name'
		_input = input'
		_result = result'
	fun name(): String => _name
	fun apply(h: TestHelper) =>
		let undertest = Parser(_input)
		h.assert_eq[String](undertest.read_string(0), _result)

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


