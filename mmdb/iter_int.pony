

class IntIter[T: (Integer[T] & Unsigned val)] is Iterator[T]
	"""
	basic iterators for unsigned integers.

```pony
actor Main
    new create(env: Env) =>
        for c in IntIter[U8](4) do
            env.out.write(c.string() + " ")
        end
```
	will print:
```
0 1 2 3 4
```

```pony
actor Main
    new create(env: Env) =>
        for c in IntIter[U8](where s=4, f=10, inc=2) do
            env.out.write(c.string() + " ")
        end
```
	will print:
```
4 6 8 10
```
	note that the `s` and `f` are inclusive.
	"""
	var iter: T
	let finish: T
	let increment: T

	new create(f: T, s: T = T.from[U8](0), inc: T = T.from[U8](1)) =>
		"""
		provide numbers from `s` to `f` inclusive with the step of `inc`
		"""
		finish = f
		iter = s
		increment = inc

	fun has_next(): Bool =>
		iter <= finish

	fun ref next(): T =>
		let result: T = iter
		iter = iter + increment
		result
