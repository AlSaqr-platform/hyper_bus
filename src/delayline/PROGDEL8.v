module PROGDEL8 (A,S,Z);
    input A;
    input [7:0] S;
    output Z;

    wire [7:0] delayed;
    wire [7:0] muxed;

    DEL4M1W delay0 (.A(delayed[0]), .Z(delayed[1]));
    DEL4M1W delay1 (.A(delayed[1]), .Z(delayed[2]));
    DEL4M1W delay2 (.A(delayed[2]), .Z(delayed[3]));
    DEL4M1W delay3 (.A(delayed[3]), .Z(delayed[4]));
    DEL4M1W delay4 (.A(delayed[4]), .Z(delayed[5]));
    DEL4M1W delay5 (.A(delayed[5]), .Z(delayed[6]));
    DEL4M1W delay6 (.A(delayed[6]), .Z(delayed[7]));

    CKMUX2M2W mux0 (.A(muxed[1]), .B(delayed[0]), .S(S[0]), .Z(muxed[0]));
    CKMUX2M2W mux1 (.A(muxed[2]), .B(delayed[1]), .S(S[1]), .Z(muxed[1]));
    CKMUX2M2W mux2 (.A(muxed[3]), .B(delayed[2]), .S(S[2]), .Z(muxed[2]));
    CKMUX2M2W mux3 (.A(muxed[4]), .B(delayed[3]), .S(S[3]), .Z(muxed[3]));
    CKMUX2M2W mux4 (.A(muxed[5]), .B(delayed[4]), .S(S[4]), .Z(muxed[4]));
    CKMUX2M2W mux5 (.A(muxed[6]), .B(delayed[5]), .S(S[5]), .Z(muxed[5]));
    CKMUX2M2W mux6 (.A(muxed[7]), .B(delayed[6]), .S(S[6]), .Z(muxed[6]));

    assign delayed[0] = A;
    assign muxed[7] = delayed[7];
    assign Z = muxed[0];
endmodule
