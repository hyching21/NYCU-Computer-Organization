module ShiftLeftOne (
    input signed [31:0] i,
    output signed [31:0] o
);

    // TODO: implement your shift left 1 here
    assign o = i << 1;
    //assign o = {i[30:0], 1'b0};
endmodule

