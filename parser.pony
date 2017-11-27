
type DbType is ( U16 | U32 )

class val Parser
	let data: Array[U8] val

	new create(data': Array[U8] val) =>
		data = data'

	fun read_u32(offset: USize): U32 => 0

	fun read_u16(offset: USize): U16 =>
		try
			let initial: U8 = data(offset)?
			let t: U8 = (initial and 0b11100000) >> 5
			var result: U16 = 0
			let length: U8 = initial and 0b00011111
			var count: USize = 0
			while count < length.usize() do
				@printf[None]("initial: %d (%X)\n".cstring(), initial, initial)
				@printf[None]("length:  %d\n".cstring(), length)
				@printf[None]("count:   %d\n".cstring(), count)
				@printf[None]("result:  %d (%X)\n".cstring(), result, result)

				let shift: U16 = 8*(length - 1 - count.u8()) // -1: length-to-index
				let data_byte: U8 = data(offset + 1 + count)? // +1: 1 metadata byte
				@printf[None]("shift:   %d\n".cstring(), shift)
				@printf[None]("data:    %d (%X)\n".cstring(), data_byte, data_byte)

				result = result or (U16.from[U8](data_byte) << shift)
				count = count + 1
			end
			result
		else
			0 // Some more useful error handling is required.
		end
