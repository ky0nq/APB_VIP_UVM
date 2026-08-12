`uvm_analysis_imp_decl(_master)
`uvm_analysis_imp_decl(_slave)

class apb_scoreboard extends uvm_scoreboard;
	`uvm_component_utils(apb_scoreboard)

	uvm_analysis_imp_master #(apb_seq_item, apb_scoreboard) master_imp;
	uvm_analysis_imp_slave #(apb_seq_item, apb_scoreboard) slave_imp;
	
	apb_seq_item master_q[$];
	apb_seq_item slave_q[$];
	
	int write_cnt = 0;
	int read_cnt = 0;
	int pass_cnt = 0;
	int fail_cnt = 0;
	
	function new(string name="apb_scoreboard", uvm_component parent);
		super.new(name, parent);
		master_imp = new("master_imp", this);
		slave_imp = new("slave_imp", this);
	endfunction
	
	// ==================================================
	// Master Monitor -> Scoreboard
	// ==================================================
	function void write_master(apb_seq_item item);
		apb_seq_item master_item;
		master_item = apb_seq_item::type_id::create("master_item");
		master_item.copy(item);
		master_q.push_back(master_item);
		`uvm_info(get_type_name(), $sformatf("Master item received : %s", master_item.convert2string()), UVM_HIGH)
		compare_item();
	endfunction

	// ==================================================
	// Slave Monitor -> Scoreboard
	// ==================================================
	function void write_slave(apb_seq_item item);
		apb_seq_item slave_item;
		slave_item = apb_seq_item::type_id::create("slave_item");
		slave_item.copy(item);
		slave_q.push_back(slave_item);
		`uvm_info(get_type_name(), $sformatf("Slave item received : %s", slave_item.convert2string()), UVM_HIGH)
		compare_item();
	endfunction

	// ==================================================
	// Master / Slave Transaction Compare
	// ==================================================
	function void compare_item();
		apb_seq_item master_item;
		apb_seq_item slave_item;
		// 양쪽 transaction이 모두 들어왔을 때만 비교
		if (master_q.size() > 0 && slave_q.size() > 0) begin
			master_item = master_q.pop_front();
			slave_item  = slave_q.pop_front();
			// -----------------------------------------
			// Read / Write Count
			// -----------------------------------------
			if (master_item.PWRITE == 1'b1)
				write_cnt++;
			else
				read_cnt++;
			// -----------------------------------------
			// 기본 Request 비교
			// -----------------------------------------
			if (
				master_item.PADDR  === slave_item.PADDR  &&
				master_item.PWRITE === slave_item.PWRITE &&
				master_item.PSTRB  === slave_item.PSTRB  &&
				master_item.PPROT  === slave_item.PPROT
			) begin
				// WRITE transaction
				if (master_item.PWRITE == 1'b1) begin
					if (
						master_item.PWDATA  === slave_item.PWDATA  &&
						master_item.PREADY  === slave_item.PREADY  &&
						master_item.PSLVERR === slave_item.PSLVERR
					) begin
						pass_cnt++;
						`uvm_info(
							get_type_name(),
							$sformatf(
								"WRITE PASS : ADDR=%08h DATA=%08h",
								master_item.PADDR,
								master_item.PWDATA
							),
							UVM_LOW
						)
					end
					else begin
						fail_cnt++;
						`uvm_error(
							get_type_name(),
							$sformatf(
								"WRITE FAIL : MASTER=%s SLAVE=%s",
								master_item.convert2string(),
								slave_item.convert2string()
							)
						)
					end
				end
				// READ transaction
				else begin
					if (
						master_item.PRDATA  === slave_item.PRDATA  &&
						master_item.PREADY  === slave_item.PREADY  &&
						master_item.PSLVERR === slave_item.PSLVERR
					) begin
						pass_cnt++;
						`uvm_info(
							get_type_name(),
							$sformatf(
								"READ PASS : ADDR=%08h DATA=%08h",
								master_item.PADDR,
								master_item.PRDATA
							),
							UVM_LOW
						)
					end
					else begin
						fail_cnt++;
						`uvm_error(
							get_type_name(),
							$sformatf(
								"READ FAIL : MASTER=%s SLAVE=%s",
								master_item.convert2string(),
								slave_item.convert2string()
							)
						)
					end
				end
			end
			else begin
				fail_cnt++;
				`uvm_error(
					get_type_name(),
					$sformatf(
						"REQUEST FAIL : MASTER=%s SLAVE=%s",
						master_item.convert2string(),
						slave_item.convert2string()
					)
				)
			end
		end
	endfunction
	
	function void report_phase(uvm_phase phase);
		super.report_phase(phase);
		`uvm_info(
			get_type_name(),
			$sformatf(
				"\n====================================\n\
					APB SCOREBOARD RESULT\n\
					Write Count : %0d\n\
					Read Count  : %0d\n\
					Pass Count  : %0d\n\
					Fail Count  : %0d\n\
					====================================", write_cnt, read_cnt, pass_cnt, fail_cnt), UVM_NONE)
	endfunction

endclass
