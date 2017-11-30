

interface _Shiftable[T]
	fun shl(y: T): T
	fun shr(y: T): T

class val Parser
	let data: Array[U8] val

	new create(data': Array[U8] val) =>
		data = data'

	fun read[T: (_Shiftable[T] & Integer[T] & Unsigned val)](offset: USize): T =>
		try
			let initial: U8 = data(offset)?
			var result: T = T.from[U8](0)
			let length: USize = (initial and 0b00011111).usize()
			if length == 0 then
				return T.from[U8](0)
			end
			var count: USize = 0
			while count < length do
				// -1: length-to-index
				let shift: T = T.from[USize](8*(length - 1 - count))
				let data_byte: U8 = data(offset + 1 + count)?
				result = result or (T.from[U8](data_byte).shl(shift))
				count = count + 1
			end
			result
		else
			T.from[U8](0)
		end

