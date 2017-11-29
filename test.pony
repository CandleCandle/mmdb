use "ponytest"

actor Main is TestList
	new create(env: Env) => PonyTest(env, this)
	new make() => None
	fun tag tests(test: PonyTest) =>
		test(_U16Tests("parse/field/u16/0-byte", 0, [0b10100000; 0x99]))
		test(_U16Tests("parse/field/u16/1-byte", 42, [0b10100001; 0x2A]))
		test(_U16Tests("parse/field/u16/2-byte", 16962, [0b10100010; 0x42; 0x42]))
		test(_U32Tests("parse/field/u32/0-byte", 0, [0b11000000; 0x99]))
		test(_U32Tests("parse/field/u32/1-byte", 66, [0b11000001; 0x42]))
		test(_U32Tests("parse/field/u32/2-byte", 36878, [0b11000010; 0x90; 0x0E]))
		test(_U32Tests("parse/field/u32/3-byte", 8522552, [0b11000011; 0x82; 0x0b; 0x38]))
		test(_U32Tests("parse/field/u32/4-byte", 1563489448, [0b11000100; 0x5d; 0x30; 0xf4; 0xa8]))
//		test(_TwoByteU32)
//		test(_ThreeByteU32)
//		test(_FourByteU32)

class iso _U16Tests is UnitTest
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
		h.assert_eq[U16](undertest.read[U16](0), _result)

class iso _U32Tests is UnitTest
	let _name: String val
	let _input: Array[U8] val
	let _result: U32
	new iso create(name': String, result': U32, input': Array[U8] val) =>
		_name = name'
		_input = input'
		_result = result'
	fun name(): String => _name
	fun apply(h: TestHelper) =>
		let undertest = Parser(_input)
		h.assert_eq[U32](undertest.read_u32(0), _result)

