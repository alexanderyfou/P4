transcript on

# removes white "chars"
proc clean_bin {x} {
    set x [string trim $x]
    set x [string map {" " "" "\n" "" "\r" ""} $x]
    return $x
}



# load instructions txt file to instruction memory
proc init_imem {fname} {



    # clear instruction memory first
    for {set i 0} {$i < 1024} {incr i} {
        force -deposit sim:/cpu_top/frontend_inst/imem_inst/mem\($i\) 00000000000000000000000000000000 0
    }


    set f [open $fname r]

    set inst_count 0


    while {[gets $f line] >= 0} {
        set line [clean_bin $line]


        if {$line eq ""} {
            continue
        }


        force -deposit sim:/cpu_top/frontend_inst/imem_inst/mem\($inst_count\) $line 0
        incr inst_count

    }


    close $f
    echo "Loaded $inst_count instructions"

}

# dump register contents into a file after sim
proc dump_regs {fname} {

    set f [open $fname w]

    for {set i 0} {$i < 32} {incr i} {

        set regval [clean_bin [examine -radix binary sim:/cpu_top/frontend_inst/decode_inst/rf_inst/regs\($i\)]]
        puts $f $regval

    }

    close $f
}

# dump data mem as 32-bit words
proc dump_mem {fname} {

    set f [open $fname w]
    

    for {set addr 0} {$addr < 32768} {incr addr 4} {

        set b0 [clean_bin [examine -radix binary sim:/cpu_top/memory_stage_inst/data_mem_inst/ram_block\($addr\)]]
        set b1 [clean_bin [examine -radix binary sim:/cpu_top/memory_stage_inst/data_mem_inst/ram_block\([expr {$addr + 1}]\)]]

        set b2 [clean_bin [examine -radix binary sim:/cpu_top/memory_stage_inst/data_mem_inst/ram_block\([expr {$addr + 2}]\)]]
        set b3 [clean_bin [examine -radix binary sim:/cpu_top/memory_stage_inst/data_mem_inst/ram_block\([expr {$addr + 3}]\)]]

        puts $f "${b3}${b2}${b1}${b0}"

    }

    close $f

}

# start fresh
if {[file exists work]} {
    vdel -all
}

vlib work
vmap work work



# compile design files
vcom -2008 common_pkg.vhd
vcom -2008 immediate_generator.vhd
vcom -2008 register_file.vhd
vcom -2008 if_id_register.vhd
vcom -2008 pc_register.vhd
vcom -2008 instruction_memory.vhd
vcom -2008 control_unit.vhd
vcom -2008 id_ex_register.vhd
vcom -2008 decode_stage.vhd
vcom -2008 frontend.vhd
vcom -2008 alu.vhd
vcom -2008 execute_stage.vhd
vcom -2008 ex_mem_register.vhd
vcom -2008 memory.vhd
vcom -2008 memory_stage.vhd
vcom -2008 mem_wb_register.vhd
vcom -2008 writeback_stage.vhd
vcom -2008 hazard_detection_unit.vhd
vcom -2008 cpu_top.vhd


vsim work.cpu_top


# signals for debug
add wave sim:/cpu_top/frontend_inst/pc_current
add wave sim:/cpu_top/mem_branch_taken_out
add wave sim:/cpu_top/mem_branch_target_out

# clock + reset
force -freeze sim:/cpu_top/clk 0 0, 1 {500 ps} -r 1 ns
force -deposit sim:/cpu_top/reset 1 0



init_imem program.txt


run 2 ns
force -deposit sim:/cpu_top/reset 0 0


# let program finish
run 10000 ns

dump_regs register_file.txt
dump_mem memory.txt

echo "Simulation complete"