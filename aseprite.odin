package aseprite

import "core:log"
import mf "core:math/fixed"

HeaderFlagsBits :: enum u8 {
	LayerOpacity,
	LayerGroups,
	LayerUUID,
}

HeaderFlags :: bit_set[HeaderFlagsBits;u32]

UUID :: distinct [16]u8

PixelRGBA :: distinct [4]u8
PixelGrayscale :: distinct [2]u8
PixelIdx :: distinct u8


Tile :: union {
	u32,
	u16,
	u8,
}

Pixel :: union #no_nil {
	PixelRGBA,
	PixelGrayscale,
	PixelIdx,
}

Header :: struct #packed {
	file_size:       u32,
	magic_number:    u16,
	frames:          u16,
	width:           u16,
	height:          u16,
	color_depth:     u16,
	flags:           HeaderFlags,
	_speed:          u16,
	_:               [2]u32,
	transparent_idx: u8,
	_:               [3]u8,
	color_count:     u16,
	pixel_width:     u8,
	pixel_height:    u8,
	grid_x:          i16,
	grid_y:          i16,
	grid_width:      u16,
	grid_height:     u16,
	_:               [84]u8,
}
#assert(size_of(Header) == 128)

FrameChunk :: struct #packed {
	bytes:        u32,
	magic_number: u16,
	_chunk_count: u16,
	duration:     u16,
	_:            [2]u8,
	chunk_count:  u32,
}
#assert(size_of(FrameChunk) == 16)

ChunkHeader :: struct #packed {
	size: u32,
	type: u16,
}

// data: union #no_nil {
//     OldPaletteChunk,
//     LayerChunk,
//     CelChunk,
//     CelExtraChunk,
//     ColorProfileChunk,
//     ExternalFileChunk,
//     MaskChunk,
//     TagsChunk,
//     PaletteChunk,
//     UserDataChunk,
//     SliceChunk,
//     TilesetChunk,
// },


OldPaletteChunk :: struct #packed {
	packes_count: i16,
	packes:       []struct {
		enries:      u8,
		color_count: u8,
		color:       [][3]u8,
	},
}

LayerFlagsBits :: enum u8 {
	Visible,
	Editable,
	LockMovement,
	Background,
	PreferLinkedCels,
	LayerGroupCollapsed,
	ReferenceLayer,
}

LayerFlags :: bit_set[LayerFlagsBits;u16]

LayerType :: enum u16 {
	Normal  = 0,
	Group   = 1,
	TileMap = 2,
}

LayerBlend :: enum u16 {
	Normal     = 0,
	Multiply   = 1,
	Screen     = 2,
	Overlay    = 3,
	Darken     = 4,
	Lighten    = 5,
	ColorDodge = 6,
	ColorBurn  = 7,
	HardLight  = 8,
	SoftLight  = 9,
	Difference = 10,
	Exclusion  = 11,
	Hue        = 12,
	Saturation = 13,
	Color      = 14,
	Luminosity = 15,
	Addition   = 16,
	Subtract   = 17,
	Divide     = 18,
}


LayerChunkCore :: struct #packed {
	flags:       LayerFlags,
	type:        LayerType,
	child_level: u16,
	_width:      u16,
	_height:     u16,
	blend_mode:  LayerBlend,
	opacity:     b8,
	_:           [3]b8,
	name:        string,
}


LayerChunkTileset :: struct #packed {
	using _:     LayerChunkCore,
	tileset_idx: u32,
}

LayerChunkUUID :: struct #packed {
	using _: LayerChunkCore,
	uudi:    UUID,
}

LayerChunk :: struct #packed {
	using _:     LayerChunkCore,
	tileset_idx: u32,
	uudi:        UUID,
}


CelType :: enum u16 {
	RawImageData,
	LinkedCel,
	CompressedImage,
	CompressedTilemap,
}


CelChunk :: struct #packed {
	layer_idx:     u16,
	using pos:     [2]i16,
	opacity_level: u8,
	type:          CelType,
	z_idx:         i16,
	_:             [5]u8,
	data:          union #no_nil {
		CelImage,
		CelLinked,
		CelType,
	},
}

CelImage :: struct #packed {
	width:  u16,
	height: u16,
	// if type == compressed: zlib compressed
	pixels: []Pixel,
}

CelLinked :: struct #packed {
	frame_pos: u16,
}

CelCompressedTilemap :: struct #packed {
	width:                u16,
	height:               u16,
	bits_per_tile:        u16,
	bitmask_id:           u32,
	bitmask_x_flip:       u32,
	bitmask_y_flip:       u32,
	bitmask_digonal_flip: u32,
	_:                    [10]b8,
	tiles:                []Tile,
}

CelExtraChunkFlagBit :: enum u8 {
	PreciseBounds,
}

CelExtraChunkFlag :: bit_set[CelExtraChunkFlagBit;u32]

CelExtraChunk :: struct #packed {
	flag:      CelExtraChunkFlag,
	using pos: [2]mf.Fixed16_16,
	width:     mf.Fixed16_16,
	height:    mf.Fixed16_16,
	_:         [16]u8,
}

ColorProfileChunkType :: enum u16 {
	NoProfile,
	SRGB,
	ICC,
}

ColorProfileChunkFlagBits :: enum u8 {
	FIXED_GAMMA,
}

ColorProfileChunkFlags :: bit_set[ColorProfileChunkFlagBits;u16]

ColorProfileChunkCore :: struct #packed {
	type:  ColorProfileChunkType,
	flag:  ColorProfileChunkFlags,
	gamma: mf.Fixed16_16,
	_:     [8]u8,
}

ColorProfileChunk :: struct #packed {
	using core: ColorProfileChunkCore,
	icc_len:    u32,
	icc_data:   []b8,
}

ExternalFileChunkEntry :: struct #packed {
	type: enum {
		ExternalPalette,
		ExternalTileset,
		ExtensionNameProp,
		ExtensionNameTileMangement,
	},
	_:    [7]b8,
	name: string,
}

ExternalFileChunk :: struct #packed {
	count:  u32,
	_:      [8]b8,
	entrys: []ExternalFileChunkEntry,
}

MaskChunk :: struct #packed {
	using pos: [2]i32,
	widht:     u16,
	height:    i16,
	_:         [8]b8,
	name:      string,
	data:      []b8,
}

TagDirection :: enum u8 {
	Forward,
	Reverse,
	PingPong,
	PingPong_Reverse,
}

TagChunkData :: struct #packed {
	from_frame:   u16,
	to_frame:     u16,
	direction:    TagDirection,
	repeat_count: u16,
	_:            [6]u8,
	color:        [3]u8,
	_:            u8,
	name_length:  AsepriteStringLength,
}

AsepriteStringLength :: u16
// data:   []u8,

TagsChunk :: struct #packed {
	tag_count: u16,
	future:    [8]u8,
}

PaletteFlagBits :: enum {
	HasName,
}

PaletteFlags :: bit_set[PaletteFlagBits;u16]

PaletteEntry :: struct #packed {
	flags: PaletteFlags,
	rgba:  [3]u8,
	name:  string,
}

PaletteChunk :: struct #packed {
	size:            u32,
	first_color_idx: u32,
	last_color_idx:  u32,
	_:               [8]u8,
	palette_entries: []PaletteEntry,
}

UserDataChunk :: struct {}
SliceChunk :: struct {}
TilesetChunk :: struct {}


Cel :: [dynamic]u8
// LayerInfo :: struct {}
Frame :: struct {
	layers:   [dynamic]Cel,
	duration: u16,
}

Tag :: struct {
	to:   u32,
	from: u32,
	name: string,
}

File :: struct {
	width:       u32,
	height:      u32,
	grid_widht:  u32,
	grid_height: u32,
	// layer_info:  LayerInfo,
	tags:        []Tag,
	frames:      []Frame,
	_format:     ColorProfileChunkType,
}

// as_img_atlas(data) -> Atlas
// Atlas {
// widht, height, img, format, grid_size
// }

// as_animation -> Animation


parse_as_img :: proc(data: []u8, allocator := context.allocator) -> (file: ^File, ok: bool) {
	file = new(File)
	header := (^Header)(&data[0])
	ensure(header.magic_number == 0xA5E0)

	read_pos: u32 = 128
	file.frames = make([]Frame, header.frames)

	for i in 0 ..< header.frames {
		frame_chunk := (^FrameChunk)(&data[read_pos])
		ensure(frame_chunk.magic_number == 0xF1FA)
		frame := &file.frames[i]
		frame.duration = frame_chunk.duration
		frame.layers = make([dynamic]Cel)

		chunk_count := frame_chunk.chunk_count
		if chunk_count == 0 {
			if frame_chunk._chunk_count == 0xFFFF do panic("old aseprite file is to big")
			chunk_count = u32(frame_chunk._chunk_count)
		}

		frame_pos: u32 = read_pos + size_of(FrameChunk)
		for chunk_id in 0 ..< chunk_count {
			chunk_header := (^ChunkHeader)(&data[frame_pos])

			log.debugf("%04X", chunk_header.type)

			chunk := data[frame_pos + 6:][:chunk_header.size - 6]

			switch chunk_header.type {
			case 0x2018:
				tags_chunk_header := (^TagsChunk)(&chunk[0])
				// log.debug(tags_chunk_header.tag_count)
				tags := chunk[size_of(TagsChunk):]
				tag_offset := 0
				for tag_id in 0 ..< tags_chunk_header.tag_count {
					tag := (^TagChunkData)(&tags[tag_offset:][0])
					tag_offset += size_of(TagChunkData)
					tag_name := tags[tag_offset:][:tag.name_length]
					log.debug(string(tag_name))
					// zzz
					tag_offset += int(tag.name_length) // + 1
				}
			case 0x2007:
				t := (^ColorProfileChunkCore)(&chunk[0])
				if t.type == .ICC {
					// chunk = (^ColorProfileChunk^)(&chunk[0])
				}
			case 0x0004:
				t := (^OldPaletteChunk)(&chunk[0])
			case 0x2004:
				t := (^LayerChunkCore)(&chunk[0])
				n, err := append(&frame.layers, Cel{})
				if t.flags == {.Editable, .LockMovement} {
					t = (^LayerChunk)(&chunk[0])
				} else if .Editable in t.flags {
					t = (^LayerChunkTileset)(&chunk[0])
				} else if .LockMovement in t.flags {
					t = (^LayerChunkUUID)(&chunk[0])
				}
			case 0x2005:
				t := (^CelChunk)(&chunk[0])

			}
			// data: union #no_nil {
			//     OldPaletteChunk,
			//     LayerChunk,
			//     CelChunk,
			//     CelExtraChunk,
			//     ExternalFileChunk,
			//     MaskChunk,
			//     TagsChunk,
			//     PaletteChunk,
			//     UserDataChunk,
			//     SliceChunk,
			//     TilesetChunk,
			// },

			frame_pos += chunk_header.size
		}

		read_pos += frame_chunk.bytes

	}
	return file, true
}

Chunk :: union {
	^ColorProfileChunk,
	^ColorProfileChunkCore,
	^OldPaletteChunk,
	^LayerChunkCore,
	^LayerChunkTileset,
	^LayerChunkUUID,
	^LayerChunk,
	^CelChunk,
}

// load_chunk :: proc(chunk_header: ^ChunkHeader, data: []u8) -> Chunk {
// 	chunk: Chunk
// }
