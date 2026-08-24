class apb_master_drv extends uvm_driver #(apb_seq_item);
	`uvm_component_utils(apb_master_drv)
	virtual apb_if apb_vif;
	
	function new(string name="apb_master_drv", uvm_component parent);
		super.new(name, parent);
	endfunction 


	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif)) begin
			`uvm_fatal(get_type_name(), "No find Virtual Interface(vif) in config_db")
		end
	endfunction 

	virtual task init_master();
		@(apb_vif.master_cb);

		// IDLE State
		apb_vif.master_cb.PSEL    <= 1'b0;
		apb_vif.master_cb.PENABLE <= 1'b0;
		apb_vif.master_cb.PADDR   <= 32'b0;
		apb_vif.master_cb.PWDATA  <= 32'b0;
		apb_vif.master_cb.PWRITE  <= 1'b0;
		apb_vif.master_cb.PSTRB   <= 4'b0;
		apb_vif.master_cb.PPROT   <= 3'b0;

		wait (apb_vif.PRESETn === 1'b1);
	endtask

	virtual task drive_setup(apb_seq_item item);
		apb_vif.master_cb.PADDR <= item.PADDR;

		if (item.PWRITE == 1'b0) begin
			apb_vif.master_cb.PWDATA <= item.PWDATA;
		end
		else begin
			apb_vif.master_cb.PWDATA <= 32'b0;
		end

		apb_vif.master_cb.PWRITE  <= item.PWRITE;
		apb_vif.master_cb.PSTRB   <= item.PSTRB;
		apb_vif.master_cb.PPROT   <= item.PPROT;
		apb_vif.master_cb.PSEL    <= 1'b1;
		apb_vif.master_cb.PENABLE <= 1'b0;

		`uvm_info(get_type_name(), $sformatf("SETUP: PADDR=%08h PWRITE=%0b PWDATA=%08h", item.PADDR, item.PWRITE, item.PWDATA), UVM_HIGH)
	endtask

	virtual task drive_access(apb_seq_item item);
		@(apb_vif.master_cb);
		apb_vif.master_cb.PENABLE <= 1'b1;

		`uvm_info(get_type_name(), "ACCESS phase Start", UVM_HIGH)
		// PREADY Waiting
		do begin
			@(apb_vif.master_cb);
		end while (apb_vif.master_cb.PREADY !== 1'b1);

		// Slave Response Saving
		item.PREADY  = apb_vif.master_cb.PREADY;
		item.PSLVERR = apb_vif.master_cb.PSLVERR;
		
		if (item.PWRITE == 1'b0) begin
			item.PRDATA = apb_vif.master_cb.PRDATA;
		end

		`uvm_info(get_type_name(), $sformatf("ACCESS completed! : PRDATA=%08h PREADY=%0b PSLVERR=%0b", item.PRDATA, item.PREADY, item.PSLVERR), UVM_HIGH)
	endtask

	// NORMAL Scenario
	virtual task drive_normal(apb_seq_item item);
		// SETUP State
		drive_setup(item);
		// ACCESS State
		drive_access(item);
	endtask

	// ======================================================================
	// PENABLE ONLY Negative Scenario 
	// ======================================================================
	virtual task drive_penable_only(apb_seq_item item);

		// Invalid State
		// PSEL = 0, PENABLE = 1
		apb_vif.master_cb.PSEL    <= 1'b0;
		apb_vif.master_cb.PENABLE <= 1'b1;

		`uvm_info(get_type_name(), "PENABLE ONLY Scenario Start : PSEL=0, PENABLE=1", UVM_HIGH)

		// Invalid State 5 Cycle 
		repeat (5) begin
			@(apb_vif.master_cb);
		end

		// IDLE State
		apb_vif.master_cb.PSEL    <= 1'b0;
		apb_vif.master_cb.PENABLE <= 1'b0;

		`uvm_info(get_type_name(), "PENABLE ONLY Scenario End -> IDLE", UVM_HIGH)
	endtask

	// ======================================================================
	// PSEL DROP Negative Scenario
	// ======================================================================
	virtual task drive_psel_drop(apb_seq_item item);

		// SETUP State
		apb_vif.master_cb.PADDR   <= item.PADDR;
		apb_vif.master_cb.PWDATA  <= item.PWDATA;
		apb_vif.master_cb.PWRITE  <= item.PWRITE;
		apb_vif.master_cb.PSTRB   <= item.PSTRB;
		apb_vif.master_cb.PPROT   <= item.PPROT;
		apb_vif.master_cb.PSEL    <= 1'b1;
		apb_vif.master_cb.PENABLE <= 1'b0;

		@(apb_vif.master_cb);

		// ACCESS State
		apb_vif.master_cb.PENABLE <= 1'b1;

		do begin
			@(apb_vif.master_cb);
		end while (apb_vif.master_cb.PREADY !== 1'b0);

		// Protocol Violation
		// ACCESS Waiting ->  PSEL Drop
		apb_vif.master_cb.PSEL <= 1'b0;

		`uvm_info(get_type_name(), "PSEL DROP Scenario : PSEL dropped during ACCESS wait", UVM_HIGH)

		@(apb_vif.master_cb);

		// IDLE Return
		apb_vif.master_cb.PSEL    <= 1'b0;
		apb_vif.master_cb.PENABLE <= 1'b0;
	endtask

	virtual task next_transaction(ref apb_seq_item c_item, ref apb_seq_item n_item);
		n_item = null;

		// Back-to-Back Process
		if (c_item.b2b == 1'b1) begin
			seq_item_port.try_next_item(n_item);
		end

		if (n_item != null) begin
			c_item = n_item;
			`uvm_info(get_type_name(), "Next Transaction Load : Back-to-Back", UVM_HIGH)
		end
		else begin
			apb_vif.master_cb.PSEL    <= 1'b0;
			apb_vif.master_cb.PENABLE <= 1'b0;

			`uvm_info(get_type_name(), "Transition to IDLE state", UVM_HIGH)
			repeat(c_item.idle_cycles) begin
				@(apb_vif.master_cb);
			end

			// Next Transaction Load
			seq_item_port.get_next_item(c_item);
			@(apb_vif.master_cb);
		end
	endtask

	virtual task run_phase(uvm_phase phase);
		apb_seq_item c_item;
		apb_seq_item n_item;

		// Master Initial Setting
		init_master();

		// First Transaction
		seq_item_port.get_next_item(c_item);
		@(apb_vif.master_cb);
		forever begin

			case (c_item.scenario)
				apb_seq_item::APB_NORMAL: begin
					drive_normal(c_item);
					`uvm_info(get_type_name(),$sformatf("Execution : %s", c_item.convert2string()), UVM_HIGH)
				end 
				apb_seq_item::APB_PENABLE_ONLY: begin
					drive_penable_only(c_item);
				end
				apb_seq_item::APB_PSEL_DROP: begin
					drive_psel_drop(c_item);
				end

				default: begin
					`uvm_error(get_type_name(), "Unknown APB Scenario")
				end
			endcase

			seq_item_port.item_done();
			next_transaction(c_item, n_item);
		end
	endtask

endclass
