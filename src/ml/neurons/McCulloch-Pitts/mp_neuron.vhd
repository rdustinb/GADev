-- Author: Dustin Brothers
-- Creation Date: September 2, 2023
-- License: CERN Open Hardware Licence Version 2 - Strongly Reciprocal

library ieee;

use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity mp_boolean is
  generic (
    INPUT_FF                : std_logic := '0';
    OUTPUT_FF               : std_logic := '0';
    INPUT_COUNT             : integer := 1
  );
  port (
    clk                     : in    std_logic;
    arst_n                  : in    std_logic;
    srst_n                  : in    std_logic;
    dendrite_x              : in    std_logic_vector(INPUT_COUNT-1 downto 0); -- Inputs are boolean, 0 or 1
    dendrite_mode           : in    std_logic_vector(INPUT_COUNT-1 downto 0); -- Excitatory = 1; Inhibitory = 0
    theta_g                 : in    std_logic_vector(ceil(log2(real(INPUT_COUNT))) downto 0);
    axon_y                  :   out std_logic
  );
end entity mp_boolean;

architecture rtl of mp_boolean is

  -- These inputs can either be excitatory or inhibitory. Inhibitory inputs are those 
  -- that have maximum effect on the decision making irrespective of other inputs i.e., 
  -- if x_3 is 1 (not home) then my output will always be 0 i.e., the neuron will never 
  -- fire, so x_3 is an inhibitory input. Excitatory inputs are NOT the ones that will 
  -- make the neuron fire on their own but they might fire it when combined together.
  --
  -- https://towardsdatascience.com/mcculloch-pitts-model-5fdf65ac5dd1 
  constant EXCITATORY       : std_logic := '1';
  constant INHIBITORY       : std_logic := '0';

  signal dendrite_x_i       : std_logic_vector(INPUT_COUNT-1 downto 0);
  signal dendrite_mode_i    : std_logic_vector(INPUT_COUNT-1 downto 0);
  signal theta_g_i          : std_logic_vector(ceil(log2(real(INPUT_COUNT))) downto 0);
  signal excitatory_sum_i   : std_logic_vector(ceil(log2(real(INPUT_COUNT))) downto 0);
  signal excitatory_flag_i  : std_logic;
  signal inhibitory_flag_i  : std_logic;

  -- Sums all the EXCITATORY Inputs
  function sum_excitatory (
    x : std_logic_vector;
    mode : std_logic_vector
  ) return unsigned is
    variable sum : unsigned;
  begin
    
    -- Zeroize the sum at the beginning of every call...
    sum := 0;

    -- Loop through all values, checking their modes
    for thisOne in x'right to x'left loop
      if mode(thisOne) = EXCITATORY then
        sum := sum + 1;
      end if;
    end loop;

    -- Return the sum
    return sum;

  end function;

  -- Checks for *any* INHIBITORY Input
  function check_inhibitory (
    x : std_logic_vector;
    mode : std_logic_vector
  ) return std_logic is
    variable flag_inhibited : std_logic;
  begin

    -- Set flag to not-inhibited
    flag_inhibited := '0';

    -- Loop through all values, checking their modes
    for thisOne in x'right to x'left loop
      if mode(thisOne) = INHIBITORY and x(thisOne) = '1' then
        -- If any one of the inhibitory inputs is active, the whole
        -- neuron is inhibited
        flag_inhibited := '1';
      end if;
    end loop;

    -- Return the flag
    return flag_inhibited;

  end function;

begin

  ------------------------------------------------------------------------------
  -- Pipeline Stage
  ------------------------------------------------------------------------------
  gen_input_pipeline_ffs : if(INPUT_FF = '1') generate
    -- Pipeline FF
    input_pipeline_process : process(clk, arst_n) begin
      if(arst_n = '0') then
        dendrite_x_i <= (others => '0');
        dendrite_mode_i <= (others => EXCITATORY);
        theta_g_i <= (others => '0');
      else
        if(srst_n = '0') then
          dendrite_x_i <= (others => '0');
          dendrite_mode_i <= (others => EXCITATORY);
          theta_g_i <= (others => '0');
        elsif rising_edge(clk) then
          dendrite_x_i <= dendrite_x;
          dendrite_mode_i <= dendrite_mode;
          theta_g_i <= theta_g;
        end if;
      end if;
    end process input_pipeline_process;
  else generate
    -- No Pipeline FF
    dendrite_x_i <= dendrite_x;
    dendrite_mode_i <= dendrite_mode;
    theta_g_i <= theta_g;
  end generate;

  ------------------------------------------------------------------------------
  -- Aggregation
  ------------------------------------------------------------------------------
  aggregation_process : process(all) begin
    -- Sum all the Excitatory Inputs
    excitatory_sum_i <= sum_excitatory(dendrite_x_i, dendrite_mode_i);
    -- Flag Excitatory threshold
    excitatory_flag_i <= '1' when excitatory_sum_i >= theta_g_i else '0';
    -- Check for ANY Inhibitory Inputs
    inhibitory_flag_i <= check_inhibitory(dendrite_x_i, dendrite_mode_i);
  end process aggregation_process;

  ------------------------------------------------------------------------------
  -- Function
  ------------------------------------------------------------------------------
  gen_output_pipeline_ffs : if(OUTPUT_FF = '1') generate
    -- Pipeline FF
    output_pipeline_process : process(clk, arst_n) begin
      if(arst_n = '0') then
        axon_y <= '0';
      else
        if(srst_n = '0') then
          axon_y <= '0';
        elsif rising_edge(clk) then
          axon_y <= '1' when (
            excitatory_flag_i = '1' and
            inhibitory_flag_i = '0'
          ) else '0';
        end if;
      end if;
    end process output_pipeline_process;
  else generate
    -- No Pipeline FF
    axon_y <= '1' when (
      excitatory_flag_i = '1' and
      inhibitory_flag_i = '0'
    ) else '0';
  end generate;

end rtl;
