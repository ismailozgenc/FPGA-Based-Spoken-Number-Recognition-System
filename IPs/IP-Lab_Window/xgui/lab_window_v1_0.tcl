# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADC_ADDR_W_G" -parent ${Page_0}
  ipgui::add_param $IPINST -name "FRAME_LEN_G" -parent ${Page_0}
  ipgui::add_param $IPINST -name "OUT_ADDR_W_G" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADC_ADDR_W_G { PARAM_VALUE.ADC_ADDR_W_G } {
	# Procedure called to update ADC_ADDR_W_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADC_ADDR_W_G { PARAM_VALUE.ADC_ADDR_W_G } {
	# Procedure called to validate ADC_ADDR_W_G
	return true
}

proc update_PARAM_VALUE.FRAME_LEN_G { PARAM_VALUE.FRAME_LEN_G } {
	# Procedure called to update FRAME_LEN_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.FRAME_LEN_G { PARAM_VALUE.FRAME_LEN_G } {
	# Procedure called to validate FRAME_LEN_G
	return true
}

proc update_PARAM_VALUE.OUT_ADDR_W_G { PARAM_VALUE.OUT_ADDR_W_G } {
	# Procedure called to update OUT_ADDR_W_G when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.OUT_ADDR_W_G { PARAM_VALUE.OUT_ADDR_W_G } {
	# Procedure called to validate OUT_ADDR_W_G
	return true
}


proc update_MODELPARAM_VALUE.FRAME_LEN_G { MODELPARAM_VALUE.FRAME_LEN_G PARAM_VALUE.FRAME_LEN_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.FRAME_LEN_G}] ${MODELPARAM_VALUE.FRAME_LEN_G}
}

proc update_MODELPARAM_VALUE.ADC_ADDR_W_G { MODELPARAM_VALUE.ADC_ADDR_W_G PARAM_VALUE.ADC_ADDR_W_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADC_ADDR_W_G}] ${MODELPARAM_VALUE.ADC_ADDR_W_G}
}

proc update_MODELPARAM_VALUE.OUT_ADDR_W_G { MODELPARAM_VALUE.OUT_ADDR_W_G PARAM_VALUE.OUT_ADDR_W_G } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.OUT_ADDR_W_G}] ${MODELPARAM_VALUE.OUT_ADDR_W_G}
}

