class apb_seq_item extends uvm_sequence_item;
	typedef enum {
		APB_NORMAL,
		APB_PENABLE_ONLY
	} apb_scenario_e;
	apb_scenario_e scenario = APB_NORMAL;

	rand bit [31:0] PADDR;
	rand bit [31:0] PWDATA;
	rand bit PWRITE;
	rand bit [3:0] PSTRB;	// write byte enable signal 
	rand bit [31:0] PRDATA;	// read operation checking 

	bit PSEL;
	bit PENABLE;
	bit [2:0] PPROT;
	bit PREADY;
	bit PSLVERR;

	// ACCESS -> SETUP state transition
	rand bit b2b;
	rand int unsigned idle_cycles;

	constraint c_b2b {
		b2b dist {
			1'b1 := 70,
			1'b0 := 30
		};	
	}

	constraint c_idle_cycles {
		if (b2b == 1'b1)
			idle_cycles == 0;
		else 
			idle_cycles inside {[1:5]};
	}
	
	`uvm_object_utils_begin(apb_seq_item)
		`uvm_field_enum(apb_scenario_e, scenario, UVM_ALL_ON)
		`uvm_field_int(PADDR,UVM_ALL_ON)
		`uvm_field_int(PWDATA,UVM_ALL_ON)
		`uvm_field_int(PWRITE,UVM_ALL_ON)
		`uvm_field_int(PSTRB,UVM_ALL_ON)
		`uvm_field_int(PSEL,UVM_ALL_ON)
		`uvm_field_int(PENABLE,UVM_ALL_ON)
		`uvm_field_int(PPROT,UVM_ALL_ON)
		`uvm_field_int(PRDATA,UVM_ALL_ON)
		`uvm_field_int(PREADY,UVM_ALL_ON)
		`uvm_field_int(PSLVERR,UVM_ALL_ON)

		`uvm_field_int(b2b,UVM_ALL_ON)
		`uvm_field_int(idle_cycles,UVM_ALL_ON)
	`uvm_object_utils_end

	function new(string name = "apb_seq_item");
		super.new(name);
	endfunction 
	
	function string convert2string();
		if (PWRITE)
			return $sformatf("[write] waddr = 0x%02h , wdata = 0x%02h, strb = 0x%01h", PADDR, PWDATA, PSTRB);
		else 	
			return $sformatf("[read] raddr = 0x%02h , rdata = 0x%02h", PADDR, PRDATA);
	endfunction 	

endclass
