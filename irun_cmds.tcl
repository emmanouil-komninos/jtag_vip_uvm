probe -create -shm -depth all minsoc_tc_top
uvm_set -config * recording_detail UVM_LOW
uvm_phase -stop_at run
run
probe -create -shm $uvm:{uvm_test_top.env} -depth all
run 10us
