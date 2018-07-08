library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity lab3 is
  port (
    clk       : in  std_logic;             -- the system clock
    reset     : in  std_logic;             -- reset
    i_valid   : in  std_logic;             -- input data is valid
    i_data    : in  unsigned(7 downto 0);  -- input data
    o_done    : out std_logic;             -- done processing
    o_data    : out unsigned(7 downto 0)   -- output data
  );
end entity lab3;

architecture main of lab3 is

signal mem_o1 : std_logic_vector(7 downto 0);
signal mem_o2 : std_logic_vector(7 downto 0);
signal mem_o3 : std_logic_vector(7 downto 0);
signal mem_i : std_logic_vector(7 downto 0);
signal calc : unsigned(9 downto 0);
signal x_pos : unsigned(3 downto 0);
signal y_pos : unsigned(3 downto 0);
signal mark : unsigned(2 downto 0):= to_unsigned(0,3);
signal c : unsigned(1 downto 0) := to_unsigned(0,2);
signal counter : unsigned(7 downto 0);
signal state : unsigned(1 downto 0);

begin

mem0 : entity work.mem(main) 
port map(
    clock => clk,
    wr_en => mark(0),
    address => x_pos,
    i_data => mem_i,
    o_data => mem_o1
);

mem1 : entity work.mem(main) 
port map(
    clock => clk,
    wr_en => mark(1),
    address => x_pos,
    i_data => mem_i,
    o_data => mem_o2
);

mem2 : entity work.mem(main) 
port map(
    clock => clk,
    wr_en => mark(2),
    address => x_pos,
    i_data => mem_i,
    o_data => mem_o3
);
	  
o_data <= counter;

with c select
calc <= unsigned("00"&unsigned(mem_o1)) - unsigned("00"&unsigned(mem_o3))+ unsigned("00"&unsigned(mem_o2)) when to_unsigned(0, 2),
unsigned("00"&unsigned(mem_o2)) - unsigned("00"&unsigned(mem_o1)) + unsigned("00"&unsigned(mem_o3)) when to_unsigned(1, 2), 
unsigned("00"&unsigned(mem_o3)) - unsigned("00"&unsigned(mem_o2))+ unsigned("00"&unsigned(mem_o1)) when to_unsigned(2, 2), 
to_unsigned(0, 10) when others;

process(clk, reset)
begin
    if (rising_edge(clk)) then 
        if(o_done = '1') then 
            counter <= to_unsigned(0, 8); 
            x_pos <= to_unsigned(0, 4); 
            y_pos <= to_unsigned(0, 4); 
            mark <= to_unsigned(1, 3); 
            o_done <= '0';
	    state <= to_unsigned(0,2);
        end if; 
    
        if(reset = '1') then 
            counter <= to_unsigned(0, 8); 
            x_pos <= to_unsigned(0, 4); 
            y_pos <= to_unsigned(0, 4); 
            mark <= to_unsigned(1, 3); 
            o_done <= '0'; 
	    state <= to_unsigned(0,2);
        end if; 
    
    	if(state = to_unsigned(0,2)) then
    	    if(i_valid = '1') then
	    	mem_i <= std_logic_vector(i_data);
	        with c select
		    mark <= to_unsigned(1, 3) when to_unsigned(0, 2),
		    to_unsigned(2, 3) when to_unsigned(1, 2), 
		    to_unsigned(4, 3) when to_unsigned(2, 2), 
		    to_unsigned(0, 3) when others;
		state <= to_unsigned(1,2);
	    end if;
	else if(state = to_unsigned(1,2)) then
	    mark <= to_unsigned(0, 3);	   
	    state <= to_unsigned(2,2);
	else if(state = to_unsigned(2,2)) then
	    state <= to_unsigned(3,2);
	else if(state = to_unsigned(3,2)) then
	    if(y_pos >= 2) then
	        if(calc(9) = '0') then
	    	    counter <= counter + 1;
	        end if;
	    end if;
	    if(x_pos = 15) then
		y_pos <= y_pos+1;
	        with c select
		    c <= to_unsigned(0, 2) when to_unsigned(2, 2),
		    to_unsigned(1, 2) when to_unsigned(0, 2), 
		    to_unsigned(2, 2) when to_unsigned(1, 2), 
		    to_unsigned(0, 2) when others;
	    end if;
	    
	    x_pos <= x_pos+1;
	    if((y_pos = to_unsigned(15, 8)) AND (x_pos = to_unsigned(15, 8))) then
		o_done <= '1';
	    end if;
	    
	    state <= to_unsigned(0,2);
	end if;
        end if;
        end if;
        end if;
    end if;
end process;

end architecture main;

-- Q1: number of flip flops and lookup tables?
-- 6 flip flops. 3 lookup tables

-- Q2: maximum clock frequency?
-- 82 MHz

-- Q3: source and destination signals of critical path?
-- source: mem1_mem/...84/clock0
-- destination: counter(7)/ena

-- Q4: does your implementation function correctly?  If not,
-- explain the bug and how you would fix it if you had more time.
-- Yes it's implemented correctly.
