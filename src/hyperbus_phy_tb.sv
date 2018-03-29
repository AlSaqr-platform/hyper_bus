// Copyright (C) 2017 ETH Zurich, University of Bologna
// All rights reserved.
//
// This code is under development and not yet released to the public.
// Until it is released, the code is under the copyright of ETH Zurich and
// the University of Bologna, and may contain confidential and/or unpublished
// work. Any reuse/redistribution is strictly forbidden without written
// permission from ETH Zurich.

`timescale 1ps/1ps

module hyperbus_phy_tb;

  timeunit 1ns;

  localparam TCLK = 3ns;
  localparam NR_CS = 2;
  localparam BURST_WIDTH = 12;

  logic                   clk_i;
  logic                   rst_ni;
  logic                   trans_valid_i;
  logic                   trans_ready_o;
  logic [31:0]            trans_address_i;
  logic [NR_CS-1:0]       trans_cs_i;
  logic                   trans_write_i;
  logic [BURST_WIDTH-1:0] trans_burst_i;
  logic                   trans_address_space_i;
  logic                   tx_valid_i;
  logic                   tx_ready_o;
  logic [15:0]            tx_data_i;
  logic [1:0]             tx_strb_i;
  logic                   rx_valid_o;
  logic                   rx_ready_i;
  logic [15:0]            rx_data_o;
  logic [NR_CS-1:0]       hyper_cs_no;
  logic                   hyper_ck_o;
  logic                   hyper_ck_no;
  logic                   hyper_rwds_o;
  logic                   hyper_rwds_i;
  logic                   hyper_rwds_oe_o;
  logic [7:0]             hyper_dq_i;
  logic [7:0]             hyper_dq_o;
  logic                   hyper_dq_oe_o;
  logic                   hyper_reset_no;

  // Instantiate device under test.
  hyperbus_phy #(
    .NR_CS(NR_CS),
    .BURST_WIDTH(BURST_WIDTH)
  ) dut_i (
    .clk_i                ( clk_i                 ),
    .rst_ni               ( rst_ni                ),
    .trans_valid_i        ( trans_valid_i         ),
    .trans_ready_o        ( trans_ready_o         ),
    .trans_address_i      ( trans_address_i       ),
    .trans_cs_i           ( trans_cs_i            ),
    .trans_write_i        ( trans_write_i         ),
    .trans_burst_i        ( trans_burst_i         ),
    .trans_address_space_i( trans_address_space_i ),
    .tx_valid_i           ( tx_valid_i            ),
    .tx_ready_o           ( tx_ready_o            ),
    .tx_data_i            ( tx_data_i             ),
    .tx_strb_i            ( tx_strb_i             ),
    .rx_valid_o           ( rx_valid_o            ),
    .rx_ready_i           ( rx_ready_i            ),
    .rx_data_o            ( rx_data_o             ),
    .hyper_cs_no          ( hyper_cs_no           ),
    .hyper_ck_o           ( hyper_ck_o            ),
    .hyper_ck_no          ( hyper_ck_no           ),
    .hyper_rwds_o         ( hyper_rwds_o          ),
    .hyper_rwds_i         ( hyper_rwds_i          ),
    .hyper_rwds_oe_o      ( hyper_rwds_oe_o       ),
    .hyper_dq_i           ( hyper_dq_i            ),
    .hyper_dq_o           ( hyper_dq_o            ),
    .hyper_dq_oe_o        ( hyper_dq_oe_o   ),
    .hyper_reset_no       ( hyper_reset_no  )
  );

  wire        rwds;
  wire [7:0 ] dq_io;

  int i;

  // TODO: Instantiate model of HyperRAM/HyperFlash.
  pad_simulation pad_sim (
    .data_i   (hyper_rwds_o),   
    .oe_i     (hyper_rwds_oe_o),
    .data_o   (hyper_rwds_i),  
    .pad_io   (rwds) 
  );

  assign hyper_dq_i = dq_io;
  assign dq_io = hyper_dq_oe_o ? hyper_dq_o : 8'bz;

  s27ks0641 #(.mem_file_name("../src/s27ks0641.mem"), .TimingModel("S27KS0641DPBHI020")) hyperram_model
  (
    .DQ7      (dq_io[7]),
    .DQ6      (dq_io[6]),
    .DQ5      (dq_io[5]),
    .DQ4      (dq_io[4]),
    .DQ3      (dq_io[3]),
    .DQ2      (dq_io[2]),
    .DQ1      (dq_io[1]),
    .DQ0      (dq_io[0]),
    .RWDS     (rwds),
    .CSNeg    (hyper_cs_no[0]),
    .CK       (hyper_ck_o),
    .CKNeg    (hyper_ck_no),
    .RESETNeg (hyper_reset_no)    
  );

  always begin
      clk_i = 1;
      #(TCLK/2);
      clk_i = 0;
      #(TCLK/2);
  end

  int expectedResultAt05FFF3[16] = '{16'h0f03, 16'h0f04, 16'h0f05, 16'h0f06, 16'h0f07, 16'h0f08, 16'h0f09, 16'h0f0a, 16'h0f0b, 16'h0f0c, 16'h0f0d, 16'h0f0e, 16'h0f0f, 16'h1001, 16'h2002, 16'h3003};
  int expectedResultAll1234[8] = '{default: 16'h1234};
  int expectedResultSimple[47] = '{16'h0001, 16'h0002, 16'h0003, 16'h0004, 16'h0005, 16'h0006, 16'h0007, 16'h0008, 16'h0009, 16'h000A, 16'h000B, 16'h000C, 16'h000D, 16'h000E, 16'h000F, 16'h0010, 16'h0011, 16'h0012, 16'h0013, 16'h0014, 16'h0015, 16'h0016, 16'h0017, 16'h0018, 16'h0019, 16'h001A, 16'h001B, 16'h001C, 16'h001D, 16'h001E, 16'h001F, 16'h0020, 16'h0021, 16'h0022, 16'h0023, 16'h0024, 16'h0025, 16'h0026, 16'h0027, 16'h0028, 16'h0029, 16'h002A, 16'h002B, 16'h002C, 16'h002D, 16'h002E, 16'h002F};

  int writeData8[8] = '{16'h1001, 16'h2002, 16'h3003, 16'h40FF, 16'h5555, 16'h6006, 16'h7007, 16'h8008};
  logic [1:0] maskAll8[8] = '{3: 2'b01, 4: 2'b10, default: 2'b00 };
  int expectedResultWrite[8] = '{16'h1001, 16'h2002, 16'h3003, 16'h4004, 16'h0055, 16'h6006, 16'h7007, 16'h8008};

  int writeData64[64] = '{16'h0f00, 16'h0f01, 16'h0f02, 16'h0f03, 16'h0f04, 16'h0f05, 16'h0f06, 16'h0f07, 16'h0f08, 16'h0f09, 16'h0f0a, 16'h0f0b, 16'h0f0c, 16'h0f0d, 16'h0f0e, 16'h0f0f, 16'h0000, 16'h1001, 16'h2002, 16'h3003, 16'h4004, 16'h5005, 16'h6006, 16'h7007, 16'h8008, 16'h9009, 16'ha00a, 16'hb00b, 16'hc00c, 16'hd00d, 16'he00e, 16'hf00f, 16'h0f00, 16'h0f01, 16'h0f02, 16'h0f03, 16'h0f04, 16'h0f05, 16'h0f06, 16'h0f07, 16'h0f08, 16'h0f09, 16'h0f0a, 16'h0f0b, 16'h0f0c, 16'h0f0d, 16'h0f0e, 16'h0f0f, 16'h0000, 16'h1001, 16'h2002, 16'h3003, 16'h4004, 16'h5005, 16'h6006, 16'h7007, 16'h8008, 16'h9009, 16'ha00a, 16'hb00b, 16'hc00c, 16'hd00d, 16'he00e, 16'hf00f};
  logic [1:0] mask64[64] = '{14: 2'b01, 43: 2'b10, default: 2'b00 };
  int regWriteData[1] = '{16'h8f1f};
  int regWriteData2[1] = '{16'h0002};

  program test_hyper_phy;

    typedef struct {
        int afterByte;
        int cycles;
    } InterruptHandshake;

    class transactionResult;
        realtime time_to_first_byte;

        int burst;
        int received_data[];
        logic testPassed = 1'bx;

        function new (int burst);
            this.burst = burst;
            this.received_data = new[burst];    
        endfunction

        task setReceivedData(int index, int data);
            this.received_data[index] = data;
        endtask

        task check(int expectedResult[]);
            if(this.testPassed !== 1'b0) begin
                this.testPassed = 1'b1;
            end

            for (int i = 0; i < this.burst; i++) begin
                assert(this.received_data[i] == expectedResult[i]) else $error("Received %4h at index %p, but expected %4h", this.received_data[i], i, expectedResult[i]);
                if(this.received_data[i] != expectedResult[i])
                    this.testPassed = 1'b0;
            end
        endtask

        task checkTimeOfFirstByte(int min_time, int max_time);
            assert(this.time_to_first_byte > min_time) else begin 
                $error("Returned data too fast: time_to_first_byte = %p, expected value between %p and %p", this.time_to_first_byte, min_time, max_time);
                this.testPassed = 1'b0;
            end
            assert(this.time_to_first_byte < max_time) else begin
                $error("Returned data too late: time_to_first_byte = %p, expected value between %p and %p", this.time_to_first_byte, min_time, max_time);
                this.testPassed = 1'b0;
            end
        endtask : checkTimeOfFirstByte

        task printResult();
            $display("%4s | %4d ns | %4d words", this.testPassed ? "Pass" : "Fail", this.time_to_first_byte, this.received_data.size(), );
        
        endtask : printResult

        task printData(int expectedResult[] = null);
            for (int i = 0; i < this.burst; i++) begin
                if(expectedResult) begin
                    $display("Data at index %h is %4h, expected %4h", i, this.received_data[i], expectedResult[i]);
                end else begin
                    $display("Data at index %h is %4h", i, this.received_data[i]);
                end
            end
        endtask 

    endclass : transactionResult

    class transactionStimuli;
        int address;
        int burst;
        logic address_space = 0;
        logic isWrite = 0;
        int writeData[];
        logic[1:0] writeMask[];
        transactionResult result;

        InterruptHandshake interruptions[$];

        function new (int address, int burst);
            this.address = address;
            this.burst = burst;
        endfunction

        task write(int data[], logic[1:0] mask[]);
            this.isWrite = 1;
            this.writeData = data;
            this.writeMask = mask;
        endtask : write

        task name(string name);
            $display("");
            $display("-------------------------------------");
            $display("Test ", name);
            $display("-------------------------------------");
        endtask : name

        task addInterruptHandshake(int afterByte, int cycles);
            this.interruptions.push_back('{afterByte, cycles});

            // for (int i = 0; i < this.interruptions.size; i++)
            //     $display("Interruption at %p for %p cycles", this.interruptions[i].afterByte, this.interruptions[i].cycles);
        endtask

        function int doInterrupt(int afterByte);
            for (int i = 0; i < this.interruptions.size; i++) begin
                if(this.interruptions[i].afterByte == afterByte)
                    return this.interruptions[i].cycles;
            end

            return 0;
        endfunction

    endclass : transactionStimuli

    // SystemVerilog "clocking block"
    // Clocking outputs are DUT inputs and vice versa
    default clocking cb_hyper_phy @(posedge clk_i);
      default input #1step output #1ns;
      output negedge rst_ni;

      output trans_valid_i, trans_address_i, trans_cs_i, trans_write_i, trans_burst_i, trans_address_space_i;
      input trans_ready_o;

      output tx_valid_i, tx_data_i, tx_strb_i;
      input tx_ready_o;

      output rx_ready_i;
      input rx_valid_o, rx_data_o;
    endclocking

    transactionStimuli stimuli;
    transactionResult result;

    // Apply the test stimulus
    initial begin
        $sdf_annotate("../models/s27ks0641/s27ks0641.sdf", hyperram_model); 

        // Set all inputs at the beginning    
        trans_valid_i = 0;
        trans_address_i = 0;
        trans_cs_i = 0;
        trans_write_i = 0;
        trans_burst_i = 0;
        trans_address_space_i = 0;

        tx_valid_i = 0;
        tx_data_i = 0;
        tx_strb_i = 0;
        rx_ready_i = 0;

        // Will be applied on negedge of clock!
        cb_hyper_phy.rst_ni <= 0;
        // Will be applied 4ns after the clock!
        ##2 cb_hyper_phy.rst_ni <= 1;

        #150us; //Wait for RAM to initalize

        // stimuli.address_space = 1;

        testBasic();
        testWriteWithMask();
        testVariableLatency();
        testWithMultipleInterruptions();
        testLongTransaction();
        testDifferentBurstRead(); 
        

        ##100;
    end

    task testBasic();

        stimuli = new(32'h05FFF3, 16);
        stimuli.name("Basic functionality");
        stimuli.addInterruptHandshake(3, 5);

        doTransaction(stimuli);

        result.check(expectedResultAt05FFF3);
        result.printResult();
    
    endtask : testBasic

    task testWriteWithMask();

        stimuli = new(32'h0, 8);
        stimuli.name("Write data to RAM with some bytes masked");
        stimuli.write(writeData8, maskAll8);
        stimuli.addInterruptHandshake(5, 5);

        doTransaction(stimuli);

        //Read written data
        stimuli.isWrite = 0;

        doTransaction(stimuli);

        result.check(expectedResultWrite);
        result.printResult();

    endtask : testWriteWithMask

    task testVariableLatency();

        doConfig0Write(16'h8f17); // use variable latency

        stimuli = new(32'h05FFF3, 8);
        stimuli.name("Use variable latency");
        stimuli.addInterruptHandshake(3, 5);

        doTransaction(stimuli);

        result.check(expectedResultAt05FFF3);
        result.checkTimeOfFirstByte(100,120);
        result.printResult();

    endtask : testVariableLatency

    task testWithMultipleInterruptions();

        stimuli = new(32'h05FFF3, 16);
        stimuli.name("Test with multiple interruptions");
        stimuli.addInterruptHandshake(-1, 10);
        stimuli.addInterruptHandshake(3, 5);
        stimuli.addInterruptHandshake(8, 8);

        doTransaction(stimuli);

        result.check(expectedResultAt05FFF3);
        result.printResult();

    endtask : testWithMultipleInterruptions

    task testLongTransaction();
        automatic int expectedResult[64];

        stimuli = new(32'h0, 64);
        stimuli.name("Test a long(64 word) transaction");
        stimuli.write(writeData64, mask64);

        doTransaction(stimuli);

        //Read written data
        stimuli.isWrite = 0;

        doTransaction(stimuli);
        
        expectedResult = writeData64;
        expectedResult[14] = 16'h0f0f;
        expectedResult[43] = 16'h000b;

        result.check(expectedResult);
        result.printResult();

    endtask : testLongTransaction

    task testDifferentBurstRead();

        stimuli.name("Test reading with different burst lengths");

        //ToDo burst length of 1 not working
        for(int burst=2; burst < 48; burst++) begin
            stimuli = new(32'h3000, burst);

            doTransaction(stimuli);

            result.check(expectedResultSimple);
            result.printResult();
        end

    endtask : testDifferentBurstRead

    task doTransaction(transactionStimuli stimuli);
        static realtime starttime;

        result = new(stimuli.burst);

        cb_hyper_phy.trans_address_i <= stimuli.address;
        cb_hyper_phy.trans_burst_i <= stimuli.burst;
        cb_hyper_phy.trans_write_i <= stimuli.isWrite;
        cb_hyper_phy.trans_cs_i <= 2'b01;
        cb_hyper_phy.trans_address_space_i <= stimuli.address_space;

        cb_hyper_phy.trans_valid_i <= 1;
        wait(cb_hyper_phy.trans_ready_o);
        starttime = $time;
        cb_hyper_phy.trans_valid_i <= 0;
        wait(~cb_hyper_phy.trans_ready_o);

        if(stimuli.isWrite) begin
            writeData(stimuli);
        end else begin
            readData(stimuli, starttime);
        end

    endtask : doTransaction

    task readData(transactionStimuli stimuli, realtime starttime);

        //read data from phy
        cb_hyper_phy.rx_ready_i <= 1;
        wait(cb_hyper_phy.rx_valid_o);
        result.time_to_first_byte = $time - starttime;

        i = 0;
        while(i<stimuli.burst) begin

            //Simulate not ready to receive data
            if(stimuli.doInterrupt(i-1)) begin
                cb_hyper_phy.rx_ready_i <= 0;
                ##(2*stimuli.doInterrupt(i-1));
                cb_hyper_phy.rx_ready_i <= 1;
            end 

            // cb_hyper_phy.rx_ready_i <= 1;

            if(cb_hyper_phy.rx_valid_o) begin
                result.setReceivedData(i, cb_hyper_phy.rx_data_o);
                i++;
            end

            ##2; //One clock in clk0
        end

##6; //ToDo Get left data... Do not send more words than expected!

      cb_hyper_phy.rx_ready_i <= 0;
    
    endtask : readData

    task writeData(transactionStimuli stimuli);
      
        for(i = 0; i < stimuli.burst; i++) begin

            //Simulate not ready to receive data
            if(stimuli.doInterrupt(i-1)) begin
                cb_hyper_phy.tx_valid_i <= 0;
                ##(2*stimuli.doInterrupt(i-1));
                cb_hyper_phy.tx_valid_i <= 1;
            end 

            cb_hyper_phy.tx_data_i <= stimuli.writeData[i];
            cb_hyper_phy.tx_strb_i <= stimuli.writeMask[i];
            cb_hyper_phy.tx_valid_i <= 1'b1;
            wait(cb_hyper_phy.tx_ready_o);

            ##2; //Wait one cycle of clk0
        end
        cb_hyper_phy.tx_valid_i <= 1'b0;

    endtask : writeData

    task doConfig0Write(logic [15:0] data);
        stimuli = new(32'h800, 1);
        stimuli.write('{data}, '{2'b00});
        stimuli.address_space = 1;

        doTransaction(stimuli);

    endtask : doConfig0Write

  endprogram

endmodule
