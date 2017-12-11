


class val Reader
	let parser: Parser val
	let node_count: U32
	let record_size: U16

	new create(parser': Parser)? =>
		// partial when the database does not have the required metadata.
		parser = parser'
		let marker: Array[U8] = [0xAB; 0xCD; 0xEF; 0x4D; 0x61; 0x78; 0x4D; 0x69; 0x6E; 0x64; 0x2E; 0x63; 0x6F; 0x6D]
		let metadata_start_offset: USize = 3185089// parser.rfind(marker) + marker.size()
		let metadata: MmdbMap = parser.read_map(metadata_start_offset)._2
		node_count = match metadata.data("node_count")?
			| let u: U32 => u
			else 0 end
		record_size = match metadata.data("record_size")?
			| let u: U16  => u
			else 0 end

	fun resolve(addr: (U32 | U128)): Field =>
		var current_node: U32 = 0
		var bit_counter: U8 = 0
		while bit_counter < 32 do
			let bit: Bool = true // true = bit is 0; false = bit is 1
			var node: (U32, U32) = parser.read_node(current_node, record_size)
			var next_node = if bit then node._1 else node._2 end
			if next_node < node_count then
				// pointer to the next node
				current_node = next_node
				bit_counter = bit_counter + 1
			elseif next_node > node_count then
				// data point: search_tree_in_bytes + 16 + (next_node - node_count)
				let offset: USize =
						(next_node - node_count).usize()
						+ ((node_count * record_size.u32() * 2)/8).usize()
						+ 16
				return parser.read_field(offset)._2
			else // next_node == node_count
				// no data
				return U16.from[U8](0)
			end
		end
		U16.from[U8](0)

