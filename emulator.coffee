# emulates the Z80

_ = require 'lodash'
u = require './util'

allOpcodeObj = u.getAllOpcodeObj()

registerInfo =
	a:
		bytetype: 'high'
		fullRegister: 'af'
	b:
		bytetype: 'high'
		fullRegister: 'bc'
	d:
		bytetype: 'high'
		fullRegister: 'de'
	h:
		bytetype: 'high'
		fullRegister: 'hl'
	c:
		bytetype: 'low'
		fullRegister: 'bc'
	e:
		bytetype: 'low'
		fullRegister: 'de'
	l:
		bytetype: 'low'
		fullRegister: 'hl'


readSource = (sourceStr, machineState, memory) ->
	# if sourceStr is length=2, then it's a 16-bit register
	# if sourceStr is length=1, then it's an 8-bit register
	if sourceStr[0] is '('
		# memory pointer
		newSourceStr = sourceStr[1 ... -1]
		regValue = readSource newSourceStr, machineState, memory
		return memory[regValue]
	else if sourceStr.length is 2
		return machineState[sourceStr]
	else if sourceStr.length is 1
		regInfo = registerInfo[sourceStr]
		{ bytetype, fullRegister } = regInfo

		fullValue = machineState[fullRegister]
		# console.log 'read fullValue', fullValue, Math.floor fullValue / 256
		if bytetype is 'high'
			return Math.floor fullValue / 256
		else
			return fullValue % 256

writeDestination = (destStr, value, machineState, memory) ->
	if destStr[0] is '('
		newdestStr = destStr[1 ... -1]
		regValue = readSource newdestStr, machineState, memory
		memory[regValue] = value
	else if destStr.length is 2
		if value < 0
			value += 65536
		# 16-bit register
		machineState[destStr] = value
	else if destStr.length is 1
		if value < 0
			value += 256

		regInfo = registerInfo[destStr]
		{ fullRegister, bytetype } = regInfo

		fullValue = machineState[fullRegister]
		if bytetype is 'low'
			fullValue = fullValue & 0xFF00
			value &= 0b11111111
			fullValue += value
			machineState[fullRegister] = fullValue
		else
			fullValue = fullValue & 0xFF
			value = value & 0xFF
			fullValue = value * 256 + fullValue
			# fullValue &= 0xFFFF
			machineState[fullRegister] = fullValue


executeCode =
	nop: (machineState, memory, currOpcodeObj) ->
	inc: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		value = readSource operand2, machineState, memory
		writeDestination operand2, value+1, machineState, memory
	dec: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		value = readSource operand2, machineState, memory
		writeDestination operand2, value-1, machineState, memory


runOpcode = (machineState, memory) ->
	{ pc } = machineState
	currOpcode = _.toUpper ('0'+memory[pc].toString(16))[-2... ]
	currOpcodeObj = allOpcodeObj[currOpcode]
	currGroup = currOpcodeObj.parsed[0]

	fn = executeCode[currGroup]
	if fn
		fn machineState, memory, currOpcodeObj
	machineState.pc += 1

module.exports = {
	runOpcode
}