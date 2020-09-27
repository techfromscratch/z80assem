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
	{ pc } = machineState
	# if sourceStr is length=2, then it's a 16-bit register
	# if sourceStr is length=1, then it's an 8-bit register
	if sourceStr is '(**)'
		addr = readSource '**', machineState, memory
		newval = memory[addr]
		if _.isNumber memory[addr+1]
			newval += memory[addr+1] * 256
		return newval

	else if sourceStr is '**'
		return memory[pc+1] + memory[pc+2] * 256
	else if sourceStr is '*'
		return memory[pc+1]
	else if sourceStr[0] is '('
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
	if destStr is '(**)'
		addr = readSource '**', machineState, memory
		memory[addr] = value % 256
		# memory[addr+1] = (value & 0xFF00) / 256
		memory[addr+1] = (value & 0xFF00) >> 8

	else if destStr[0] is '('
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

flagOrderObj =
	s: 7
	z: 6
	h: 4
	v: 2
	n: 1
	c: 0
flagStatusIndex =
	c: 0
	n: 1
	v: 2 			# also p flag
	h: 3
	z: 4
	s: 5
flagOrder = ['s', 'z', '', 'h', '', 'v', 'n', 'c']
# flagStatus = ['c', 'n', 'v', 'h', 'z', 's']

setFlags = (machineState, memory, currOpcodeObj, prevVal, currVal) ->
	{ flags, parsed } = currOpcodeObj
	optype = parsed[0]
	operand2 = parsed[1]
	if operand2.length is 2
		numbits = 16
		currVal = currVal & 0xFFFF
	else
		numbits = 8
		currVal = currVal & 0xFF

	flagObj = {}

	# sign flag
	flagObj.s =
		switch flags[flagStatusIndex.s]
			when '+'
				if numbits is 8
					currVal & 0x80
				else
					currVal & 0x8000

	flagObj.z =
		switch flags[flagStatusIndex.z]
			when '+'
				if currVal is 0 then 1


	# half carry flag
	flagObj.h =
		switch flags[flagStatusIndex.h]
			when '+'
				switch optype
					when 'dec'
						# prevVal: 0bxxxx0000 -> xxxx1111
						if (prevVal & 0xF) is 0 then 1
					when 'inc'
						# prevVal: 0bxxxx1111 -> xxxx0000
						if (prevVal & 0xF) is 0xF then 1

	# overflow flag
	flagObj.v =
		switch flags[flagStatusIndex.v]
			when 'V'
				switch optype
					when 'inc'
						# inc: 0b0111 1111 = 127 + 1 turns negative
						if (prevVal & 0xFF) is 0x7F then 1
					when 'dec'
						# dec: 0b1000 0000 = -128 - 1 turns positive
						if (prevVal & 0xFF) is 0x80 then 1


	# negative operation flag
	flagObj.n =
		switch flags[flagStatusIndex.n]
			when '+'
				if optype in ['dec']
					1

	flagValue = 0
	for flagLetter in flagOrder
		if flagObj[flagLetter]
			flagtemp = 1 << flagOrderObj[flagLetter]
			flagValue |= flagtemp

	machineState.af = (machineState.af & 0xFF00) + flagValue


executeCode =
	dec: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		value = readSource operand2, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value, value-1
		writeDestination operand2, value-1, machineState, memory
	di: (machineState, memory, currOpcodeObj) ->
		machineState.iff1 = 0
		machineState.iff2 = 0
	ei: (machineState, memory, currOpcodeObj) ->
		machineState.iff1 = 1
		machineState.iff2 = 1
	halt: (machineState, memory, currOpcodeObj) ->
		machineState.pc = -1
		machineState.halted = 1
	in: (machineState, memory, currOpcodeObj) ->
	inc: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		value = readSource operand2, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value, value+1
		writeDestination operand2, value+1, machineState, memory
	ld: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		operand3 = currOpcodeObj.parsed[2]

		value = readSource operand3, machineState, memory
		writeDestination operand2, value, machineState, memory
	nop: (machineState, memory, currOpcodeObj) ->
	out: (machineState, memory, currOpcodeObj) ->
	push: (machineState, memory, currOpcodeObj) ->
		{ sp } = machineState
		sp -= 1
		operand2 = currOpcodeObj.parsed[1]
		value = readSource operand2, machineState, memory
		memory[sp] = Math.floor value / 256
		# memory[sp] = (value & 0xFF00) >> 8
		sp -= 1
		memory[sp] = value & 0xFF
		machineState.sp = sp
	pop: (machineState, memory, currOpcodeObj) ->
		{ sp } = machineState
		value = memory[sp] + memory[sp+1] * 256
		operand2 = currOpcodeObj.parsed[1]
		writeDestination operand2, value, machineState, memory
		machineState.sp += 2


runOpcode = (machineState, memory) ->
	{ pc } = machineState
	currOpcode = _.toUpper ('0'+memory[pc].toString(16))[-2... ]
	currOpcodeObj = allOpcodeObj[currOpcode]
	currGroup = currOpcodeObj.parsed[0]

	fn = executeCode[currGroup]
	if fn
		fn machineState, memory, currOpcodeObj
	machineState.pc += currOpcodeObj.numbytes

module.exports = {
	runOpcode
}