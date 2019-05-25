from subprocess import PIPE, Popen
from os import getcwd

pipe_all = {"stdin" : PIPE}#, "stdout" : PIPE, "stderr" : PIPE}
quartus_tcl = "/software/altera/13.1/quartus/common/tcl/internal/nativelink/qnativesim.tcl"

def init_sim(mp, path):
	quartus_map = Popen(["quartus_map", mp, "-c", mp], **pipe_all)
	quartus_map.wait()
	quartus_sh = Popen(["quartus_sh", "-t", quartus_tcl, "--no_gui", "--rtl_sim", mp, mp], **pipe_all)
	vsim_init = Popen(["/software/altera/13.1/modelsim_ase/bin/vsim", "-c"], **pipe_all)
	quartus_sh.wait()
	dolines = open(path + "/simulation/modelsim/" + mp + "_run_msim_rtl_verilog.do", 'r').readlines()
	initdo = "".join(dolines[:-2])
	vsim_init.communicate(initdo)
	vsim_init.wait()
	return dolines[-7] #-6 for quartus 15

dolines = init_sim("mp0", getcwd())
print dolines

