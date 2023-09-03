-- Author: Dustin Brothers
-- Creation Date: September 2, 2023
-- License: CERN Open Hardware Licence Version 2 - Strongly Reciprocal

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mp_boolean is
  generic (
    INPUT_FF              : std_logic := '0';
    OUTPUT_FF             : std_logic := '0';
    INPUT_COUNT           : integer := 1
  );
  port (
    clk                   : in    std_logic;
    arst_n                : in    std_logic;
    srst_n                : in    std_logic;
    dendrite_x            : in    std_logic_vector(INPUT_COUNT-1 downto 0); -- Inputs are boolean, 0 or 1
    dendrite_mode         : in    std_logic_vector(INPUT_COUNT-1 downto 0); -- Excitatory = 1; Inhibitory = 0
    theta_g               : in    std_logic_vector(ceil(log2(real(INPUT_COUNT))) downto 0);
    axon_y                :   out std_logic
  );
end entity mp_boolean;

architecture rtl of mp_boolean is

  constant EXCITATORY     : std_logic := '1';
  constant INHIBITORY     : std_logic := '0';

  signal dendrite_x_i     : std_logic_vector(INPUT_COUNT-1 downto 0);
  signal dendrite_mode_i  : std_logic_vector(INPUT_COUNT-1 downto 0);

  function sum_when_mode_1 (
    x : std_logic_vector;
    mode : std_logic_vector
  ) return unsigned is
    variable sum : unsigned;
  begin
      
      return sum;
  end function;

begin

  -- TODO should there be a mode for each input?

  ------------------------------------------------------------------------------
  -- Pipeline Stage
  ------------------------------------------------------------------------------
  gen_input_pipeline_ffs : if(INPUT_FF = '1') generate
    -- Pipeline FF
    input_pipeline_process : process(clk, arst_n) begin
      if(arst_n = '0') then
        dendrite_x_i <= (others => '0');
        dendrite_mode_i <= (others => EXCITATORY);
      else
        if(srst_n = '0') then
          dendrite_x_i <= (others => '0');
          dendrite_mode_i <= (others => EXCITATORY);
        elsif rising_edge(clk) then
          dendrite_x_i <= dendrite_x;
          dendrite_mode_i <= dendrite_mode;
        end if;
      end if;
    end process input_pipeline_process;
  else generate
    -- No Pipeline FF
    dendrite_x_i <= dendrite_x;
    dendrite_mode_i <= dendrite_mode;
  end generate;

  ------------------------------------------------------------------------------
  -- Aggregation
  ------------------------------------------------------------------------------
  aggregation_process : process(all) begin
    excitatory_sum_i <= 
  end process aggregation_process;

  ------------------------------------------------------------------------------
  -- Function
  ------------------------------------------------------------------------------
  gen_output_pipeline_ffs : if(OUTPUT_FF = '1') generate
    -- Pipeline FF
    output_pipeline_process : process(clk, arst_n) begin
      if(arst_n = '0') then
      else
        if(srst_n = '0') then
        elsif rising_edge(clk) then
        end if;
      end if;
    end process output_pipeline_process;
  else generate
    -- No Pipeline FF
  end generate;

end rtl;
