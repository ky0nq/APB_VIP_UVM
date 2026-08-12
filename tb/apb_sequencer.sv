class apb_sequencer extends uvm_sequencer;
	`uvm_component_utils(apb_sequencer)
	
	apb_master_sqr apb_master_sqr;
	apb_slave_sqr  apb_slave_sqr;

	function new(string name="apb_sequencer", uvm_component parent);
		super.new(name, parent);
	endfunction

endclass 
