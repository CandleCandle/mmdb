

class val Parser
	let data: Array[U8] val

	new create(data': Array[U8] val) =>
		data = data'

	fun read[T: (U16 | U32)](offset: USize): T =>
		try
			let initial: U8 = data(offset)?
			let length: U8 = initial and 0b00011111
			var result: T = 0
			var count: USize = 0
			while count < length.usize() do
				@printf[None]("initial: %d (%X)\n".cstring(), initial, initial)
				@printf[None]("length:  %d\n".cstring(), length)
				@printf[None]("count:   %d\n".cstring(), count)
				@printf[None]("result:  %d (%X)\n".cstring(), result, result)

				let shift: U8 = 8*(length - 1 - count.u8())
				let data_byte: U8 = data(offset + 1 + count)?
				@printf[None]("shift:   %d\n".cstring(), shift)
				@printf[None]("data:    %d (%X)\n".cstring(), data_byte, data_byte)

				result = result or (data_byte << shift.u8()).u16()
				count = count + 1
			end
			result
		else
			0 // Some more useful error handling is required.
		end
