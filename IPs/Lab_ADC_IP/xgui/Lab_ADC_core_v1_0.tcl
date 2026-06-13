# Definitional proc to organize widgets for parameters.
proc init_gui { IPINST } {
  ipgui::add_param $IPINST -name "Component_Name"
  #Adding Page
  set Page_0 [ipgui::add_page $IPINST -name "Page 0"]
  ipgui::add_param $IPINST -name "ADC_OFFSET" -parent ${Page_0}
  ipgui::add_param $IPINST -name "ADC_WORD" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CS_LOW_CYCLES" -parent ${Page_0}
  ipgui::add_param $IPINST -name "CS_PERIOD_CYCLES" -parent ${Page_0}
  ipgui::add_param $IPINST -name "DECIM_FACTOR" -parent ${Page_0}
  ipgui::add_param $IPINST -name "N" -parent ${Page_0}
  ipgui::add_param $IPINST -name "SILENCE_LIMIT" -parent ${Page_0}
  ipgui::add_param $IPINST -name "VOICE_THRESH" -parent ${Page_0}


}

proc update_PARAM_VALUE.ADC_OFFSET { PARAM_VALUE.ADC_OFFSET } {
	# Procedure called to update ADC_OFFSET when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADC_OFFSET { PARAM_VALUE.ADC_OFFSET } {
	# Procedure called to validate ADC_OFFSET
	return true
}

proc update_PARAM_VALUE.ADC_WORD { PARAM_VALUE.ADC_WORD } {
	# Procedure called to update ADC_WORD when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.ADC_WORD { PARAM_VALUE.ADC_WORD } {
	# Procedure called to validate ADC_WORD
	return true
}

proc update_PARAM_VALUE.CS_LOW_CYCLES { PARAM_VALUE.CS_LOW_CYCLES } {
	# Procedure called to update CS_LOW_CYCLES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CS_LOW_CYCLES { PARAM_VALUE.CS_LOW_CYCLES } {
	# Procedure called to validate CS_LOW_CYCLES
	return true
}

proc update_PARAM_VALUE.CS_PERIOD_CYCLES { PARAM_VALUE.CS_PERIOD_CYCLES } {
	# Procedure called to update CS_PERIOD_CYCLES when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.CS_PERIOD_CYCLES { PARAM_VALUE.CS_PERIOD_CYCLES } {
	# Procedure called to validate CS_PERIOD_CYCLES
	return true
}

proc update_PARAM_VALUE.DECIM_FACTOR { PARAM_VALUE.DECIM_FACTOR } {
	# Procedure called to update DECIM_FACTOR when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.DECIM_FACTOR { PARAM_VALUE.DECIM_FACTOR } {
	# Procedure called to validate DECIM_FACTOR
	return true
}

proc update_PARAM_VALUE.N { PARAM_VALUE.N } {
	# Procedure called to update N when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.N { PARAM_VALUE.N } {
	# Procedure called to validate N
	return true
}

proc update_PARAM_VALUE.SILENCE_LIMIT { PARAM_VALUE.SILENCE_LIMIT } {
	# Procedure called to update SILENCE_LIMIT when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.SILENCE_LIMIT { PARAM_VALUE.SILENCE_LIMIT } {
	# Procedure called to validate SILENCE_LIMIT
	return true
}

proc update_PARAM_VALUE.VOICE_THRESH { PARAM_VALUE.VOICE_THRESH } {
	# Procedure called to update VOICE_THRESH when any of the dependent parameters in the arguments change
}

proc validate_PARAM_VALUE.VOICE_THRESH { PARAM_VALUE.VOICE_THRESH } {
	# Procedure called to validate VOICE_THRESH
	return true
}


proc update_MODELPARAM_VALUE.N { MODELPARAM_VALUE.N PARAM_VALUE.N } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.N}] ${MODELPARAM_VALUE.N}
}

proc update_MODELPARAM_VALUE.DECIM_FACTOR { MODELPARAM_VALUE.DECIM_FACTOR PARAM_VALUE.DECIM_FACTOR } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.DECIM_FACTOR}] ${MODELPARAM_VALUE.DECIM_FACTOR}
}

proc update_MODELPARAM_VALUE.ADC_WORD { MODELPARAM_VALUE.ADC_WORD PARAM_VALUE.ADC_WORD } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADC_WORD}] ${MODELPARAM_VALUE.ADC_WORD}
}

proc update_MODELPARAM_VALUE.ADC_OFFSET { MODELPARAM_VALUE.ADC_OFFSET PARAM_VALUE.ADC_OFFSET } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.ADC_OFFSET}] ${MODELPARAM_VALUE.ADC_OFFSET}
}

proc update_MODELPARAM_VALUE.VOICE_THRESH { MODELPARAM_VALUE.VOICE_THRESH PARAM_VALUE.VOICE_THRESH } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.VOICE_THRESH}] ${MODELPARAM_VALUE.VOICE_THRESH}
}

proc update_MODELPARAM_VALUE.SILENCE_LIMIT { MODELPARAM_VALUE.SILENCE_LIMIT PARAM_VALUE.SILENCE_LIMIT } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.SILENCE_LIMIT}] ${MODELPARAM_VALUE.SILENCE_LIMIT}
}

proc update_MODELPARAM_VALUE.CS_LOW_CYCLES { MODELPARAM_VALUE.CS_LOW_CYCLES PARAM_VALUE.CS_LOW_CYCLES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CS_LOW_CYCLES}] ${MODELPARAM_VALUE.CS_LOW_CYCLES}
}

proc update_MODELPARAM_VALUE.CS_PERIOD_CYCLES { MODELPARAM_VALUE.CS_PERIOD_CYCLES PARAM_VALUE.CS_PERIOD_CYCLES } {
	# Procedure called to set VHDL generic/Verilog parameter value(s) based on TCL parameter value
	set_property value [get_property value ${PARAM_VALUE.CS_PERIOD_CYCLES}] ${MODELPARAM_VALUE.CS_PERIOD_CYCLES}
}

