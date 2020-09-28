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
		value = value & 0xFFFF

		# 16-bit register
		machineState[destStr] = value
	else if destStr.length is 1
		if value < 0
			value += 256
		value = value & 0xFF

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

# which bit position in the flag register
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

flagCodeObj =
	c:
		flagname: 'c'
		isSet: true
	nc:
		flagname: 'c'
		isSet: false
	z:
		flagname: 'z'
		isSet: true
	nz:
		flagname: 'z'
		isSet: false
	m:
		flagname: 's'
		isSet: true
	p:
		flagname: 's'
		isSet: false
	pe:
		flagname: 'v'
		isSet: true
	po:
		flagname: 'v'
		isSet: false


parity_bits = [
	1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
	0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
	0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
	1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
	0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
	1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
	1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
	0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
	0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
	1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
	1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
	0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
	1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1,
	0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
	0, 1, 1, 0, 1, 0, 0, 1, 1, 0, 0, 1, 0, 1, 1, 0,
	1, 0, 0, 1, 0, 1, 1, 0, 0, 1, 1, 0, 1, 0, 0, 1
]

# returns 1 if set, 0 if unset for requested flag
getFlag = (flagname, machineState) ->
	flagbyte = machineState.af & 0xFF
	# 0100 0000 = mask for z flag
	shiftbits = flagOrderObj[flagname]
	flagmask = 1 << shiftbits
	return (flagbyte & flagmask) >> shiftbits 		# 1 if set, 0 if unset

getFlagCondition = (flagcode, machineState) ->
	{ flagname, isSet } = flagCodeObj[flagcode]
	flagvalue = getFlag flagname, machineState
	return (flagvalue > 0) is isSet


setFlags = (machineState, memory, currOpcodeObj, prev1Val, prev2Val, result) ->
	{ flags, parsed } = currOpcodeObj
	optype = parsed[0]
	operand2 = parsed[1]
	origResult = result

	if operand2.length is 2
		numbits = 16
		result = result & 0xFFFF
	else
		numbits = 8
		result = result & 0xFF

	flagObj = {}

	# sign flag
	flagObj.s =
		switch flags[flagStatusIndex.s]
			when '1'
				1
			when '0'
				0
			when '+'
				if numbits is 8
					result & 0x80
				else
					result & 0x8000

	flagObj.z =
		switch flags[flagStatusIndex.z]
			when '1'
				1
			when '0'
				0
			when '+'
				if result is 0 then 1


	# half carry flag
	flagObj.h =
		switch flags[flagStatusIndex.h]
			when '1'
				1
			when '0'
				0
			when '+'
				switch optype
					when 'dec'
						# prev1Val: 0bxxxx0000 -> xxxx1111
						if (prev1Val & 0xF) is 0 then 1
					when 'inc'
						# prev1Val: 0bxxxx1111 -> xxxx0000
						if (prev1Val & 0xF) is 0xF then 1
					when 'add'
						if numbits is 8
							if ((prev1Val & 0x0F) + (prev2Val & 0x0F)) & 0x10 then 1
						else
							if ((prev1Val & 0x0FFF) + (prev2Val & 0x0FFF)) & 0x1000 then 1
					when 'adc'
						if ((prev1Val & 0x0F) + (prev2Val & 0x0F) + getFlag('c', machineState)) & 0x10 then 1
					when 'sub', 'cp'
						if ((prev1Val & 0x0F) - (prev2Val & 0x0F)) & 0x10 then 1
					when 'sbc'
						if ((prev1Val & 0x0F) - (prev2Val & 0x0F) - getFlag('c', machineState)) & 0x10 then 1

	# overflow flag
	flagObj.v =
		switch flags[flagStatusIndex.v]
			when '1'
				1
			when '0'
				0
			when 'V'
				switch optype
					when 'inc'
						# inc: 0b0111 1111 = 127 + 1 turns negative
						if (prev1Val & 0xFF) is 0x7F then 1
					when 'dec'
						# dec: 0b1000 0000 = -128 - 1 turns positive
						if (prev1Val & 0xFF) is 0x80 then 1
					when 'add', 'adc'
						if ((prev2Val & 0x80) is (prev1Val & 0x80)) & ((prev1Val & 0x80) isnt (result & 0x80)) then 1
					when 'sub', 'sbc', 'cp'
						if ((prev2Val & 0x80) isnt (prev1Val & 0x80)) & ((prev1Val & 0x80) isnt (result & 0x80)) then 1
			when 'P'
				parity_bits[result]


	# negative operation flag
	flagObj.n =
		switch flags[flagStatusIndex.n]
			when '1'
				1
			when '0'
				0
			when '+'
				if optype in ['dec', 'sub', 'sbc', 'cp']
					1

	flagObj.c =
		switch flags[flagStatusIndex.c]
			when '1'
				1
			when '0'
				0
			when '+'
				if numbits is 8
					origResult & 0xF00
				else
					origResult & 0xF0000

	flagValue = 0
	for flagLetter in flagOrder
		if flagObj[flagLetter]
			flagtemp = 1 << flagOrderObj[flagLetter]
			flagValue |= flagtemp

	machineState.af = (machineState.af & 0xFF00) + flagValue


executeCode =
	adc: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		operand3 = currOpcodeObj.parsed[2]
		flagval = getFlag 'c', machineState

		value2 = readSource operand2, machineState, memory
		value3 = readSource operand3, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value2, value3, value2 + value3 + flagval
		writeDestination operand2, value2 + value3 + flagval, machineState, memory

	add: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		operand3 = currOpcodeObj.parsed[2]

		value2 = readSource operand2, machineState, memory
		value3 = readSource operand3, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value2, value3, value2 + value3
		writeDestination operand2, value2 + value3, machineState, memory

	and: (machineState, memory, currOpcodeObj) ->
		operand3 = currOpcodeObj.parsed[1]

		value2 = readSource 'a', machineState, memory
		value3 = readSource operand3, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value2, value3, value2 & value3
		writeDestination 'a', value2 & value3, machineState, memory

	cp: (machineState, memory, currOpcodeObj) ->
		operand3 = currOpcodeObj.parsed[1]

		value2 = readSource 'a', machineState, memory
		value3 = readSource operand3, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value2, value3, value2 - value3

	dec: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		value = readSource operand2, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value, 0, value-1
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
		setFlags machineState, memory, currOpcodeObj, value, 0, value+1
		writeDestination operand2, value+1, machineState, memory

	jp: (machineState, memory, currOpcodeObj) ->
		{ parsed, opcode, numbytes } = currOpcodeObj
		operand2 = currOpcodeObj.parsed[1]

		if parsed.length is 2
			if opcode is 'E9'
				source = 'hl'
			else if opcode is 'C3'
				source = '**'
			value = readSource source, machineState, memory
			machineState.pc = value - numbytes
		else
			if getFlagCondition operand2, machineState
				operand3 = currOpcodeObj.parsed[2]
				memloc = readSource operand3, machineState, memory
				machineState.pc = memloc - numbytes


	ld: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		operand3 = currOpcodeObj.parsed[2]

		value = readSource operand3, machineState, memory
		writeDestination operand2, value, machineState, memory

	nop: (machineState, memory, currOpcodeObj) ->

	or: (machineState, memory, currOpcodeObj) ->
		operand3 = currOpcodeObj.parsed[1]

		value2 = readSource 'a', machineState, memory
		value3 = readSource operand3, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value2, value3, value2 | value3
		writeDestination 'a', value2 | value3, machineState, memory

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

	sbc: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		operand3 = currOpcodeObj.parsed[2]
		flagval = getFlag 'c', machineState

		value2 = readSource operand2, machineState, memory
		value3 = readSource operand3, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value2, value3, value2 - value3 - flagval
		writeDestination operand2, value2 - value3 - flagval, machineState, memory

	sub: (machineState, memory, currOpcodeObj) ->
		operand3 = currOpcodeObj.parsed[1]

		value2 = readSource 'a', machineState, memory
		value3 = readSource operand3, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value2, value3, value2 - value3
		writeDestination 'a', value2 - value3, machineState, memory

	xor: (machineState, memory, currOpcodeObj) ->
		operand3 = currOpcodeObj.parsed[1]

		value2 = readSource 'a', machineState, memory
		value3 = readSource operand3, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value2, value3, value2 ^ value3
		writeDestination 'a', value2 ^ value3, machineState, memory




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