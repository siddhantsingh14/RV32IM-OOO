transcript on
if {[file exists rtl_work]} {
    vdel -lib rtl_work -all
}
vlib rtl_work
vmap work rtl_work

vlog -sv -work work  {./hdl/cir_q.sv}
vlog -sv -work work  {./hvl/cir_q_tb.sv}

vsim -t 1ps -L altera_ver -L lpm_ver -L sgate_ver -L altera_mf_ver -L altera_lnsim_ver -L stratixv_ver -L stratixv_hssi_ver -L stratixv_pcie_hip_ver -L rtl_work -L work -voptargs="+acc"  cir_q_tb

run -all