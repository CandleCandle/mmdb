use "collections"
use "logger"

type SimpleField is ( U16 | U32 | U64 | U128 | I32 | String | F32 | F64 )
type Field is ( SimpleField | MmdbMap | MmdbArray ) // missing: byte array, data cache container, boolean

interface Shiftable[T]
	fun shl(y: T): T
	fun shr(y: T): T

class val MmdbMap
	let data: Map[String val, Field val] val
	new val create(data': Map[String val, Field val] val) =>
		data = data'

class val MmdbArray
	let data: Array[Field val] val
	new val create(data': Array[Field val] val) =>
		data = data'

primitive _Masks
	"""
	rather than calculating bit-masks on-the-fly for every request,
	pre-calculate them and store them as constants.
	"""
	fun negative_extension(bytes: U8): U32 =>
		"""
		when there are `bytes` bytes in the stored number, then the constant
		is bit-wise OR'd with the stored number to extend the result to 32 bits
		"""
		match bytes
		| 1 => 0xFF_FF_FF_00
		| 2 => 0xFF_FF_00_00
		| 3 => 0xFF_00_00_00
		| 4 => 0x00_00_00_00
		else 0 end
	fun negative_bit_mask(bytes: U8): U32 =>
		"""
		when the bit-wise AND of the constant and the stored number is greater
		than zero, then the resulting number is negative.
		"""
		match bytes
		| 1 => 0x00_00_00_80
		| 2 => 0x00_00_80_00
		| 3 => 0x00_80_00_00
		| 4 => 0x80_00_00_00
		else 0 end


class val Parser
	let data: Array[U8] val

	let _log: (None | Logger[String])

	new create(data': Array[U8] val, logger': (None | Logger[String]) = None) =>
		_log = logger'
		data = data'

	fun read_unsigned[T: (Shiftable[T] & Integer[T] & Unsigned val)](offset: USize): (USize, T) =>
		match _log
			| let l: Logger[String] => l(Fine) and l.log("Reading unsigned from offset " + offset.string())
		end
		let length': USize = length(offset)
		let metadata_bytes' = metadata_bytes(offset)
		if length' == 0 then
			return (metadata_bytes', T.from[U8](0))
		end
		(metadata_bytes' + length', _read_into[T](offset + metadata_bytes', length'))
	
	fun read_float_64(offset: USize): (USize, F64) =>
		let r: (USize, U64) = read_unsigned[U64](offset)
		(r._1, F64.from_bits(r._2))

	fun read_float_32(offset: USize): (USize, F32) =>
		let r: (USize, U32) = read_unsigned[U32](offset)
		(r._1, F32.from_bits(r._2))

	fun read_signed_32(offset: USize): (USize, I32) =>
		(let length': USize, var u: U32) = read_unsigned[U32](offset)
		if u == 0 then return (length', u.i32()) end
		let initial: U8 = try data(offset)? else 0 end
		let length'' = initial and 0b00011111
		let negative_bit_mask = _Masks.negative_bit_mask(length'')

		let i = (if (u and negative_bit_mask) > 0 then
				u or _Masks.negative_extension(length'')
			else
				u
			end).i32()
		(length', i)

	fun _read_into[T: (Shiftable[T] & Integer[T] & Unsigned val)](offset: USize, length': USize): T =>
		var result: T = T.from[U8](0)
		for count in IntIter[USize](length') do
			let data_byte: U8 = try data(offset + count)? else 0 end
			result = (result << T.from[U8](8)) or T.from[U8](data_byte)
		end
		result

	fun read_pointer(offset: USize, data_offset: USize): (USize, Field) =>
		match _log
			| let l: Logger[String] => l(Fine) and l.log("Reading pointer from offset " + offset.string())
		end
	try
		let size: U8 = (data(offset)? and 0b00011000) >> 3
		let value: U32 = (data(offset)? and 0b00000111).u32()
		(let bytes_read: USize, let pointed_offset: U32) = match size
			| 0 => (2, (value << 8) or _read_into[U32](offset+1, 1))
			| 1 => (3, ((value << 16) or _read_into[U32](offset+1, 2)) + 2048)
			| 2 => (4, ((value << 24) or _read_into[U32](offset+1, 3)) + 526336)
			| 3 => (5, _read_into[U32](offset+1, 4))
			else
				(1, U32.from[U8](0))
			end

		// discard the bytes read from the read_field call.
		(bytes_read, read_field(data_offset + pointed_offset.usize(), data_offset)._2)
	else
		(1, U32.from[U8](0))
	end

	fun rfind(search: Array[U8] val): USize ? =>
		var result: USize = data.size()
		while result > 0 do
			result = result - 1
			if _is_at(result, search) then return result end
		end
		match _log
			| let l: Logger[String] => l(Error) and l.log("failed to rfind")
		end
		error

	fun _is_at(offset: USize, search: Array[U8] val): Bool =>
		var c: USize = 0
		while c < search.size() do
			try
				let d = data(offset + c)?
				let s = search(c)?
				if d != s then return false end
			else return false end
			c = c + 1
		end
		true

	fun read_node(node_id: U32, record_size: U16): (U32, U32) =>
		match _log
			| let l: Logger[String] => l(Fine) and l.log("Reading node at " + node_id.string() + " with record size of " + record_size.string())
		end
		let bytes = (record_size >> 2).usize() // divide by 4
		let start_offset: USize = (node_id.usize() * bytes.usize())

		// we should not assume that the record_size is 24/28/32.
		// if record size is not a whole number of bytes, then the middle byte
		// is split in two, and contains the four highest bits of the records.
		// e.g. 12 bits per record
		// | 7..0 | 11..8 | 11..8 | 7..0 |
		var first: U32 = 0
		var second: U32 = 0
		if (bytes and 0x1) > 0 then // bytes is odd; need to split the middle byte
			let middle = _read_into[U32](
					start_offset + ((record_size and 0xFFF8) >> 3).usize(), // reduce the U16 to the closest multiple of 8.
					1
			)
			first = ((middle and 0xF0) >> 4) << (record_size and 0xFFF8).u32()
			second = (middle and 0x0F) << (record_size and 0xFFF8).u32()
		end
		first = first or _read_into[U32](
				start_offset,
				(record_size >> 3).usize()
		)
		second = second or _read_into[U32](
				start_offset + (record_size >> 3).usize() + (bytes and 0x1),
				(record_size >> 3).usize()
		)
		(first, second)

	fun read_string(offset: USize): (USize, String val) =>
		match _log
			| let l: Logger[String] => l(Fine) and l.log("Reading string from offset " + offset.string())
		end
		try
			let initial: U8 = data(offset)?
			let length': USize = length(offset)
			let metadata_bytes' = metadata_bytes(offset)
			let length_bytes' = length_bytes(offset)
			let start = offset + metadata_bytes' + length_bytes'
			let finish = start + length'
			(finish - offset, String.from_array(recover val data.slice(start, finish) end))
		else
			(0, "")
		end

	fun read_array(offset: USize, data_section_offset: USize): (USize, MmdbArray) =>
		match _log
			| let l: Logger[String] => l(Fine) and l.log("Reading array from offset " + offset.string())
		end
		var byte_count: USize = 0
		let result: Array[Field] val = recover val
			let entry_count = length(offset)
			byte_count = byte_count + metadata_bytes(offset) + length_bytes(offset)
			var res = Array[Field](entry_count)
			for counter in IntIter[USize](where f=entry_count) do
				(let change: USize, let value: Field) = read_field(offset + byte_count, data_section_offset)
				byte_count = byte_count + change
				res.push(value)
			end
			res
		end
		(byte_count, MmdbArray(result))

	fun read_map(offset: USize, data_section_offset: USize): (USize, MmdbMap) =>
		match _log
			| let l: Logger[String] => l(Fine) and l.log("Reading map from offset " + offset.string())
		end
		var byte_count: USize = 0
		let result: Map[String val, Field val] val = recover val
			let entry_count = length(offset)
			byte_count = byte_count + metadata_bytes(offset) + length_bytes(offset)
			var res = Map[String, Field](entry_count)
			for counter in IntIter[USize](where f=entry_count) do
				(let key_change: USize, let key': Field) = read_field(offset + byte_count, data_section_offset)
				let key: String = match key'
				| let s: String => s
				else "error" end
				byte_count = byte_count + key_change
				(let value_change: USize, let value: Field) = read_field(offset + byte_count, data_section_offset)
				byte_count = byte_count + value_change

				res(key) = value
			end
			res
		end
		(byte_count, MmdbMap(result))

	fun read_field(offset: USize, data_section_offset: USize): (USize, Field) =>
		"""
		return a 2-tuple of:
		1: the total number of bytes read in reading this field
		2: the field result

		delegates to the correct `read_*` function for the type of the field.
		"""
		match get_type(offset)
		// | 0 marker for data type extension
		| 1 => read_pointer(offset, data_section_offset)
		| 2 => read_string(offset)
		| 3 => read_float_64(offset)
		// | 4 => byte array
		| 5 => read_unsigned[U16](offset)
		| 6 => read_unsigned[U32](offset)
		| 7 => read_map(offset, data_section_offset)
		| 8 => read_signed_32(offset)
		| 9 => read_unsigned[U64](offset)
		| 10 => read_unsigned[U128](offset)
		| 11 => read_array(offset, data_section_offset)
		// | 12 => data cache container
		// | 13 => end marker
		// | 14 => boolean
		| 15 => read_float_32(offset)
		else
			match _log
				| let l: Logger[String] => l(Error) and l.log("Type "+get_type(offset).string()+" is not implemented at offset "+offset.string())
			end
			(0, U16.from[U8](0))
		end

	fun get_type(offset: USize): U16 =>
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

	fun length(offset: USize): USize =>
		try
			let initial: U8 = data(offset)?
			var length' = (initial and 0b00011111).usize()
			let metadata_bytes' = metadata_bytes(offset)
			// magic length extension bytes.
			match length'
			| 29 => 29 + _read_into[USize](offset + metadata_bytes', 1)
			| 30 => 285 + _read_into[USize](offset + metadata_bytes', 2)
			| 31 => 65821 + _read_into[USize](offset + metadata_bytes', 3)
			else
				length'
			end
		else
			0
		end

	fun length_bytes(offset: USize): USize =>
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

	fun metadata_bytes(offset: USize): USize =>
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

