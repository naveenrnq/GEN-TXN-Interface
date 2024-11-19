// Rules

// 1. Add transaction constructor in generator custom constructor
// 2. Send deep copy of transaction between generator and driver
// 

class transaction;

 randc bit [3:0] a;
 randc bit [3:0] b;
 bit [4:0] sum;

 // Function to know the current value of Txn Class
  function void display();
    $display("a : %0d \t b: %0d \t sum: %0d",a,b,sum);
  endfunction

  // We dont want obj to keep history of variables so we declare deep copy method

  function transaction copy();
    copy = new();
    copy.a = this.a;
    copy.b = this.b;
  endfunction

endclass

class generator;

  transaction trans;
  mailbox #(transaction) mbx;
  int i = 0;

  function new(mailbox #(transaction) mbx);
    this.mbx = mbx;
    trans = new();  // this will create single object with history
    
  endfunction

  task run();
    for(int i = 0; i < 20; i++) begin
      assert(trans.randomize()) else $display("RANDOMIZATION FAILED");
      $display("[GEN] : Data Sent to Driver");
      trans.display();
      mbx.put(trans.copy);  // This will allow independent values for each copy
    end

  endtask

endclass

interface add_if;
  logic [3:0] a;
  logic [3:0] b;
  logic [4:0] sum;
  logic clk;
  
  modport DRV (input a,b, input sum,clk);
  
endinterface


class driver;
  
  virtual add_if.DRV aif;
  
  task run();
    forever begin
      @(posedge aif.clk);  
      aif.a <= 2;
      aif.b <= 3;
      $display("[DRV] : Interface Trigger");
    end
  endtask
  
  
endclass
 
 
 
module tb;
  
  generator gen;
  mailbox #(transaction) mbx;

  add_if aif();
  driver drv;
  
  add dut (aif.a, aif.b, aif.sum, aif.clk );
 
  initial begin
    mbx = new();
    gen = new(mbx);
    gen.run();
  end


  initial begin
    aif.clk <= 0;
  end
  
  always #10 aif.clk <= ~aif.clk;
 
   initial begin
     drv = new();
     drv.aif = aif;
     drv.run();
     
   end
  
  initial begin
    $dumpfile("dump.vcd"); 
    $dumpvars;  
    #100;
    $finish();
  end
  
endmodule
