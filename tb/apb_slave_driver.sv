class apb_slave_drv extends uvm_driver #(apb_seq_item);
	`uvm_component_utils(apb_slave_drv)

	virtual apb_if apb_vif;
	
	function new(string name="apb_slave_drv", uvm_component parent);
		super.new(name, parent);
	endfunction 

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual apb_if)::get(this,"","apb_vif",apb_vif)) begin
			`uvm_fatal(get_type_name(), "No find Virtual Interface(vif) in config_db")
		end
	endfunction 
	
	virtual task run_phase(uvm_phase phase);
		apb_seq_item item;
		int unsigned waiting_ready;
		bit addr_error; 		// PSLVERR signal test

		@(apb_vif.slave_cb);

		apb_vif.slave_cb.PRDATA  <= 32'b0;
		apb_vif.slave_cb.PREADY  <= 1'b0;
		apb_vif.slave_cb.PSLVERR <= 1'b0;
		
		wait (apb_vif.PRESETn === 1'b1);

		forever begin
			// IDLE State
			apb_vif.slave_cb.PREADY <= 1'b0;
			apb_vif.slave_cb.PSLVERR <= 1'b0;

			seq_item_port.get_next_item(item);

			// SETUP State
			do begin
				@(apb_vif.slave_cb);
			end while (!(apb_vif.slave_cb.PSEL == 1'b1 && apb_vif.slave_cb.PENABLE == 1'b0));
			`uvm_info(get_type_name(), $sformatf("SETUP detected: PADDR=%08h PWRITE=%0b PWDATA=%08h", apb_vif.slave_cb.PADDR, apb_vif.slave_cb.PWRITE, apb_vif.slave_cb.PWDATA), UVM_HIGH)

			// Address Access Check
			if (apb_vif.slave_cb.PADDR > 32'h8FFF_FFFF) 	// Not Permitted Region
				addr_error = 1'b1;
			else
				addr_error = 1'b0;

			// ACCESS State
			if (apb_vif.slave_cb.PWRITE == 1'b0) begin
				apb_vif.slave_cb.PRDATA <= item.PRDATA;
			end
			else begin
				apb_vif.slave_cb.PRDATA <= 32'b0;
			end
			apb_vif.slave_cb.PSLVERR <= 1'b0;
			apb_vif.slave_cb.PREADY  <= 1'b0;

			if (item.scenario == apb_seq_item::APB_PSEL_DROP) begin
				waiting_ready = 3;
			end
			else begin
				if (!std::randomize(waiting_ready) with {
					waiting_ready inside {[0:5]};
				}) begin
					`uvm_fatal(get_type_name(), "Ready Assign Cycle Randomization Failed!")
				end
			end
			// waiting not exists. already setting.
			if (waiting_ready == 0) begin
				apb_vif.slave_cb.PREADY <= 1'b1;
				apb_vif.slave_cb.PSLVERR <= addr_error;

				// Master PSEL & PENABLE signal waiting
				do begin
					@(apb_vif.slave_cb);
				end while (!(apb_vif.slave_cb.PSEL == 1'b1 && apb_vif.slave_cb.PENABLE == 1'b1));
			end
			else begin
				apb_vif.slave_cb.PREADY <= 1'b0;

				// Master PSEL & PENABLE signal waiting
				do begin
					@(apb_vif.slave_cb);
				end while (!(apb_vif.slave_cb.PSEL == 1'b1 && apb_vif.slave_cb.PENABLE == 1'b1));

				repeat (waiting_ready-1) begin	
					@(apb_vif.slave_cb);
				end

				// PREADY is asserted only while ACCESS state is still valid
				if (apb_vif.slave_cb.PSEL == 1'b1 &&
					apb_vif.slave_cb.PENABLE == 1'b1) begin
					apb_vif.slave_cb.PREADY  <= 1'b1;
					apb_vif.slave_cb.PSLVERR <= addr_error;
					@(apb_vif.slave_cb);
				end
				else begin
					// PSEL / PENABLE dropped before response
					apb_vif.slave_cb.PREADY  <= 1'b0;
					apb_vif.slave_cb.PSLVERR <= 1'b0;
					`uvm_info(get_type_name(), "ACCESS aborted : PREADY is not asserted", UVM_HIGH
					)
				end
			end
			
			`uvm_info(get_type_name(), $sformatf("Execution : %s", item.convert2string()), UVM_HIGH)
			seq_item_port.item_done();

			apb_vif.slave_cb.PSLVERR <= 1'b0;
			apb_vif.slave_cb.PRDATA  <= 32'b0;
			apb_vif.slave_cb.PREADY  <= 1'b0;
		end	
	endtask

endclass
