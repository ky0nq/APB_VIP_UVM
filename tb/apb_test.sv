class apb_test extends uvm_test;

	`uvm_component_utils(apb_test)

	apb_env env;


	function new(
		string name = "apb_test",
		uvm_component parent = null
	);
		super.new(name, parent);
	endfunction


	function void build_phase(uvm_phase phase);
		super.build_phase(phase);

		env = apb_env::type_id::create(
			"env",
			this
		);

	endfunction


	virtual task run_phase(uvm_phase phase);

		apb_base_seq base_seq;


		phase.raise_objection(this);


		base_seq =
			apb_base_seq::type_id::create(
				"base_seq"
			);


		base_seq.num = 20;


		base_seq.start(
			env.apb_sqr
		);


		phase.drop_objection(this);

	endtask

endclass