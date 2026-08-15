import uvm_pkg::*;
import apb_pkg::*;

module tb_top;

	logic PCLK;
	logic PRESETn;

	// clock generate
	initial PCLK = 0;
	always #5 PCLK = ~PCLK;

	// interface instance
	apb_if apb_vif (
		.PCLK    (PCLK),
		.PRESETn (PRESETn)
	);

	// ======================
	// dut place
	// ======================
	
	initial begin
		PRESETn = 1'b0;
		repeat(5) @(posedge PCLK);
		PRESETn = 1'b1;
	end

	initial begin
		uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", apb_vif);
		run_test("apb_test");
	end

	initial begin
		$fsdbDumpfile("wave.fsdb");
		$fsdbDumpvars(0);
		$fsdbDumpMDA();
	end
endmodule
