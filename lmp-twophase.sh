# constant temperature simulation
variable  initTemperature  equal 2000
variable  LoopPerCycle     equal 400
variable  initP            equal 100000.0
variable  gseed            equal 6124
variable   sampleStep     equal 10000
variable   DumpFreq       equal 100

# init part
units real
boundary    p p p
timestep 0.25
shell mkdir re

atom_style	charge
read_data  metal_30x30x30.data

neighbor	2 bin
neigh_modify every 10 delay 0 check no
pair_style	reaxff NULL safezone 50 mincap 500
pair_coeff	* * Al_CHO.ff  Al H O
fix  1base   all qeq/reax 1 0.0 10.0 1e-6 reaxff
fix  balance all balance  1000 1.05 shift xy 10 1.05
thermo 1000

shell mkdir ${cycleN}
variable  StartLoop equal 1
variable  ReStartLoop equal ${ReStep}+1
    # for the first cycle, start from restart loop number
    if "${cycleN} == ${StartCycle}" then "variable StartLoop equal ${ReStartLoop}"
    variable dumpNum loop ${StartLoop} ${LoopPerCycle}
    label cyc
    fix  1 all npt  temp  ${initTemperature}  ${initTemperature} $(200.*dt) x ${initP} ${initP} $(1000.*dt) y ${initP} ${initP} $(1000.*dt) z ${initP} ${initP} $(1000.*dt) couple xy
    dump 2 all netcdf ${DumpFreq}  ${cycleN}/${dumpNum}.nc id type x y z q
    run  ${sampleStep}
    unfix 1
    undump 2
    write_restart re/${cycleN}_${dumpNum}.re
    next dumpNum
    jump SELF cyc
next cycleN
