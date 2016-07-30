module address_selector(clk,addra,control,write_enable,write_done);

	input clk;
	input [18:0] addra;
	input control;

	output reg write_enable,write_done;
	
	always@(posedge clk)
	begin
		begin
			if(control == 0)
			begin
				write_enable <= 0;
			end else 
			begin
				if(addra == 0) 
				begin
					write_enable <= 1;
					write_done <= 0;
				end
				
			end
		end
	end

endmodule