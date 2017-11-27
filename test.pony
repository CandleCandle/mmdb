use "ponytest"

actor Main is TestList
	new create(env: Env) => PonyTest(env, this)
	new make() => None
	fun tag tests(test: PonyTest) =>
		test(_OneByteU16)
		test(_TwoByteU16)
		test(_OneByteU32)
//		test(_TwoByteU32)
//		test(_ThreeByteU32)
//		test(_FourByteU32)

class iso _OneByteU16 is UnitTest
	fun name(): String => "parse/field/u16/1-byte"
	fun apply(h: TestHelper) =>
		let bytes: Array[U8] val = [0b10100001; 0x2A]

		let undertest = Parser(bytes)
		h.assert_eq[U16](undertest.read[U16](0), 42)

class iso _TwoByteU16 is UnitTest
	fun name(): String => "parse/field/u16/2-byte"
	fun apply(h: TestHelper) =>
		let bytes: Array[U8] val = [0b10100010; 0x00; 0x42]

		let undertest = Parser(bytes)
		h.assert_eq[U16](undertest.read[U16](0), 66)

class iso _OneByteU32 is UnitTest
	fun name(): String => "parse/field/u32/1-byte"
	fun apply(h: TestHelper) =>
		let bytes: Array[U8] val = [0b11000001; 0x42]

		let undertest = Parser(bytes)
		let result = undertest.read[U32](0)
		h.assert_eq[U32](result, 66)

