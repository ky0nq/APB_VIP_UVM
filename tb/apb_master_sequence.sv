class apb_master_seq extends uvm_sequence #(apb_seq_item);
	`uvm_object_utils(apb_master_seq)

	apb_seq_item item;

	function new(string name = "apb_master_seq");
		super.new(name);
	endfunction 

	virtual task body();
		start_item(item);
		finish_item(item);	
	endtask

endclass
