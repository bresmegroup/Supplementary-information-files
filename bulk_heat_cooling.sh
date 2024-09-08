variable  initTemperature  equal 400
variable  LoopPerCycle     equal 100
variable  TotalCycle       equal 2
variable  initP            equal 1.0
variable gseed            equal 20969

# restart part
variable StartCycle equal 1
variable ReStep equal 0
variable   equilStep      equal 10000
variable   sampleStep     equal 10000
variable   heatStep       equal 10000
variable   DumpFreq       equal 100

# init part
units		real
boundary    p p p
timestep	 0.25
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

variable cycleN loop ${StartCycle} ${TotalCycle}
label grandcyc
shell mkdir ${cycleN}
variable  StartLoop equal 1
variable  ReStartLoop equal ${ReStep}+1
    # for the first cycle, update the StartLoop from ReStartLoop; else StartLoop equal 1
    if "${cycleN} == ${StartCycle}" then "variable StartLoop equal ${ReStartLoop}"
    variable dumpNum loop ${StartLoop} ${LoopPerCycle}
    label cyc
    variable a equal ${cycleN}%2
    if "${a} > 0" then "variable index equal 1" else "variable index equal -1"
    if "${a} > 0" then "variable indexT equal 0" else "variable indexT equal 1"
    variable Ta equal ${initTemperature}+${LoopPerCycle}*10.*${indexT}+10.*(${dumpNum}-1)*${index}
    variable Tb equal ${Ta}+10.*${index}
    print "running from ${Ta}K to ${Tb}K"
    fix  1 all npt  temp  ${Ta}  ${Tb} $(200.*dt) x ${initP} ${initP} $(1000.*dt) y ${initP} ${initP} $(1000.*dt) z ${initP} ${initP} $(1000.*dt) couple xy
    run   ${heatStep}
    unfix 1

    # equilibrium
    fix  1 all npt  temp  ${Tb}  ${Tb} $(200.*dt) x ${initP} ${initP} $(1000.*dt) y ${initP} ${initP} $(1000.*dt) z ${initP} ${initP} $(1000.*dt) couple xy
    run   ${equilStep}
    unfix 1

    # sample
    fix 1 all nvt  temp  ${Tb}  ${Tb} $(200.*dt)
    dump 2 all netcdf ${DumpFreq}  ${cycleN}/${Tb}.nc id type x y z q vx vy vz
    run  ${sampleStep}
    unfix 1
    undump 2
    write_restart re/${cycleN}_${dumpNum}.re

    next dumpNum
    jump SELF cyc
next cycleN
jump SELF grandcyc
