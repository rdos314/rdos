module pcie_pipe_clock (

    //---------- Input -------------------------------------
    input             CLK_TXOUTCLK,
    input       [7:0] CLK_RXOUTCLK_IN,
    input             CLK_RST_N,
    input       [7:0] CLK_PCLK_SEL,
    input       [7:0] CLK_PCLK_SEL_SLAVE,
    input             CLK_GEN3,
    
    //---------- Output ------------------------------------
    output        CLK_PCLK,
    output        CLK_PCLK_SLAVE,
    output        CLK_RXUSRCLK,
    output  [7:0] CLK_RXOUTCLK_OUT,
    output        CLK_DCLK,
    output        CLK_OOBCLK,
    output        CLK_USERCLK1,
    output        CLK_USERCLK2,
    output        CLK_MMCM_LOCK
    
);

    //---------- Select Clock Divider ----------------------
    localparam          DIVCLK_DIVIDE    = 1;
    localparam          CLKFBOUT_MULT_F  = 10;
    localparam          CLKIN1_PERIOD    = 10;                                               
    localparam          CLKOUT0_DIVIDE_F = 8;
    localparam          CLKOUT1_DIVIDE   = 4;
    localparam          CLKOUT2_DIVIDE   = 2;
    localparam          CLKOUT3_DIVIDE   = 4;
    localparam          CLKOUT4_DIVIDE   = 20;

    localparam          PCIE_GEN1_MODE    = 1'b0;             // PCIe link speed is GEN1 only

    //---------- Input Registers ---------------------------

(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg         [7:0] pclk_sel_reg1 = {8{1'd0}};
(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg         [7:0] pclk_sel_slave_reg1 = {8{1'd0}};
(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg                         gen3_reg1     = 1'd0;
    
(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg         [7:0] pclk_sel_reg2 = {8{1'd0}};
(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg         [7:0] pclk_sel_slave_reg2 = {8{1'd0}};
(* ASYNC_REG = "TRUE", SHIFT_EXTRACT = "NO" *)    reg                         gen3_reg2     = 1'd0;   
                                           
    //---------- Internal Signals -------------------------- 
    wire   refclk;
    wire   mmcm_fb;
    wire   clk_125mhz;
    wire   clk_125mhz_buf;
    wire   clk_250mhz;
    wire   userclk1;
    wire   userclk2;
    wire   oobclk;
    reg    pclk_sel = 1'd0;
    reg    pclk_sel_slave = 1'd0;

    //---------- Output Registers --------------------------
    wire   pclk_1;
    wire   pclk;
    wire   userclk1_1;
    wire   userclk2_1;
    wire   mmcm_lock;
    
    //---------- Generate Per-Lane Signals -----------------
    genvar              i;                                  // Index for per-lane signals


//---------- Input FF ----------------------------------------------------------
always @ (posedge pclk)
begin

    if (!CLK_RST_N)
        begin
        //---------- 1st Stage FF --------------------------
        pclk_sel_reg1 <= {8{1'd0}};
        pclk_sel_slave_reg1 <= {8{1'd0}};
        gen3_reg1     <= 1'd0;
        //---------- 2nd Stage FF --------------------------
        pclk_sel_reg2 <= {8{1'd0}};
        pclk_sel_slave_reg2 <= {8{1'd0}};
        gen3_reg2     <= 1'd0;
        end
    else
        begin  
        //---------- 1st Stage FF --------------------------
        pclk_sel_reg1 <= CLK_PCLK_SEL;
        pclk_sel_slave_reg1 <= CLK_PCLK_SEL_SLAVE;
        gen3_reg1     <= CLK_GEN3;
        //---------- 2nd Stage FF --------------------------
        pclk_sel_reg2 <= pclk_sel_reg1;
        pclk_sel_slave_reg2 <= pclk_sel_slave_reg1;
        gen3_reg2     <= gen3_reg1;
        end
        
end
   
//---------- Select Reference clock or TXOUTCLK --------------------------------   
generate 
    begin : txoutclk_i
    
    //---------- Select TXOUTCLK -----------------------------------------------
    BUFG txoutclk_i
    (    
        //---------- Input -------------------------------------
        .I                          (CLK_TXOUTCLK),
        //---------- Output ------------------------------------
        .O                          (refclk)  
    );
   
    end

endgenerate



//---------- MMCM --------------------------------------------------------------
MMCME2_ADV #
(

    .BANDWIDTH                  ("OPTIMIZED"),
    .CLKOUT4_CASCADE            ("FALSE"),
    .COMPENSATION               ("ZHOLD"),
    .STARTUP_WAIT               ("FALSE"),
    .DIVCLK_DIVIDE              (1),
    .CLKFBOUT_MULT_F            (10),                // 1000MHz
    .CLKFBOUT_PHASE             (0.000),
    .CLKFBOUT_USE_FINE_PS       ("FALSE"),
    .CLKOUT0_DIVIDE_F           (8),                // 125 MHz   
    .CLKOUT0_PHASE              (0.000),
    .CLKOUT0_DUTY_CYCLE         (0.500),
    .CLKOUT0_USE_FINE_PS        ("FALSE"),
    .CLKOUT1_DIVIDE             (4),                // 250 MHz    
    .CLKOUT1_PHASE              (0.000),
    .CLKOUT1_DUTY_CYCLE         (0.500),
    .CLKOUT1_USE_FINE_PS        ("FALSE"),
    .CLKOUT2_DIVIDE             (2),                 // 500 MHz 
    .CLKOUT2_PHASE              (0.000),
    .CLKOUT2_DUTY_CYCLE         (0.500),
    .CLKOUT2_USE_FINE_PS        ("FALSE"),
    .CLKOUT3_DIVIDE             (4),                 // 250 MHz 
    .CLKOUT3_PHASE              (0.000),
    .CLKOUT3_DUTY_CYCLE         (0.500),
    .CLKOUT3_USE_FINE_PS        ("FALSE"),
    .CLKOUT4_DIVIDE             (20),                // 50 MHz  
    .CLKOUT4_PHASE              (0.000),
    .CLKOUT4_DUTY_CYCLE         (0.500),
    .CLKOUT4_USE_FINE_PS        ("FALSE"),
    .CLKIN1_PERIOD              (10),                // 100Mhz
    .REF_JITTER1                (0.010)
    
)
mmcm_i
(

     //---------- Input ------------------------------------
    .CLKIN1                     (refclk),
    .CLKIN2                     (1'd0),                     // not used, comment out CLKIN2 if it cause implementation issues
  //.CLKIN2                     (refclk),                   // not used, comment out CLKIN2 if it cause implementation issues
    .CLKINSEL                   (1'd1),
    .CLKFBIN                    (mmcm_fb),
    .RST                        (!CLK_RST_N),
    .PWRDWN                     (1'd0), 
    
    //---------- Output ------------------------------------
    .CLKFBOUT                   (mmcm_fb),
    .CLKFBOUTB                  (),
    .CLKOUT0                    (clk_125mhz),   // 125 MHz
    .CLKOUT0B                   (),
    .CLKOUT1                    (clk_250mhz),   // 250 MHz
    .CLKOUT1B                   (),
    .CLKOUT2                    (userclk1),     // 500 MHz
    .CLKOUT2B                   (),
    .CLKOUT3                    (userclk2),     // 250 MHz
    .CLKOUT3B                   (),
    .CLKOUT4                    (oobclk),       // 50 MHz
    .CLKOUT5                    (),
    .CLKOUT6                    (),
    .LOCKED                     (mmcm_lock),
    
    //---------- Dynamic Reconfiguration -------------------
    .DCLK                       ( 1'd0),
    .DADDR                      ( 7'd0),
    .DEN                        ( 1'd0),
    .DWE                        ( 1'd0),
    .DI                         (16'd0),
    .DO                         (),
    .DRDY                       (),
    
    //---------- Dynamic Phase Shift -----------------------
    .PSCLK                      (1'd0),
    .PSEN                       (1'd0),
    .PSINCDEC                   (1'd0),
    .PSDONE                     (),
    
    //---------- Status ------------------------------------
    .CLKINSTOPPED               (),
    .CLKFBSTOPPED               ()  

); 
  


//---------- Select PCLK MUX ---------------------------------------------------
generate  
    begin : pclk_i1_bufgctrl
    //---------- PCLK Mux ----------------------------------
    BUFGCTRL pclk_i1
    (
        //---------- Input ---------------------------------
        .CE0                        (1'd1),         
        .CE1                        (1'd1),        
        .I0                         (clk_125mhz),   
        .I1                         (clk_250mhz),   
        .IGNORE0                    (1'd0),        
        .IGNORE1                    (1'd0),        
        .S0                         (~pclk_sel),    
        .S1                         ( pclk_sel),    
        //---------- Output --------------------------------
        .O                          (pclk_1)
    );
    end
endgenerate

//---------- Select PCLK MUX for Slave---------------------------------------------------
generate  
   //---------- PCLK MUX for Slave------------------// 
    begin : pclk_slave_disable
    assign CLK_PCLK_SLAVE = 1'b0;
    end  

endgenerate



//---------- Generate RXOUTCLK Buffer for Debug --------------------------------
generate 
    //---------- Disable RXOUTCLK Buffer for Normal Operation 
    begin : rxoutclk_i_disable
    assign CLK_RXOUTCLK_OUT = {8{1'd0}};
    end       
            
endgenerate 


generate 

    begin : dclk_i_bufg
    //---------- DCLK Buffer -------------------------------
    BUFG dclk_i
    (
        //---------- Input ---------------------------------
        .I                          (clk_125mhz),
        //---------- Output --------------------------------
        .O                          (CLK_DCLK)
    );
    end

endgenerate




//---------- Generate USERCLK1 Buffer ------------------------------------------
generate 
    begin : userclk1_i1
    //---------- USERCLK1 Buffer ---------------------------
    BUFG usrclk1_i1
    (
        //---------- Input ---------------------------------
        .I                          (userclk1),
        //---------- Output --------------------------------
        .O                          (userclk1_1)
    );
    end 
endgenerate 



//---------- Generate USERCLK2 Buffer ------------------------------------------

generate 
    begin : userclk2_i1
    //---------- USERCLK2 Buffer ---------------------------
    BUFG usrclk2_i1
    (
        //---------- Input ---------------------------------
        .I                          (userclk2),
        //---------- Output --------------------------------
        .O                          (userclk2_1)
    );
    end
endgenerate 

//---------- Generate OOBCLK Buffer --------------------------------------------
generate         
    //---------- Disable OOBCLK Buffer ---------------------
    begin : oobclk_i1_disable
    assign CLK_OOBCLK = pclk;
    end  

endgenerate 


// Disabled Second Stage Buffers
    assign pclk         = pclk_1;
    assign CLK_RXUSRCLK = pclk_1;
    assign CLK_USERCLK1 = userclk1_1;
    assign CLK_USERCLK2 = userclk2_1;
 

//---------- Select PCLK -------------------------------------------------------
always @ (posedge pclk)
begin

    if (!CLK_RST_N)
        pclk_sel <= 1'd0;
    else
        begin 
        //---------- Select 250 MHz ------------------------
        if (&pclk_sel_reg2)
            pclk_sel <= 1'd1;
        //---------- Select 125 MHz ------------------------  
        else if (&(~pclk_sel_reg2))
            pclk_sel <= 1'd0;  
        //---------- Hold PCLK -----------------------------
        else
            pclk_sel <= pclk_sel;
        end

end        

always @ (posedge pclk)
begin

    if (!CLK_RST_N)
        pclk_sel_slave<= 1'd0;
    else
        begin 
        //---------- Select 250 MHz ------------------------
        if (&pclk_sel_slave_reg2)
            pclk_sel_slave <= 1'd1;
        //---------- Select 125 MHz ------------------------  
        else if (&(~pclk_sel_slave_reg2))
            pclk_sel_slave <= 1'd0;  
        //---------- Hold PCLK -----------------------------
        else
            pclk_sel_slave <= pclk_sel_slave;
        end

end     



//---------- PIPE Clock Output -------------------------------------------------
assign CLK_PCLK      = pclk;
assign CLK_MMCM_LOCK = mmcm_lock;


endmodule
