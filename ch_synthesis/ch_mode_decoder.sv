import types_pkg::*;

module ch_mode_decoder (
    input logic INST_START,
    input smode_t MODE,

    output logic start1,
    output logic start2,
    output logic start4
);
    always_comb begin
        if (INST_START) begin //since INST_START is a pulse (of unknown width), this generates a start sampling pulse
           case (MODE) 
                    MODE_SAMPLE1: 
                        begin
                            start1 = 1;
                            start2 = 0;
                            start4 = 0;
                        end
                    MODE_SAMPLE2: 
                        begin
                            start1 = 0;
                            start2 = 1;
                            start4 = 0;
                        end
                    MODE_SAMPLE4: 
                        begin
                            start1 = 0;
                            start2 = 0;
                            start4 = 1;
                        end 
                    default: //default should only be reached on MODE = 2'b10 
                        begin
                            //default is to sample only one pulse with all four fast banks
                            start1 = 0;
                            start2 = 0;
                            start4 = 1;
                        end
                endcase 
        end
        else begin //resets the pulse
            start1 = 0;
            start2 = 0;
            start4 = 0;
        end
    end
endmodule