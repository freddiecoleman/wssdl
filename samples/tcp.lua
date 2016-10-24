-- In this sample, we'll use the DSL to describe what a TCP packet looks like
-- and use the generated dissector in place of the builtin one.
--
-- This isn't an extensive replacement for the TCP dissector, but it shows
-- that we can handle more complex definitions.
--
local wssdl = require("wssdl"):init(_ENV)

tcp_flags = wssdl.packet
{
  ns  : bit();
  cwr : bit();
  ece : bit();
  urg : bit();
  ack : bit();
  psh : bit();
  rst : bit();
  syn : bit();
  fin : bit();
}

tcp_hdr = wssdl.packet
  : padding(32)
{
  src_port    : u16();
  dst_port    : u16();
  seq_num     : u32();
  ack_num     : u32();
  data_offset : bits(4);
  reserved    : bits(3);
  flags       : tcp_flags();
  window_size : u16();
  checksum    : u16();
  urgent_ptr  : u16();

  -- The options field takes the remaining space before the payload.
  -- Since data_offset contains the offset from the start of the packet
  -- to the payload in 32-bit words (i.e. 4 bytes), and the minimum size
  -- of the header is 160 bits (i.e. 5 32-bit words), the size of the
  -- options field is (data_offset - 5) * 4 bytes.
  options     : bytes((data_offset - 5) * 4);
}

tcp = wssdl.packet
{
  header  : tcp_hdr();
  payload : payload { header.dst_port, 'tcp.port' };
}

-- Let's replace the builtin dissector for TCP!
DissectorTable.get('ip.proto')
    :set(0x06, tcp:protocol('TCP', 'Transmission Control Protocol'))