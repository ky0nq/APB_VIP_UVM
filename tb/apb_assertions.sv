module apb_assertions (
	input logic PCLK,
	input logic PRESETn,
	input logic PSEL,
	input logic PENABLE,
	input logic PREADY
);

	// Monitor APB interface signals and check protocol rules

	// ==================================================
	// PENABLE ONLY
	// ==================================================
	property p_penable_only_no_pready;
		@(posedge PCLK)
		disable iff (!PRESETn)

		(!PSEL && PENABLE) |-> !PREADY;
	endproperty

	a_penable_only_no_pready:
	assert property (p_penable_only_no_pready)
	else
		$error("PENABLE ONLY ERROR : PREADY asserted");

	c_penable_only:
	cover property (
		@(posedge PCLK)
		disable iff (!PRESETn)

		(!PSEL && PENABLE)
	);


	// ==================================================
	// PSEL DROP
	// ==================================================
	property p_psel_hold_during_wait;
		@(posedge PCLK)
		disable iff (!PRESETn)

		(PSEL && PENABLE && !PREADY)
		|=> PSEL;
	endproperty

	a_psel_hold_during_wait:
	assert property (p_psel_hold_during_wait)
	else
		$error("PSEL DROP ERROR : PSEL dropped during ACCESS wait");

	c_psel_drop:
	cover property (
		@(posedge PCLK)
		disable iff (!PRESETn)

		(PSEL && PENABLE && !PREADY)
		##1
		(!PSEL && PENABLE)
	);

endmodule
