type t = int

let of_int x = x
let of_uint32 = Unsigned.UInt32.to_int
let to_uint32 = Unsigned.UInt32.of_int
let pp = Fmt.int
