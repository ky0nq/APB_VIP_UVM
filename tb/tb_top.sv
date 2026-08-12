`timescale 1ns/1ps

module tb_top;

	import uvm_pkg::*;

	`include "uvm_macros.svh"


	logic PCLK;
	logic PRESETn;


	// -----------------------------------------
	// Interface
	// -----------------------------------------
	apb_if apb_vif (
		.PCLK    (PCLK),
		.PRESETn (PRESETn)
	);


	// -----------------------------------------
	// Clock
	// 100 MHz
	// -----------------------------------------
	initial begin

		PCLK = 1'b0;

		forever begin
			#5 PCLK = ~PCLK;
		end

	end


	// -----------------------------------------
	// Reset
	// -----------------------------------------
	initial begin

		PRESETn = 1'b0;

		repeat(5) begin
			@(posedge PCLK);
		end

		PRESETn = 1'b1;

	end


	// -----------------------------------------
	// UVM
	// -----------------------------------------
	initial begin

		uvm_config_db#(virtual apb_if)::set(
			null,
			"*",
			"apb_vif",
			apb_vif
		);

		run_test("apb_test");

	end

	initial begin
		$fsdbDumpfile("wave.fsdb");
		$fsdbDumpvars(0, tb_top);
	end
endmodule
