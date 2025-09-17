task startSim();
  $display("");
  $display("---------------------------------");
  $display("           SIM Starting!");
  $display("---------------------------------");
  $display("");
endtask

task finishSim();
  $display("");
  $display("---------------------------------");
  $display("           SIM COMPLETE!");
  $display("---------------------------------");
  $display("");
  $finish;
endtask
