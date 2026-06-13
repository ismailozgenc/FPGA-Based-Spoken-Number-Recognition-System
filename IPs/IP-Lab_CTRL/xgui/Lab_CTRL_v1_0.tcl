# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADC_MEM_DEPTH" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FRAME_LEN" -parent ${Page_0}
  ipgui::add_param $IPINST -name "N" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADC_MEM_DEPTH { PARAM_VALUE.ADC_MEM_DEPTH } {
	# Procedure called to update ADC_MEM_DEPTH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADC_MEM_DEPTH { PARAM_VALUE.ADC_MEM_DEPTH } {
	# Procedure called to validate ADC_MEM_DEPTH
	return true
}

proc update_PARAM_VALUE.FRAME_LEN { PARAM_VALUE.FRAME_LEN } {
	# Procedure called to update FRAME_LEN when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAME_LEN { PARAM_VALUE.FRAME_LEN } {
	# Procedure called to validate FRAME_LEN
	return true
}

proc update_PARAM_VALUE.N { PARAM_VALUE.N } {
	# Procedure called to update N when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.N { PARAM_VALUE.N } {
	# Procedure called to validate N
	return true
}


proc update_MODELPARAM_VALUE.N { MODELPARAM_VALUE.N PARAM_VALUE.N } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.N}] ${MODELPARAM_VALUE.N}
}

proc update_MODELPARAM_VALUE.FRAME_LEN { MODELPARAM_VALUE.FRAME_LEN PARAM_VALUE.FRAME_LEN } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_LEN}] ${MODELPARAM_VALUE.FRAME_LEN}
}

proc update_MODELPARAM_VALUE.ADC_MEM_DEPTH { MODELPARAM_VALUE.ADC_MEM_DEPTH PARAM_VALUE.ADC_MEM_DEPTH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADC_MEM_DEPTH}] ${MODELPARAM_VALUE.ADC_MEM_DEPTH}
}

