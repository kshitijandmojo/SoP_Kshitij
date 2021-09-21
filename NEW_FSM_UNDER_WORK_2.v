module switch_2 #(parameter x_coor=0, y_coor=0, l=0, u=0)(inout data_in_act, inout data_1_act, inout data_2_act, inout data_3_act, inout data_4_act, inout r_1_act, inout r_2_act, inout r_3_act, inout r_4_act, inout ack_1_act, inout ack_2_act, inout ack_3_act, inout ack_4_act, input clk);

//state <= ;
reg buffer_in_use=0;
//buffer_in_use <= 0;
reg buffer_full=0;
integer counter;
reg [1:0] x;
reg [1:0] y;
reg [23:0] data;
reg [1:0] siz;
reg [3:0] r = 4'b0000;
reg [3:0] s = 4'b0000;


reg data_in=0;
reg data_1=0;
reg data_2=0;
reg data_3 =0 ;
reg data_4 = 0;
reg ack_1 =0;
reg ack_2 = 0;
reg ack_3 = 0;
reg ack_4 = 0;
reg r_1 = 0;
reg r_2 =0;
reg r_3 = 0;
reg r_4 = 0;


assign data_in_act = data_in?1:0;
assign data_1_act = data_1?1:0;
assign data_2_act = data_2?1:0;
assign data_3_act = data_3?1:0;
assign data_4_act = data_4?1:0;
assign ack_1_act = ack_1?1:0;
assign ack_2_act = ack_2?1:0;
assign ack_3_act = ack_3?1:0;
assign ack_4_act = ack_4?1:0;
assign r_1_act = r_1?1:0;
assign r_2_act = r_2?1:0;
assign r_3_act = r_3?1:0;
assign r_4_act = r_4?1:0;



localparam GET_PARM_IN = 4'b0000,
	GET_DATA = 4'b0001,
	ROUND_ROBIN = 4'b0010,
	TRANSFER_BUFFER_PARM_INTERNAL = 4'b0011,
	REQUEST_SEND_TO_EXTERNAL = 4'b0100,
	TRANSFER_BUFFER_PARM_TO_EXTERNAL = 4'b0101,
	TRANSFER_BUFFER_DATA_TO_EXTERNAL = 4'b0110,
	MAKE_REQUEST = 4'b0111,
	TRANSFER_BUFFER_DATA_INTERNAL = 4'b1000;
	SEND_DATA_TO_NODE = 4'b1001;

reg [3:0] state=ROUND_ROBIN;

always @(posedge clk)
 begin
	case(state)									//data intake code made, for external sender straight to buffer
		GET_PARM_IN: 
		begin
			buffer_in_use<=1;
			counter <= 0;
			
			if(counter<2)
			begin
				counter <= counter+1;					//x_coordinate of destination
				x[counter]<=data_in_act;

			end
			else if(counter<4)
			begin
				counter <= counter+1;					//y_coordinate of destination
				y[counter-2]<=data_in_act;
			end
			else if(counter<6)
			begin
				counter <= counter+1;
				siz[counter-4]<=data_in_act;				//siz of data packet in byte
				if(counter == 5)
				begin
					state <= GET_DATA;
					counter <= siz[0]*8 + data_1_act*16 - 1;
				end
			end	
		end
			
		GET_DATA: begin
			if(counter>=0)
			begin
				data[counter] <= data_in_act;
				counter <= counter-1;
			end
			else if(counter <0)
			begin
				
					state <= MAKE_REQUEST;		
					buffer_full <= 1;
			end
		end

											//request receive & process module

	ROUND_ROBIN:
	begin
		if(r_1_act == 1 && r[0] == 0 )						//request lines r_1,r_2,r_3, r_4 and side select tracker s[0:3] and roundrobin tracker r[0:3] 
		begin
			
			s[0] <= 1;
										//data_in is by default 0 and made 1 to request,to refuse, other simply holds data_in at 0
			r[0] <= 1 ;	
			state <= REQUEST_SEND_TO_EXTERNAL;
			data_in <= 0;
		end
		else if(r_2_act == 1 && r[1] == 0 )
		begin
			
			s[1] <= 1;
			r[1] <= 1;
			data_in <= 0;
			state <= REQUEST_SEND_TO_EXTERNAL;			//all s[0],s[1],s[2],s[3] will be set zero, after data transfer is complete,so it will remain zero
			
		end
		else if(r_3_act == 1 && r[2] == 0 )
		begin
			
			s[2] <= 1;
			r[2] <= 1;
			data_in <= 0;
			
			state <= REQUEST_SEND_TO_EXTERNAL;
		end

		else if(r_4_act == 1 && r[3] == 0 )
		begin
			
			s[3] <= 1;
			r[3] <= 1;
			data_in <= 0;
			
			state <= REQUEST_SEND_TO_EXTERNAL;
		end

		else if(ack_1_act||ack_2_act||ack_3_act||ack_4_act == 1 )								//ACK waiting, incase buffer is empty
		begin
			state <= TRANSFER_BUFFER_PARM_INTERNAL;
			counter <= 0;
			data_in <= 0;
		end
		else if(data_in_act == 1)
		begin
			state <= GET_PARM_IN;
		end
		else if(data_in_act == 0)
		begin
			r<=4'b0000;
		end
	end

	TRANSFER_BUFFER_PARM_INTERNAL:
	begin
		
		data_in <= 0;
		if(counter < 2)
		begin
			if(r_1_act == 1)
			begin
				data_1 <= x[counter];	
			end
			if(r_2_act == 1)
			begin
				data_2 <= x[counter];
			end
			if(r_3_act == 1)
			begin
				data_3 <= x[counter];	
			end
			if(r_4_act == 1)
			begin
				data_4 <= x[counter];
			end
		end
		if(counter < 4)
		begin
			if(r_1_act == 1)
			begin
				data_1 <= y[counter-2];	
			end
			if(r_2_act == 1)
			begin
				data_2 <=y[counter-2];
			end
			if(r_3_act == 1)
			begin
				data_3 <= y[counter-2];	
			end
			if(r_4_act == 1)
			begin
				data_4 <=y[counter-2];
			end
		end
		if(counter < 6)
		begin
			if(r_1_act == 1)
			begin
				data_1 <= siz[counter-4];
				if(counter == 5)
				begin
					counter <= siz*8;
					state <= TRANSFER_BUFFER_DATA_INTERNAL;
				end
			end
			if(r_2_act == 1)
			begin
				data_2 <=siz[counter-4];
				if(counter == 5)
				begin
					counter <= siz*8;
					state <= TRANSFER_BUFFER_DATA_INTERNAL;
				end
			end
			if(r_3_act == 1)
			begin
				data_3 <= siz[counter-4];
				if(counter == 5)
				begin
					counter <= siz*8;
					state <= TRANSFER_BUFFER_DATA_INTERNAL;
				end	
			end
			if(r_4_act == 1)
			begin
				data_4 <= siz[counter-4];
				if(counter == 5)
				begin
					counter <= siz*8;
					state <= TRANSFER_BUFFER_DATA_INTERNAL;
				end
			end
		end
	end
	TRANSFER_BUFFER_DATA_INTERNAL:
	begin
		
		data_in <= 0;
		if(counter>0)
		begin
			counter <= counter - 1;
			if(r_1_act == 1)
			begin
				data_1 <= data[counter];	
			end
			if(r_2_act == 1)
			begin
				data_2 <= data[counter];
			end
			if(r_3_act == 1)
			begin
				data_3 <= data[counter];	
			end
			if(r_4_act == 1)
			begin
				data_4 <=data[counter];
			end
		end
		else
		begin
			buffer_full <= 0;
			buffer_in_use <= 0;
			state <= ROUND_ROBIN;
		end
	end	
	REQUEST_SEND_TO_EXTERNAL:					//data_in is by default 0 and made 1 to request,to refuse, other simply holds data_in at 0
	begin
		data_in <= 1;							//this is the code for REQUEST_SEND_TO_EXTERNAL state
		if(data_in_act == 1)
		begin
			if(buffer_full == 1)
			begin
				counter <= 0;						//may not happen check
				state <= TRANSFER_BUFFER_PARM_TO_EXTERNAL;
			end
			else if((s[0]||s[1]||s[2]||s[3]) == 1)	
			begin
				ack_1 <= s[0];
				ack_2 <= s[1];
				ack_3 <= s[2];	
				ack_4 <= s[3];
				counter <= 0;										//done to account for transfer starting delay on other fsm LINE_1
															
				state <= TRANSFER_BUFFER_PARM_INTERNAL;
			end	
		end
	end
	

	TRANSFER_BUFFER_PARM_TO_EXTERNAL:
	begin
										//transfer buffer data to external
		if (counter < 3) 
		begin
			data_in<=x[counter-1];
			counter<=counter+1;
		end	
		else if(counter < 5) 
		begin
			data_in<=y[counter-3];
			counter<=counter+1;
		end
		else if(counter < 7)
		begin
			data_in <= siz[counter-5];
			counter <= counter + 1;
			if(counter == 6)
			begin
				counter <= siz[1]*16 +siz[0]*8;
				state <= TRANSFER_BUFFER_DATA_TO_EXTERNAL;
			end
		end
	end
	TRANSFER_BUFFER_DATA_TO_EXTERNAL:
	begin
		data_in <= data[counter];
		counter <= counter-1;
		if(counter == 1)
		begin
			state <= ROUND_ROBIN;
		end			
	end



	MAKE_REQUEST:						//request maker module
	begin
		
		if(x > x_coor && l == 1)						// l & u are directional indicators, to indicate the positioning of the FSM in the node
		begin
			r_2 <= 1;
			if(ack_2_act == 1)
			begin
				state <= TRANSFER_BUFFER_PARM_INTERNAL;
			end
		end
		else if(x > x_coor && l == 0)
		begin
			data_in <= 1;
			state <= REQUEST_SEND_TO_EXTERNAL;

		end
		else if(y > y_coor && u == 1)
		begin
			r_1 <= 1;
			if(ack_1_act == 1)
			begin
				state <= TRANSFER_BUFFER_PARM_INTERNAL;
			end

		end
		else if(y > y_coor && u == 0)
		begin
			r_3 <= 1;
			if(ack_3_act == 1)
			begin
				state <= TRANSFER_BUFFER_PARM_INTERNAL;
			end
		end
		else if(x < x_coor && l == 1)
		begin
			data_in <= 1;
			state <= REQUEST_SEND_TO_EXTERNAL;

		end
		else if(x < x_coor && l == 0)
		begin
			r_2 <= 1;
			if(ack_2 == 1)
			begin
				state <= TRANSFER_BUFFER_PARM_INTERNAL;
			end

		end
		else if(y < y_coor && u == 1)
		begin
			r_3 <= 1;
			if(ack_3 == 1)
			begin
				state <= TRANSFER_BUFFER_PARM_INTERNAL;
			end

		end
		else if(y < y_coor && u == 0)
		begin
			r_1 <= 1;
			if(ack_1_act == 1)
			begin
				state <= TRANSFER_BUFFER_PARM_INTERNAL;
			end
		end
		else
		begin
			r_4<=1;
			if(ack_4_act==1)
			begin
				state<= SEND_DATA_TO_NODE;
				counter<=siz*8;
			end
		end
	end										
	
	SEND_DATA_TO_NODE:
	begin
		if(counter>0)
		begin
			data_4_act<=data[counter-1];
		end
		else
		begin
			state<=ROUND_ROBIN;
		end
	end
		
	
	TRANSFER_BUFFER_PARM_INTERNAL:
	begin
		counter <= counter + 1;
		data_in <= 0;
		if(counter < 2)
		begin
			if(r_1_act == 1)
			begin
				data_in <= data_1_act;	
			end
			if(r_2_act == 1)
			begin
				data_in <=data_2_act;
			end
			if(r_3_act == 1)
			begin
				data_in <= data_3_act;	
			end
			if(r_4_act == 1)
			begin
				data_in <=data_4_act;
			end
		end
		if(counter < 4)
		begin
			if(r_1_act == 1)
			begin
				data_1 <= y[counter-2];	
			end
			if(r_2_act == 1)
			begin
				data_2 <=y[counter-2];
			end
			if(r_3_act == 1)
			begin
				data_3 <= y[counter-2];	
			end
			if(r_4_act == 1)
			begin
				data_4 <=y[counter-2];
			end
		end
		if(counter < 6)
		begin
			if(r_1_act == 1)
			begin
				data_1 <= siz[counter-4];
				if(counter == 5)
				begin
					counter <= siz*8;
					state <= TRANSFER_BUFFER_DATA_INTERNAL;
				end
			end
			if(r_2_act == 1)
			begin
				data_2 <=siz[counter-4];
				if(counter == 5)
				begin
					counter <= siz*8;
					state <= TRANSFER_BUFFER_DATA_INTERNAL;
				end
			end
			if(r_3_act == 1)
			begin
				data_3 <= siz[counter-4];
				if(counter == 5)
				begin
					counter <= siz*8;
					state <= TRANSFER_BUFFER_DATA_INTERNAL;
				end	
			end
			if(r_4_act == 1)
			begin
				data_4 <= siz[counter-4];
				if(counter == 5)
				begin
					counter <= siz*8;
					state <= TRANSFER_BUFFER_DATA_INTERNAL;
				end
			end
		end
	end
	TRANSFER_BUFFER_DATA_INTERNAL:
	begin
		
		data_in <= 0;
		if(counter >= 0)
		begin
			counter <= counter - 1;
			if(r_1_act == 1)
			begin
				data_1 <= data[counter];	
			end
			if(r_2_act == 1)
			begin
				data_2 <=data[counter];
			end
			if(r_3_act == 1)
			begin
				data_3 <= data[counter];	
			end
			if(r_4_act == 1)
			begin
				data_4 <=data[counter];
			end
		end
		else
		begin
			buffer_full <= 0;
			buffer_in_use <= 0;
			state <= ROUND_ROBIN;
		end
	end
	endcase
end


//serializer #(.WIDTH(30)) serializer(.datain, .clk, output reg [WIDTH-1:0] dataout);
//deserializer #(.WIDTH(30)) deserializer(.datain, .clk, output reg [WIDTH-1:0] dataout);


endmodule
