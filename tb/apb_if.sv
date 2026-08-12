interface apb_if ( 
	input logic PCLK,
	input logic PRESETn
);

	// master to slave
	logic PSEL;
	logic PENABLE;	
	logic PWRITE;
	logic [31:0] PADDR;
	logic [31:0] PWDATA;
	logic [3:0] PSTRB;
	logic [2:0] PPROT;

	// slave to master
	logic [31:0] PRDATA;
	logic PREADY;
	logic PSLVERR;

	// Master Driver
    clocking master_cb @(posedge PCLK);
        default input #1step output #0;

        output PADDR;
        output PSEL;
        output PENABLE;
        output PWRITE;
        output PWDATA;
        output PSTRB;
        output PPROT;

        input  PRDATA;
        input  PREADY;
        input  PSLVERR;
    endclocking


    // Slave Driver
    clocking slave_cb @(posedge PCLK);
        default input #1step output #0;

        input  PADDR;
        input  PSEL;
        input  PENABLE;
        input  PWRITE;
        input  PWDATA;
        input  PSTRB;
        input  PPROT;

        output PRDATA;
        output PREADY;
        output PSLVERR;
    endclocking


    // Monitoring
    clocking monitor_cb @(posedge PCLK);
        default input #1step;

        input PADDR;
        input PSEL;
        input PENABLE;
        input PWRITE;
        input PWDATA;
        input PSTRB;
        input PPROT;

        input PRDATA;
        input PREADY;
        input PSLVERR;
    endclocking

endinterface
