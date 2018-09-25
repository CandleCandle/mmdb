use "../mmdb"
use "ponytest"

actor IntIteratorTest is TestList
	new create(env: Env) => PonyTest(env, this)
	new make() => None
	fun tag tests(test: PonyTest) =>
		test(_IntIteratorTest)
		test(_IntIterator2Test)
		test(_IntIterator3Test)
		test(_IntIteratorEmptyTest)

class iso _IntIteratorTest is UnitTest
	fun name(): String => "iterator/int/0/1/5"
	fun apply(h: TestHelper) =>
		let undertest = IntIter[U8](5)
		var result: Array[U8] = Array[U8](5)
		for i in undertest do
			result.push(i)
		end
		let expected: Array[U8] = [0;1;2;3;4]
		h.assert_eq[USize](expected.size(), result.size())
		for (i, v) in expected.pairs() do
			try
				h.assert_eq[U8](v, result(i)?)
			else
				h.fail("failed at index " + i.string())
			end
		end

class iso _IntIterator2Test is UnitTest
	fun name(): String => "iterator/int/5/1/9"
	fun apply(h: TestHelper) =>
		let undertest = IntIter[U8](where s=5, f=10)
		var result: Array[U8] = Array[U8](5)
		for i in undertest do
			result.push(i)
		end
		let expected: Array[U8] = [5;6;7;8;9]
		h.assert_eq[USize](expected.size(), result.size())
		for (i, v) in expected.pairs() do
			try
				h.assert_eq[U8](v, result(i)?)
			else
				h.fail("failed at index " + i.string())
			end
		end

class iso _IntIterator3Test is UnitTest
	fun name(): String => "iterator/int/0/2/6"
	fun apply(h: TestHelper) =>
		let undertest = IntIter[U8](where s=0, f=8, inc=2)
		var result: Array[U8] = Array[U8](4)
		for i in undertest do
			result.push(i)
		end
		let expected: Array[U8] = [0;2;4;6]
		h.assert_eq[USize](expected.size(), result.size())
		for (i, v) in expected.pairs() do
			try
				h.assert_eq[U8](v, result(i)?)
			else
				h.fail("failed at index " + i.string())
			end
		end

class iso _IntIteratorEmptyTest is UnitTest
	fun name(): String => "iterator/int/0/0/1"
	fun apply(h: TestHelper) =>
		let undertest = IntIter[U8](where s=0, f=0, inc=1)
		var result: Array[U8] = Array[U8](0)
		for i in undertest do
			result.push(i)
		end
		let expected: Array[U8] = []
		h.assert_eq[USize](expected.size(), result.size())
		for (i, v) in expected.pairs() do
			try
				h.assert_eq[U8](v, result(i)?)
			else
				h.fail("failed at index " + i.string())
			end
		end
