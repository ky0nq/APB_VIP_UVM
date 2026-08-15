class apb_master_drv extends uvm_driver #(apb_seq_item);
	`uvm_component_utils(apb_master_drv)

	virtual apb_if apb_vif;
	
	function new(string name="apb_master_drv", uvm_component parent);
		super.new(name, parent);
	endfunction 

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
		if (!uvm_config_db#(virtual apb_if)::get(this,"","apb_vif",apb_vif)) begin
			`uvm_fatal(get_type_name(), "No find Virtual Interface(vif) in config_db")
		end
	endfunction 
	
	virtual task run_phase(uvm_phase phase);
		apb_seq_item c_item;
		apb_seq_item n_item;
		
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
		seq_item_port.get_next_item(c_item);
		
		@(apb_vif.master_cb);

		// SETUP State
		apb_vif.master_cb.PADDR 	<= c_item.PADDR;
		if(c_item.PWRITE == 1'b0) begin
			apb_vif.master_cb.PWDATA 	<= c_item.PWDATA;
		end
		else begin
			apb_vif.master_cb.PWDATA	<= 32'b0;
		end
		apb_vif.master_cb.PWRITE 	<= c_item.PWRITE;
		apb_vif.master_cb.PSTRB 	<= c_item.PSTRB;
		apb_vif.master_cb.PPROT   	<= c_item.PPROT;
        apb_vif.master_cb.PSEL    	<= 1'b1;
        apb_vif.master_cb.PENABLE 	<= 1'b0;
		`uvm_info(get_type_name(), $sformatf("SETUP: PADDR=%08h PWRITE=%0b PWDATA=%08h", c_item.PADDR, c_item.PWRITE, c_item.PWDATA), UVM_HIGH)
		
		forever begin
			@(apb_vif.master_cb);

			// ACCESS State
			apb_vif.master_cb.PENABLE <= 1'b1;
			`uvm_info(get_type_name(), "ACCESS phase Start", UVM_HIGH)
			
			do begin
				@(apb_vif.master_cb);
			end while (apb_vif.master_cb.PREADY !== 1'b1);

			n_item = null;

			c_item.PREADY 	= apb_vif.master_cb.PREADY;
			c_item.PSLVERR 	= apb_vif.master_cb.PSLVERR;
		
			if (c_item.PWRITE == 1'b0) begin
				c_item.PRDATA = apb_vif.master_cb.PRDATA;
			end
			`uvm_info(get_type_name(), $sformatf("ACCESS completed! : PRDATA=%08h PREADY=%0b PSLVERR=%0b", c_item.PRDATA, c_item.PREADY, c_item.PSLVERR), UVM_HIGH)
			
			// Item done
			`uvm_info(get_type_name(), $sformatf("Execution : %s", c_item.convert2string()), UVM_HIGH)
			seq_item_port.item_done();

			n_item = null;
			if (c_item.b2b == 1'b1) begin // back-to-back process randomize
				seq_item_port.try_next_item(n_item);
			end // next trasaction check method

			// Transition to IDLE or SETUP state for next transaction
			if (n_item != null) begin
				apb_vif.master_cb.PADDR   <= n_item.PADDR;
				apb_vif.master_cb.PWDATA  <= n_item.PWDATA;
				apb_vif.master_cb.PWRITE  <= n_item.PWRITE;
				apb_vif.master_cb.PSTRB   <= n_item.PSTRB;
				apb_vif.master_cb.PPROT   <= n_item.PPROT;
				apb_vif.master_cb.PSEL    <= 1'b1;
				apb_vif.master_cb.PENABLE <= 1'b0;
				`uvm_info(get_type_name(), "Transition to SETUP state for next transaction", UVM_HIGH)
				c_item = n_item; 
				`uvm_info(get_type_name(), $sformatf("SETUP: PADDR=%08h PWRITE=%0b PWDATA=%08h", c_item.PADDR, c_item.PWRITE, c_item.PWDATA), UVM_HIGH)
			end else begin
				apb_vif.master_cb.PSEL <= 1'b0;
				apb_vif.master_cb.PENABLE <= 1'b0;
				`uvm_info(get_type_name(), "Transition to IDLE state", UVM_HIGH)

				// IDLE state
				repeat(c_item.idle_cycles) begin
					@(apb_vif.master_cb);
				end

				// next transaction load
				seq_item_port.get_next_item(c_item);

				@(apb_vif.master_cb);

				apb_vif.master_cb.PADDR   <= c_item.PADDR;
				apb_vif.master_cb.PWDATA  <= c_item.PWDATA;		
				apb_vif.master_cb.PWRITE  <= c_item.PWRITE;
				apb_vif.master_cb.PSTRB   <= c_item.PSTRB;
				apb_vif.master_cb.PPROT   <= c_item.PPROT;
				apb_vif.master_cb.PSEL    <= 1'b1;
				apb_vif.master_cb.PENABLE <= 1'b0;
				`uvm_info(get_type_name(), $sformatf("SETUP: PADDR=%08h PWRITE=%0b PWDATA=%08h", c_item.PADDR, c_item.PWRITE, c_item.PWDATA), UVM_HIGH)
			end	
		end	
	endtask

endclass
