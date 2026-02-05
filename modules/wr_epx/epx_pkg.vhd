-------------------------------------------------------------------------------
-- SPDX-FileCopyrightText: 2026 CERN (home.cern)
--
-- SPDX-License-Identifier: CERN-OHL-W-2.0+
-------------------------------------------------------------------------------
--  10G endpoint definitions
-------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

package epx_pkg is
  subtype t_blk66 is std_logic_vector(0 to 65);
  subtype t_slv64 is std_logic_vector(63 downto 0);
  subtype t_slv32 is std_logic_vector(31 downto 0);
  subtype t_slv8 is std_logic_vector(7 downto 0);

  --  Revert bits of a byte
  function rev8(d : t_slv8) return t_slv8;
    
  --  IDLE 0x1e = 0b0001_1110
  constant c_blk_idle_hdr : std_logic_vector(0 to 9) := b"10_01111000";
  constant c_blk_idle : t_blk66 := c_blk_idle_hdr & x"00_00_00_00_00_00_00";

  --  START 0x78 = 0b0111_1000
  --  Preamble byte is 0xaa = 0b1010_1010 (sent from left to right)
  --  SFD is 0b10101011 (sent from left to right)
  --
  --  802.3 2015 46.2.2 Preamble and start of frame delimiter
  --  On transmit the RS converts the first data octet of preamble
  --  transferred from the MAC into s Start control character.
  --
  --  The preamble and SFD are shown previously with their bits ordered for
  --  serial transmission from left to right.  As shown, the left-most bit
  --  of each octect is the LSB of the octet and the right-most bit of each
  --  octet is the MSB of the octet.
  constant c_blk_start_hdr : std_logic_vector(0 to 9) := b"10_00011110";
  constant c_blk_start : t_blk66 := c_blk_start_hdr & x"aa_aa_aa_aa_aa_aa_ab";

  constant c_blk_data : t_blk66 :=
    b"01_00000000_00000000_00000000_00000000_00000000_00000000_00000000_00000000";

  --  TERMINATE 0: 0x87 = 0b1000_0111
  constant c_blk_t0_hdr : std_logic_vector(0 to 9) := b"10_11100001";
  constant c_blk_t0 : t_blk66 := c_blk_t0_hdr
    & b"0000000_0000000_0000000_0000000_0000000_0000000_0000000_0000000";

  --  TERMINATE 1: 0x99 = 0b1001_1001
  constant c_blk_t1_hdr : std_logic_vector(0 to 9) := b"10_10011001";
  constant c_blk_t1 : t_blk66 := c_blk_t1_hdr
    & b"00000000_000000_0000000_0000000_0000000_0000000_0000000_0000000";

  --  TERMINATE 2: 0xaa = 0b1010_1010
  constant c_blk_t2_hdr : std_logic_vector(0 to 9) := b"10_01010101";
  constant c_blk_t2 : t_blk66 := c_blk_t2_hdr
    & b"00000000_00000000_00000_0000000_0000000_0000000_0000000_0000000";

  --  TERMINATE 3: 0xb4 = 0b1011_0100
  constant c_blk_t3_hdr : std_logic_vector(0 to 9) := b"10_00101101";
  constant c_blk_t3 : t_blk66 := c_blk_t3_hdr
    & b"00000000_00000000_00000000_0000_0000000_0000000_0000000_0000000";

  --  TERMINATE 4: 0xcc = 0b1100_1100
  constant c_blk_t4_hdr : std_logic_vector(0 to 9) := b"10_00110011";
  constant c_blk_t4 : t_blk66 := c_blk_t4_hdr
    & b"00000000_00000000_00000000_00000000_000_0000000_0000000_0000000";

  --  TERMINATE 5: 0xd2 = 0b1101_0010
  constant c_blk_t5_hdr : std_logic_vector(0 to 9) := b"10_01001011";
  constant c_blk_t5 : t_blk66 := c_blk_t5_hdr
    & b"00000000_00000000_00000000_00000000_00000000_00_0000000_0000000";

  --  TERMINATE 6: 0xe1 = 0b1110_0001
  constant c_blk_t6_hdr : std_logic_vector(0 to 9) := b"10_10000111";
  constant c_blk_t6 : t_blk66 := c_blk_t6_hdr
    & b"00000000_00000000_00000000_00000000_00000000_00000000_0_0000000";

  --  TERMINATE 7: 0xff = 0b1111_1111
  constant c_blk_t7_hdr : std_logic_vector(0 to 9) := b"10_11111111";
  constant c_blk_t7 : t_blk66 := c_blk_t7_hdr
    & b"00000000_00000000_00000000_00000000_00000000_00000000_00000000";

  --  IEEE 802.3 4.4.2 MAC parameters
  --   minFrameSize = 64B
  --  (From DA to FCS according to 4.2.3.4)

  --  From IEEE 802.3 3.2.9 Framce Check Sequence (FCS) field
  --  Polynom is:
  --  x**32
  --  + x**26
  --  + x**23 + x**22
  --  + x**16
  --  + x**12
  --  + x**11 + x**10 + x**8
  --  + x**7 + x**5 + x**4
  --  + x**2 + x**1 + 1
  --  ie 0x1_04_c1_1d_b7
  --  When reversed: 0xed_b8_83_20_1

  constant crc_poly : t_slv32 := x"04_c1_1d_b7";
  constant crc_poly_rev : t_slv32 := x"ed_b8_83_20";
  constant crc_verify_rev : t_slv32 := x"21_44_df_1c";
end epx_pkg;
  
package body epx_pkg is
  function rev8(d : t_slv8) return t_slv8
  is
    alias rd : std_logic_vector(0 to 7) is d;
    variable res : t_slv8;
  begin
    for i in rd'range loop
      res (i) := rd(i);
    end loop;
    return res;
  end rev8;
end epx_pkg;
  
