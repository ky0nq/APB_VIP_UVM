class apb_env extends uvm_env;
	`uvm_component_utils(apb_env)

	apb_master_agent master_agt;
	apb_slave_agent  slave_agt;
	apb_sequencer    apb_sqr;
	apb_scoreboard   scb;

	function new(string name = "apb_env", uvm_component parent);
		super.new(name, parent);
	endfunction


	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		master_agt = apb_master_agent::type_id::create("master_agt", this);
		slave_agt = apb_slave_agent::type_id::create("slave_agt", this);
		apb_sqr = apb_sequencer::type_id::create("apb_sqr",	this);
		scb = apb_scoreboard::type_id::create("scb", this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);

		apb_sqr.master_sqr = master_agt.master_sqr;
		apb_sqr.slave_sqr  = slave_agt.slave_sqr;;

		master_agt.master_mon.master_ap.connect(scb.master_imp);
		slave_agt.slave_mon.slave_ap.connect(scb.slave_imp);
	endfunction

endclass
