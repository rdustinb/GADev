// This inherently knows about the global mem, not the best 
// idea but this is the easiest
task initMem(input [31:0] initValue);
  $display("Initializing the whole memory...");
  for(int initIdx=0; initIdx<$size(wholeMem); initIdx++) begin
    wholeMem[initIdx] = initValue;
  end
  $display("Done initializing the whole memory.");
endtask

task startSim;
  $display("\n");
  $display("################################");
  $display("Starting simulation...");
  $display("\n");
endtask

task finishSim;
  $display("\n");
  $display("Simulation complete!");
  $display("################################");
  $display("\n");
  $finish;
endtask
