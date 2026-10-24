module traffic_fsm_final #(
    parameter GREEN_LOW_TIME    = 5,
    parameter GREEN_MEDIUM_TIME = 10,
    parameter GREEN_HIGH_TIME   = 20,
    parameter YELLOW_TIME       = 3,
    parameter RED_TIME          = 8,
    parameter PEDESTRIAN_TIME   = 6
)(input clk,input reset,input wire timer_expired,input wire[1:0] vehicle_density,input wire pedestrian_request,
  output reg [31:0] timer_limit,
    output reg red,
    output reg yellow,
    output reg green,
    output reg pedestrian_active
);
localparam GREEN=2'b00;
localparam YELLOW=2'b01;
localparam RED=2'b10;
localparam PEDESTRIAN=2'b11;

reg[1:0]current_state;
reg[1:0]next_state;
reg ped_request_latched;
always @(posedge clk or posedge reset)begin
   if (reset)
        ped_request_latched<=0;

   else if (pedestrian_request)
        ped_request_latched<=1;
   
     else if (current_state==PEDESTRIAN)
        ped_request_latched<=0;
end
always @(posedge clk or posedge reset)begin
if (reset)
    current_state<=RED;
else current_state<=next_state;
end

always@(*)begin
next_state=current_state;
case(current_state)
    GREEN:if(timer_expired)begin
        next_state<=YELLOW;
        end
   YELLOW:if(timer_expired)begin
          next_state<=RED;
          end
   RED:if(timer_expired)begin
        if(ped_request_latched)
           next_state<=PEDESTRIAN;
         else next_state<=RED;
        end

   PEDESTRIAN:if(timer_expired)begin
        next_state<=GREEN;
        end
 endcase
end

always @(*) begin

        red               = 1'b0;
        yellow            = 1'b0;
        green             = 1'b0;
        pedestrian_active = 1'b0;

        timer_limit = GREEN_LOW_TIME;

        case (current_state)

            GREEN: begin
                green = 1'b1;

                case (vehicle_density)
                    2'b00:
                        timer_limit = GREEN_LOW_TIME;

                    2'b01:
                        timer_limit = GREEN_MEDIUM_TIME;

                    default:
                        timer_limit = GREEN_HIGH_TIME;
                endcase
            end

            YELLOW: begin
                yellow = 1'b1;
                timer_limit = YELLOW_TIME;
            end

            RED: begin
                red = 1'b1;
                timer_limit = RED_TIME;
            end

            PEDESTRIAN: begin
                red = 1'b1;
                pedestrian_active = 1'b1;
                timer_limit = PEDESTRIAN_TIME;
            end

            default: begin
                red = 1'b1;
                timer_limit = RED_TIME;
            end

        endcase
    end
endmodule