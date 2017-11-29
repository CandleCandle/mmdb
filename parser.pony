
type DbType is ( U16 | U32 )

class val Parser
	let data: Array[U8] val

	new create(data': Array[U8] val) =>
		data = data'

	fun read_u16(offset: USize): U16 =>
		try
			let initial: U8 = data(offset)?
			var result: U16 = 0
			let length: USize = (initial and 0b00011111).usize()
			if length == 0 then
				return 0
			end
			var count: USize = 0
			while count < length do
				// -1: length-to-index
				let shift: U16 = 8*(length.u16() - 1 - count.u16())
				// +1: 1 metadata byte
				let data_byte: U8 = data(offset + 1 + count)?
				result = result or (U16.from[U8](data_byte) << shift)
				count = count + 1
			end
			result
		else
			0 // Some more useful error handling is required.
		end

	fun read_u32(offset: USize): U32 =>
		try
			var result: U32 = 0
			let length: USize = (data(offset)? and 0b00011111).usize()
			if length == 0 then
				return 0
			end
			var count: USize = 0
			while count < length do
				let shift: U32 = 8*(length.u32() - 1 - count.u32())
				let data_byte: U8 = data(offset + 1 + count)?
				result = result or (U32.from[U8](data_byte) << shift)
				count = count + 1
			end
			result
		else
			0
		end
