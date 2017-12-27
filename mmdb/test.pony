use "ponytest"

actor Main is TestList
	new create(env: Env) => PonyTest(env, this)
	new make() => None
	fun tag tests(test: PonyTest) =>
		IntIteratorTest.make().tests(test)
		ParserTest.make().tests(test)
		ReaderTest.make().tests(test)
