class apb_base_test extends uvm_test;
	`uvm_component_utils(apb_base_test)
	apb_env env;

	function new(string name = "apb_base_test", uvm_component parent = null);
		super.new(name, parent);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		env = apb_env::type_id::create("env", this);
	endfunction

	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);
	endfunction

	function void end_of_elaboration_phase(uvm_phase phase);
		super.end_of_elaboration_phase(phase);
		uvm_top.print_topology();
	endfunction
endclass

class apb_basic_test extends apb_base_test;
	`uvm_component_utils(apb_basic_test)

	function new(string name="apb_basic_test", uvm_component parent);
		super.new(name, parent);
	endfunction

	virtual task run_phase(uvm_phase phase);
		apb_base_seq seq;

		phase.raise_objection(this);
		seq = apb_base_seq::type_id::create("seq");
		if (!seq.randomize())
			`uvm_error("TEST", "Seq Randomize Fail!!");
		seq.num = 20;
		seq.start(env.apb_sqr);

		#100; // delay for stable state
		phase.drop_objection(this);

	endtask
endclass
