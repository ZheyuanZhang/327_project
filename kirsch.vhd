library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.util.all;
use work.kirsch_synth_pkg.all;

entity kirsch is
  port(
    clk        : in  std_logic;                      
    reset      : in  std_logic;                      
    i_valid    : in  std_logic;                 
    i_pixel    : in  unsigned(7 downto 0);
    o_valid    : out std_logic;                 
    o_edge     : out std_logic;	                     
    o_dir      : out direction_ty;
    o_mode     : out mode_ty;
    o_row      : out unsigned(7 downto 0);
    o_col      : out unsigned(7 downto 0)
  );  
end entity;

architecture main of kirsch is
    signal deriv_n,  deriv_s,  deriv_e,  deriv_w, deriv_ne, deriv_nw, deriv_se, deriv_sw  : integer range -3900 to 3900 ;
    signal max_deriv : integer;
    signal edge_dir : direction_ty;
    signal mem_o1, mem_o2, mem_o3, mem_i : std_logic_vector(7 downto 0);
    signal x_pos : unsigned(7 downto 0);
    signal y_pos : unsigned(7 downto 0);
    signal mark : unsigned(2 downto 0):= to_unsigned(0,3);
    signal current_mark : unsigned(1 downto 0) := to_unsigned(0,2);
    signal counter : unsigned(7 downto 0);
    signal state : unsigned(1 downto 0);
    signal a,b,c,d,e,f,g,h,i : integer range 0 to 255;
    signal v : std_logic_vector(7 downto 0);
begin

mem0 : entity work.mem(main) 
port map(
    clock => clk,
    wren => mark(0),
    address => x_pos,
    data => mem_i,
    q => mem_o1
);

mem1 : entity work.mem(main) 
port map(
    clock => clk,
    wren => mark(1),
    address => x_pos,
    data => mem_i,
    q => mem_o2
);

mem2 : entity work.mem(main) 
port map(
    clock => clk,
    wren => mark(2),
    address => x_pos,
    data => mem_i,
    q => mem_o3
);

process(clk, reset)
begin
if (rising_edge(clk)) then 
    if(reset = '1') then 
        counter <= to_unsigned(0, 8); 
        x_pos <= to_unsigned(0, 8); 
        y_pos <= to_unsigned(0, 8); 
        mark <= to_unsigned(1, 3); 
        o_mode <= "01"; 
        state <= to_unsigned(0,2);
    else
      if(o_mode = "01") then
        o_mode <= "10";
    end if;

  if(o_mode = "10") then 
      counter <= to_unsigned(0, 8); 
      x_pos <= to_unsigned(0, 8); 
      y_pos <= to_unsigned(0, 8); 
      mark <= to_unsigned(1, 3);
      state <= to_unsigned(0,2);
  end if; 
    
  if(state = to_unsigned(0,2)) then
    o_valid <= '0';
      if(i_valid = '1') then
        o_mode <= "11";
  	    mem_i <= std_logic_vector(i_pixel);
        with current_mark select
          mark <= to_unsigned(1, 3) when to_unsigned(0, 2),
                  to_unsigned(2, 3) when to_unsigned(1, 2), 
                  to_unsigned(4, 3) when to_unsigned(2, 2), 
                  to_unsigned(0, 3) when others;
        state <= to_unsigned(1,2);
  
      o_row <= y_pos;
      o_col <= x_pos;
  end if;

	else if(state = to_unsigned(1,2)) then
	    mark <= to_unsigned(0, 3);	   
	    state <= to_unsigned(2,2);
	else if(state = to_unsigned(2,2)) then
	    state <= to_unsigned(3,2);
	else if(state = to_unsigned(3,2)) then
	if(y_pos>= 2) then
	    a <= b;
	    b <= c;
	    with current_mark select
		c <= to_integer(unsigned(mem_o1)) when to_unsigned(2, 2),
		to_integer(unsigned(mem_o2)) when to_unsigned(0, 2), 
		to_integer(unsigned(mem_o3)) when to_unsigned(1, 2), 
		0 when others;
	    h <= i;
	    i <= d;
	    with current_mark select
		d <= to_integer(unsigned(mem_o2)) when to_unsigned(2, 2),
		to_integer(unsigned(mem_o3)) when to_unsigned(0, 2), 
		to_integer(unsigned(mem_o1)) when to_unsigned(1, 2), 
		0 when others;
	    g <= f;
	    f <= e;
	    with current_mark select
		e <= to_integer(unsigned(mem_o3)) when to_unsigned(2, 2),
		to_integer(unsigned(mem_o1)) when to_unsigned(0, 2), 
		to_integer(unsigned(mem_o2)) when to_unsigned(1, 2), 
		0 when others;
      
	    if(x_pos >= 2) then
    ----------------------------------------------------
    		deriv_e  <= 5*(c + d + e) - 3*(a + b + f + g + h);
    		deriv_ne <= 5*(b + c + d) - 3*(a + e + f + g + h);
    		deriv_n  <= 5*(a + b + c) - 3*(d + e + f + g + h);
    		deriv_nw <= 5*(a + b + h) - 3*(c + d + e + f + g);
    		deriv_w  <= 5*(a + g + h) - 3*(b + c + d + e + f);
    		deriv_sw <= 5*(f + g + h) - 3*(a + b + c + d + e);
    		deriv_s  <= 5*(e + f + g) - 3*(a + b + c + d + h);
    		deriv_se <= 5*(d + e + f) - 3*(a + b + c + g + h);
    		max_deriv <= 0;

    		if deriv_sw >= max_deriv then
    		  max_deriv <= deriv_sw;
    		  edge_dir <= dir_sw;
    		end if;
    		if deriv_s >= max_deriv then
    		  max_deriv <= deriv_s;
    		  edge_dir <= dir_s;
    		end if;
    		if deriv_se >= max_deriv then
    		  max_deriv <= deriv_se;
    		  edge_dir <= dir_se;
    		end if;
    		if deriv_e >= max_deriv then
    		  max_deriv <= deriv_e;
    		  edge_dir <= dir_e;
    		end if;
    		if deriv_ne >= max_deriv then
    		  max_deriv <= deriv_ne;
    		  edge_dir <= dir_ne;
    		end if;
    		if deriv_n >= max_deriv then
     		  max_deriv <= deriv_n;
     		  edge_dir <= dir_n;
    		end if;
    		if deriv_nw >= max_deriv then
    		  max_deriv <= deriv_nw;
    		  edge_dir <= dir_nw;
    		end if;
   		 if deriv_w >= max_deriv then
    		  max_deriv <= deriv_w;
    		  edge_dir <= dir_w;
    		end if;
    
    		if max_deriv > 383 then
      		  o_edge <= '1';
		        o_dir <= edge_dir;
		        o_valid <= '1';
    		else
      		  o_edge <= '0'; 
            o_dir <= (others => '0');
		        o_valid <= '1';
    		end if;
	-------------------------------------------------
	    else
         o_edge <= '0';
		     o_dir <= (others => '0');
	    end if;
	    end if;
	    
	    if((y_pos = to_unsigned(255, 8)) AND (x_pos = to_unsigned(255, 8))) then
		    o_mode <= "10";
	    end if;
	    
	    if(x_pos = to_unsigned(255, 8)) then
		      y_pos <= y_pos+1;
	        with current_mark select
		        current_mark <= to_unsigned(0, 2) when to_unsigned(2, 2),
		                        to_unsigned(1, 2) when to_unsigned(0, 2), 
		                        to_unsigned(2, 2) when to_unsigned(1, 2), 
                            to_unsigned(0, 2) when others;
	    end if;
	    
	    x_pos <= x_pos+1;
	    state <= to_unsigned(0,2);
	end if;
        end if;
        end if;
        end if;
	end if;
    end if;
end process;
  
end architecture;