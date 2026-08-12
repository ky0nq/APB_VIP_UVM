class apb_master_agent extends uvm_agent;
	`uvm_component_utils(apb_master_agent)

	apb_master_sqr 		 master_sqr;
	apb_master_drv       master_drv;
	apb_master_mon       master_mon;

	function new(string name = "apb_master_agent", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		master_sqr = apb_master_sqr::type_id::create("master_sqr", this);
		master_drv = apb_master_drv::type_id::create("master_drv", this);
		master_mon = apb_master_mon::type_id::create("master_mon", this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		master_drv.seq_item_port.connect(master_sqr.seq_item_export);
	endfunction

endclass