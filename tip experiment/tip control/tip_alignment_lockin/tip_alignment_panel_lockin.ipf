#pragma moduleName = tip_alignment_panel
#pragma rtGlobals=3		// Use modern global access method and strict wave access.

#include "tip_alignment_lockin"

static strconstant gv_folder = "root:global_variables:tip_alignment"

function align_tips_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar scan_size = $(gv_folder + ":scan_size"), scan_step = $(gv_folder + ":scan_step")
			tip_alignment#align_tips(scan_size, scan_step)
			break
		case -1:
			break
	endswitch
	return 0
end

function move_to_centre_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			pi_stage#open_comms()
			tip_alignment#move_to_centre()
			pi_stage#close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

function resonance_scan_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			nvar freq_start = $(gv_folder + ":freq_start"), freq_stop = $(gv_folder + ":freq_stop")
			nvar freq_inc = $(gv_folder + ":freq_inc")
			tip_res#resonance_scan(freq_start, freq_stop, freq_inc)
			break
		case -1:
			break
	endswitch
	return 0
end

function output_sine_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	
	dfref df = $(sig_gen#gv_path())
	nvar/z/sdfr=df sig_gen_mode
	if (!nvar_exists(sig_gen_mode))
		variable/g df:sig_gen_mode = 1
	endif
	
	switch (ba.eventcode)
		case 2:
			sig_gen#open_comms()
			if (sig_gen_mode == 1)
				sig_gen#output_dc()
				sig_gen_mode = 0
			elseif (sig_gen_mode == 0)
				sig_gen#output_sine()
				sig_gen_mode = 1
			endif
			sig_gen#close_comms()
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_x_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "x"
			dfref sf = $scan_folder
			wave/sdfr=sf wdata = $("force_scan_" + var)
			centroid_fitting#fit_alignment_scan(sf, wdata)
			nvar/sdfr=sf x0 = $(var + "_x0"), y0 = $(var + "_y0")
			tip_alignment#set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_y_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "y"
			dfref sf = $scan_folder
			wave/sdfr=sf wdata = $("force_scan_" + var)
			centroid_fitting#fit_alignment_scan(sf, wdata)
			nvar/sdfr=sf x0 = $(var + "_x0"), y0 = $(var + "_y0")
			tip_alignment#set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_r_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "r"
			dfref sf = $scan_folder
			wave/sdfr=sf wdata = $("force_scan_" + var)
			centroid_fitting#fit_alignment_scan(sf, wdata)
			nvar/sdfr=sf x0 = $(var + "_x0"), y0 = $(var + "_y0")
			tip_alignment#set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_theta_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "theta"
			dfref sf = $scan_folder
			wave/sdfr=sf wdata = $("force_scan_" + var)
			centroid_fitting#fit_alignment_scan(sf, wdata)
			nvar/sdfr=sf x0 = $(var + "_x0"), y0 = $(var + "_y0")
			tip_alignment#set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_fx_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "x"
			dfref sf = $scan_folder
			wave/sdfr=sf wdata = $("current_scan_" + var)
			centroid_fitting#fit_alignment_scan(sf, wdata)
			nvar/sdfr=sf x0 = $(var + "_x0"), y0 = $(var + "_y0")
			tip_alignment#set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_fy_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "y"
			dfref sf = $scan_folder
			wave/sdfr=sf wdata = $("current_scan_" + var)
			centroid_fitting#fit_alignment_scan(sf, wdata)
			nvar/sdfr=sf x0 = $(var + "_x0"), y0 = $(var + "_y0")
			tip_alignment#set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_fr_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "r"
			dfref sf = $scan_folder
			wave/sdfr=sf wdata = $("current_scan_" + var)
			centroid_fitting#fit_alignment_scan(sf, wdata)
			nvar/sdfr=sf x0 = $(var + "_x0"), y0 = $(var + "_y0")
			tip_alignment#set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end

function fit_alignment_data_fthet_button(ba) : buttoncontrol
	struct wmbuttonaction &ba
	switch (ba.eventcode)
		case 2:
			svar scan_folder = $(gv_folder + ":current_scan_folder")
			string var = "theta"
			dfref sf = $scan_folder
			wave/sdfr=sf wdata = $("current_scan_" + var)
			centroid_fitting#fit_alignment_scan(sf, wdata)
			nvar/sdfr=sf x0 = $(var + "_x0"), y0 = $(var + "_y0")
			tip_alignment#set_centroid(x0, y0)
			break
		case -1:
			break
	endswitch
	return 0
end