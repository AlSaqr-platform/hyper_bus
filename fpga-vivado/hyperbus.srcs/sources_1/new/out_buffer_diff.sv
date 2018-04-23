`timescale 1ns / 1ps

module out_buffer_diff
(
    input  logic in_i,
    input  logic en_i, //high enable
    output logic out_o,
    output logic out_no
);


    
    OBUFTDS out_buffer
    (
        .I  ( in_i   ),
        .T  ( ~en_i  ),
        .O  ( out_o  ),
        .OB ( out_no )
    );
    
endmodule
