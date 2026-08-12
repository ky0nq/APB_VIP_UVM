class apb_master_sqr extends uvm_sequencer #(apb_seq_item);
	`uvm_component_utils(apb_master_sqr)

	function new(string name="apb_master_sqr", uvm_component parent);
		super.new(name, parent);	
	endfunction

endclass
