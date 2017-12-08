use "collections"

type SimpleField is ( U16 | U32 | U64 | U128 | I32 | String | F32 | F64 )
type Field is ( SimpleField | MmdbMap )
// pointer, array, byte array, data cache container, boolean

interface _Shiftable[T]
	fun shl(y: T): T
	fun shr(y: T): T

class val MmdbMap
	let data: Map[String val, Field val] val
	new val create(data': Map[String val, Field val] val) =>
		data = data'

class val Parser
	let data: Array[U8] val

	new create(data': Array[U8] val) =>
		data = data'

	fun read_unsigned[T: (_Shiftable[T] & Integer[T] & Unsigned val)](offset: USize): (USize, T) =>
		try
			let initial: U8 = data(offset)?
			var result: T = T.from[U8](0)
			let length: USize = _length(offset)
			let metadata_bytes = _metadata_bytes(offset)
			if length == 0 then
				return (1, T.from[U8](0))
			end
			var count: USize = 0
			while count < length do
				// -1: length-to-index
				let shift: T = T.from[USize](8*(length - 1 - count))
				let data_byte: U8 = data(offset + metadata_bytes + count)?
				result = result or (T.from[U8](data_byte).shl(shift))
				count = count + 1
			end
			@printf[None]("Uxx result: %d using %d bytes\n".cstring(), result, metadata_bytes + length)
			(metadata_bytes + length, result)
		else
			(0, T.from[U8](0))
		end

	fun read_string(offset: USize): (USize, String val) =>
		try
			let initial: U8 = data(offset)?
			let length: USize = _length(offset)
			let metadata_bytes = _metadata_bytes(offset)
			let length_bytes = _length_bytes(offset)
			let start = offset + metadata_bytes + length_bytes
			let finish = start + length
			@printf[None]("String at: offset %d; metadata %d, length_bytes %d, length: %d, start %d, finish %d\n".cstring(), offset, metadata_bytes, length_bytes, length, start, finish)
			(finish - offset, String.from_array(recover val data.slice(start, finish) end))
		else
			(0, "")
		end

	fun read_map(offset: USize): (USize, MmdbMap) =>
//		try
			let total_pairs = _length(offset)
//			@printf[None]("expecting: %d entr{y,ies}\n".cstring(), total_pairs)
			var running_offset = offset + _metadata_bytes(offset) + _length_bytes(offset)
			let result: Map[String val, Field val] val = recover val
				var result = Map[String, Field]
				var counter: USize = 0
				@printf[None]("new offset: %d\n".cstring(), running_offset)
				while counter < total_pairs do
					@printf[None]("map key: offset: %d\n".cstring(), running_offset)
					(let key_change: USize, let key: String) = read_string(running_offset)
					@printf[None]("k: %s\n".cstring(), key.cstring())
					running_offset = running_offset + key_change
					@printf[None]("map value: offset: %d, last change: %d\n".cstring(), running_offset, key_change)
					(let value_change: USize, let value: Field) = read_field(running_offset)
					running_offset = running_offset + value_change
					@printf[None]("map value end: offset: %d, last change: %d\n".cstring(), running_offset, value_change)

					match value
					| let s: String => @printf[None]("v: %s\n".cstring(), s.cstring())
					| let u: Unsigned => @printf[None]("v: %s\n".cstring(), u.string().cstring())
					| let m: MmdbMap => @printf[None]("v: map with %d key(s)\n".cstring(), m.data.size())
					else
						@printf[None]("v: other\n".cstring())
					end
//					match value
//					| let s: String => @printf[None]("new key: %s, new value: %s, new offset: %d\n".cstring(), key.cstring(), s.cstring(), running_offset)
//					| let u: Unsigned => @printf[None]("new key: %s, new value: %d, new offset: %d\n".cstring(), key.cstring(), u, running_offset)
//					end

					result(key) = value
					counter = counter + 1
				end
				consume result
			end
			(0, MmdbMap(result))
//			(running_offset - offset, MmdbMap(result))
//		else
//			recover val Map[String, Field] end
//		end
	fun read_field(offset: USize): (USize, Field) =>
		match _get_type(offset)
		// | 0 marker for data type extension
		// | 1 => pointer
		| 2 => read_string(offset)
		// | 3 => F64
		// | 4 => byte array
		| 5 => read_unsigned[U16](offset)
		| 6 => read_unsigned[U32](offset)
		| 7 =>
//			read_map(offset)
			let res: (USize, Field) = read_map(offset)
//			@printf[None]("map read using %d bytes\n".cstring(), res._1)
			res
		// | 8 => I32
		| 9 => read_unsigned[U64](offset)
		| 10 => read_unsigned[U128](offset)
		// | 11 => array
		// | 12 => data cache container
		// | 13 => end marker
		else
			(0, U16.from[U8](0))
		end

	fun _get_type(offset: USize): U16 =>
		try
			let t: U8 = (data(offset)? and 0b11100000) >> 5
			match t
			| 0 =>
				7 + data(offset + 1)?.u16()
			else
				t.u16()
			end
		else
			0
		end

	fun _length(offset: USize): USize =>
		try
			let initial: U8 = data(offset)?
			var length = (initial and 0b00011111).usize()
			let metadata_bytes = _metadata_bytes(offset)
			// magic extension bytes.
			match length
			| 29 => 29
					+ data(offset + metadata_bytes)?.usize()
			| 30 => 285
					+ (    data(offset + metadata_bytes + 1)?.usize()
						or data(offset + metadata_bytes    )?.usize().shl(8)
					)
			| 31 => 65821
					+ (    data(offset + metadata_bytes + 2)?.usize()
						or data(offset + metadata_bytes + 1)?.usize().shl(8)
						or data(offset + metadata_bytes    )?.usize().shl(16)
					)
			else
				length
			end
		else
			0
		end

	fun _length_bytes(offset: USize): USize =>
		try
			let initial: U8 = data(offset)?
			match (initial and 0b00011111)
			| 29 => 1
			| 30 => 2
			| 31 => 3
			else
				0
			end
		else
			0
		end

	fun _metadata_bytes(offset: USize): USize =>
		try
			let initial: U8 = data(offset)?
			let t: U8 = initial and 0b11100000
			if t == 0 then
				2
			else
				1
			end
		else
			1
		end

