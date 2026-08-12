class apb_slave_agent extends uvm_agent;
	`uvm_component_utils(apb_slave_agent)

	apb_slave_sqr 		slave_sqr;
	apb_slave_drv       slave_drv;
	apb_slave_mon       slave_mon;

	function new(string name = "apb_slave_agent", uvm_component parent);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		slave_sqr = apb_slave_sqr::type_id::create("slave_sqr", this);
		slave_drv = apb_slave_drv::type_id::create("slave_drv", this);
		slave_mon = apb_slave_mon::type_id::create("slave_mon", this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
		slave_drv.seq_item_port.connect(slave_sqr.seq_item_export);
	endfunction

endclass