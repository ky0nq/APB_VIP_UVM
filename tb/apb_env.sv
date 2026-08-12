class apb_env extends uvm_env;

	`uvm_component_utils(apb_env)

	apb_master_agent master_agent;
	apb_slave_agent  slave_agent;

	apb_sequencer    apb_sqr;

	apb_scoreboard   scoreboard;


	function new(
		string name = "apb_env",
		uvm_component parent = null
	);
		super.new(name, parent);
	endfunction


	function void build_phase(uvm_phase phase);
		super.build_phase(phase);


		master_agent =
			apb_master_agent::type_id::create(
				"master_agent",
				this
			);


		slave_agent =
			apb_slave_agent::type_id::create(
				"slave_agent",
				this
			);


		apb_sqr =
			apb_sequencer::type_id::create(
				"apb_sqr",
				this
			);


		scoreboard =
			apb_scoreboard::type_id::create(
				"scoreboard",
				this
			);

	endfunction


	function void connect_phase(uvm_phase phase);
		super.connect_phase(phase);


		// -----------------------------------------
		// Virtual Sequencer
		// -----------------------------------------
		apb_sqr.apb_master_sqr =
			master_agent.master_sqr;

		apb_sqr.apb_slave_sqr =
			slave_agent.slave_sqr;


		// -----------------------------------------
		// Master Monitor -> Scoreboard
		// -----------------------------------------
		master_agent.master_mon.master_ap.connect(
			scoreboard.master_imp
		);


		// -----------------------------------------
		// Slave Monitor -> Scoreboard
		// -----------------------------------------
		slave_agent.slave_mon.slave_ap.connect(
			scoreboard.slave_imp
		);

	endfunction

endclass