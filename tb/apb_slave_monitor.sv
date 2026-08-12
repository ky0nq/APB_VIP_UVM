class apb_slave_mon extends uvm_monitor;
	`uvm_component_utils(apb_slave_mon)
	virtual apb_if apb_vif;
	uvm_analysis_port #(apb_seq_item) slave_ap; 
	
	function new(string name="apb_slave_mon", uvm_component parent);
		super.new(name, parent);
		slave_ap = new("slave_ap", this);
	endfunction

	function void build_phase(uvm_phase phase);
		super.build_phase(phase);
	
		if (!uvm_config_db#(virtual apb_if)::get(this, "", "apb_vif", apb_vif)) begin
			`uvm_fatal(get_type_name(), "No find Virtual Interface(vif)")
		end
	endfunction

	virtual task run_phase(uvm_phase phase);
		apb_seq_item item;

		forever begin		
			// Waiting ACCESS State
			do begin 
				@(apb_vif.monitor_cb);
			end while (!(apb_vif.monitor_cb.PSEL == 1'b1 && apb_vif.monitor_cb.PENABLE == 1'b1 &&
							apb_vif.monitor_cb.PREADY == 1'b1));
			item = apb_seq_item::type_id::create("item");	
			
			// Master Request Saving
			item.PADDR  = apb_vif.monitor_cb.PADDR;
			item.PWDATA = apb_vif.monitor_cb.PWDATA;
			item.PWRITE = apb_vif.monitor_cb.PWRITE;
			item.PSTRB  = apb_vif.monitor_cb.PSTRB;
			item.PPROT  = apb_vif.monitor_cb.PPROT;

			// Slave Response Saving
			item.PREADY  = apb_vif.monitor_cb.PREADY;
			item.PSLVERR = apb_vif.monitor_cb.PSLVERR;

			if (item.PWRITE == 1'b0) begin
				item.PRDATA = apb_vif.monitor_cb.PRDATA; 	// Read Operation
			end
			else begin
				item.PRDATA = 32'b0;
			end
			
			`uvm_info(get_type_name(), $sformatf("SLAVE MONITOR: PADDR=%08h PWRITE=%0b PRDATA=%08h PREADY=%0b PSLVERR=%0b", 
							item.PADDR, item.PWRITE, item.PRDATA, item.PREADY, item.PSLVERR), UVM_HIGH)

			slave_ap.write(item);
		end
	endtask

endclass
