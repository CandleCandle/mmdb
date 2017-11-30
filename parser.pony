

interface _Shiftable[T]
	fun shl(y: T): T
	fun shr(y: T): T

class val Parser
	let data: Array[U8] val

	new create(data': Array[U8] val) =>
		data = data'

	fun read_unsigned[T: (_Shiftable[T] & Integer[T] & Unsigned val)](offset: USize): T =>
		try
			let initial: U8 = data(offset)?
			var result: T = T.from[U8](0)
			let length: USize = _length_bytes(offset)
			let metadata_bytes = _metadata_bytes(offset)
			if length == 0 then
				return T.from[U8](0)
			end
			var count: USize = 0
			while count < length do
				// -1: length-to-index
				let shift: T = T.from[USize](8*(length - 1 - count))
				let data_byte: U8 = data(offset + metadata_bytes + count)?
				result = result or (T.from[U8](data_byte).shl(shift))
				count = count + 1
			end
			result
		else
			T.from[U8](0)
		end

	fun read_string(offset: USize): String val =>
		try
			let initial: U8 = data(offset)?
			let length: USize = _length_bytes(offset)
			let metadata_bytes = _metadata_bytes(offset)
			let start = offset + metadata_bytes
			let finish = start + length
			@printf[None]("offset %d; metadata %d, length: %d, start %d, finish %d\n".cstring(), offset, metadata_bytes, length, start, finish)
			String.from_array(recover val data.slice(start, finish) end)
		else
			""
		end

	fun _length_bytes(offset: USize): USize =>
		try
			let initial: U8 = data(offset)?
			// TODO, handle extensions; where the size is 29,30,31
			var length = (initial and 0b00011111).usize()
			// magic extension bytes.
			match length
			| 29 => data(offset + 1)?.usize() + 29
			| 30 => (data(offset + 1)?.usize().shl(8) or data(offset + 2)?.usize()) + 285
			| 31 => ((data(offset + 1)?.usize().shl(16) or data(offset + 1)?.usize().shl(8)) or data(offset + 2)?.usize()) + 65821
			else
				length
			end
		else
			0
		end

	fun _metadata_bytes(offset: USize): USize =>
		try
			let initial: U8 = data(offset)?
			let t: U8 = initial and 0b11100000
			let m: USize = if t == 0 then
					2
				else
					1
				end
			let s: USize = match (initial and 0b00011111)
				| 29 => 1
				| 30 => 2
				| 31 => 3
				else
					0
				end
			m + s
		else
			1
		end

