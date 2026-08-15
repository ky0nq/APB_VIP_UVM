class apb_base_seq extends uvm_sequence;
	`uvm_object_utils(apb_base_seq)	
	`uvm_declare_p_sequencer(apb_sequencer)

	int unsigned num;	

	function new(string name = "apb_base_seq");
		super.new(name);
	endfunction

	virtual	task body();
		apb_seq_item 		top_item;
		apb_seq_item        master_item;
        apb_seq_item        slave_item;

		apb_master_seq 	master_seq;
		apb_slave_seq 	slave_seq;
		
		`uvm_info(get_type_name(), $sformatf("Random Scenario Start (%0d repeat)", num), UVM_LOW)

		repeat(num) begin
			top_item = apb_seq_item::type_id::create("top_item");
			master_item = apb_seq_item::type_id::create("master_item");
			slave_item = apb_seq_item::type_id::create("slave_item");

			if (!top_item.randomize()) begin
				`uvm_fatal(get_type_name(), $sformatf("Item Randomization Failed!"))
			end		
	
			master_seq 	= apb_master_seq::type_id::create("apb_master_seq");
			slave_seq 	= apb_slave_seq::type_id::create("apb_slave_seq");

			master_item.copy(top_item);
            slave_item.copy(top_item);
			master_seq.item = master_item;
			slave_seq.item 	= slave_item;		
			
			fork
				master_seq.start(p_sequencer.master_sqr);
				slave_seq.start(p_sequencer.slave_sqr);
			join
		end
	endtask		

endclass
