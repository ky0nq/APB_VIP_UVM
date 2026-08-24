import uvm_pkg::*;
import apb_pkg::*;

module tb_top;

	logic PCLK;
	logic PRESETn;

	// clock generate
	initial PCLK = 0;
	always #5 PCLK = ~PCLK;

	// interface instance
	apb_if U_APB_VIF (
		.PCLK    (PCLK),
		.PRESETn (PRESETn)
	);

	apb_assertions U_APB_ASSERTIONS (
		.PCLK    (PCLK),
		.PRESETn (PRESETn),
		.PSEL    (U_APB_VIF.PSEL),
		.PENABLE (U_APB_VIF.PENABLE),
		.PREADY  (U_APB_VIF.PREADY)
	);

	// =============================
	// dut place
	// =============================

	initial begin
		PRESETn = 1'b0;
		repeat(5) @(posedge PCLK);
		PRESETn = 1'b1;
	end

	initial begin
		uvm_config_db#(virtual apb_if)::set(null, "*", "apb_vif", U_APB_VIF);
		run_test("apb_test");
	end

	initial begin
		$fsdbDumpfile("wave.fsdb");
		$fsdbDumpvars(0);
		$fsdbDumpMDA();
	end
endmodule