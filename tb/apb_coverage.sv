class apb_coverage extends uvm_subscriber #(apb_seq_item);
	`uvm_component_utils(apb_coverage)
	apb_seq_item item;

	covergroup apb_cg;

		cp_write : coverpoint item.PWRITE {
			bins READ  = {0};
			bins WRITE = {1};
		}

		cp_pstrb : coverpoint item.PSTRB {
			bins BYTE0 = {4'b0001};
			bins BYTE1 = {4'b0010};
			bins BYTE2 = {4'b0100};
			bins BYTE3 = {4'b1000};
			bins FULL  = {4'b1111};
		}

		cp_pslverr : coverpoint item.PSLVERR {
			bins NORMAL = {0};
			bins ERROR  = {1};
		}

		write_x_pstrb : cross cp_write, cp_pstrb;

	endgroup


	function new(string name="apb_coverage", uvm_component parent);
		super.new(name, parent);
		apb_cg = new();
	endfunction


	virtual function void write(apb_seq_item t);
		item = t;
		apb_cg.sample();
	endfunction

endclass