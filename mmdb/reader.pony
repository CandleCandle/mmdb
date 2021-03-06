use "logger"


class val Reader
	let parser: Parser val
	let node_count: U32
	let record_size: U16
	let data_section_offset: USize
	let metadata_start_offset: USize

	let _log: (None | Logger[String])

	new create(parser': Parser, logger': (None | Logger[String]) = None)? =>
		// partial when the database does not have the required metadata.
		_log = logger'
		parser = parser'
		let marker: Array[U8] val = [0xAB; 0xCD; 0xEF; 0x4D; 0x61; 0x78; 0x4D; 0x69; 0x6E; 0x64; 0x2E; 0x63; 0x6F; 0x6D]
		metadata_start_offset = parser.rfind(marker)? + marker.size()
		match _log
			| let l: Logger[String] => l(Fine) and l.log("Found metadata start at " + metadata_start_offset.string())
		end
		let metadata: MmdbMap = parser.read_map(metadata_start_offset, 0)._2
		node_count = match metadata.data("node_count")?
			| let u: U32 => u
			else 0 end
		record_size = match metadata.data("record_size")?
			| let u: U16  => u
			else 0 end
		data_section_offset = 16 + ((node_count.usize() * record_size.usize() * 2)/8)

	fun resolve(addr: U128): Field =>
		var current_node: U32 = 0
		var bit_counter: U8 = 0
		while bit_counter < 128 do
			let mask: U128 = 1 << (127 - bit_counter.u128())
			let bit: Bool = (addr and mask) > 0 // true = bit is 1; false = bit is 0
			var node: (U32, U32) = parser.read_node(current_node, record_size)
			var next_node = if bit then node._2 else node._1 end
			match _log
				| let l: Logger[String] => l(Fine) and l.log("found node at "
						+ current_node.string()
						+ ": (" + node._1.string() + ", " + node._2.string() + "), "
						+ "applying " + bit.string()
						+ ", so using " + next_node.string())
			end
			if next_node < node_count then
				// pointer to the next node
				current_node = next_node
				bit_counter = bit_counter + 1
			elseif next_node > node_count then
				// data point: search_tree_in_bytes + 16 + (next_node - node_count)
				let offset: USize =
						(next_node - node_count).usize()
						+ ((node_count * record_size.u32() * 2)/8).usize()
//						+ 16
				return parser.read_field(offset, data_section_offset)._2
			else // next_node == node_count
				// no data
				return U16.from[U8](0)
			end
		end
		U16.from[U8](0)


