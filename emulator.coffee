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
	else if sourceStr is '$'
		value = memory[pc+1]
		if value > 127
			value = -(256 - value)
		return value
	else if sourceStr[0] is '('
		# memory pointer
		newSourceStr = sourceStr[1 ... -1]
		regValue = readSource newSourceStr, machineState, memory
		return memory[regValue]
	else if sourceStr.length is 2 or sourceStr.length is 3
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
	else if destStr.length is 2 or destStr.length is 3
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

# value is 1 or 0
setFlagBit = (flagname, value, machineState) ->
	flagbyte = machineState.af & 0xFF
	shiftbits = flagOrderObj[flagname]
	temp = 1 << shiftbits
	mask = 0xFF ^ temp

	# example: flagname="z", value=1
	# 0100 0000 = temp for z flag
	# 1111 1111 = 0xFF
	# 1011 1111 = mask

	flagbyte = flagbyte & mask
	flagvalue = value << shiftbits
	flagbyte = flagbyte | flagvalue
	machineState.af = (machineState.af & 0xFF00) | flagbyte


getFlagCondition = (flagcode, machineState) ->
	{ flagname, isSet } = flagCodeObj[flagcode]
	flagvalue = getFlag flagname, machineState
	return (flagvalue > 0) is isSet


setFlags = (machineState, memory, currOpcodeObj, prev1Val, prev2Val, result) ->
	{ flags, parsed } = currOpcodeObj
	optype = parsed[0]
	operand2 = parsed[1]
	origResult = result

	if _.isString(operand2) and operand2.length is 2
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
					if result & 0x80 then 1 else 0
				else
					if result & 0x8000 then 1 else 0

	flagObj.z =
		switch flags[flagStatusIndex.z]
			when '1'
				1
			when '0'
				0
			when '+'
				if result is 0 then 1 else 0


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
						if (prev1Val & 0xF) is 0 then 1 else 0
					when 'inc'
						# prev1Val: 0bxxxx1111 -> xxxx0000
						if (prev1Val & 0xF) is 0xF then 1 else 0
					when 'add'
						if numbits is 8
							if ((prev1Val & 0x0F) + (prev2Val & 0x0F)) & 0x10 then 1 else 0
						else
							if ((prev1Val & 0x0FFF) + (prev2Val & 0x0FFF)) & 0x1000 then 1 else 0
					when 'adc'
						if ((prev1Val & 0x0F) + (prev2Val & 0x0F) + getFlag('c', machineState)) & 0x10 then 1 else 0
					when 'sub', 'cp'
						if ((prev1Val & 0x0F) - (prev2Val & 0x0F)) & 0x10 then 1 else 0
					when 'sbc'
						if ((prev1Val & 0x0F) - (prev2Val & 0x0F) - getFlag('c', machineState)) & 0x10 then 1 else 0

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
						if (prev1Val & 0xFF) is 0x7F then 1 else 0
					when 'dec'
						# dec: 0b1000 0000 = -128 - 1 turns positive
						if (prev1Val & 0xFF) is 0x80 then 1 else 0
					when 'add', 'adc'
						if ((prev2Val & 0x80) is (prev1Val & 0x80)) & ((prev1Val & 0x80) isnt (result & 0x80)) then 1 else 0
					when 'sub', 'sbc', 'cp'
						if ((prev2Val & 0x80) isnt (prev1Val & 0x80)) & ((prev1Val & 0x80) isnt (result & 0x80)) then 1 else 0
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
				if optype in ['dec', 'sub', 'sbc', 'cp'] then 1 else 0

	flagObj.c =
		switch flags[flagStatusIndex.c]
			when '1'
				1
			when '0'
				0
			when '+'
				if numbits is 8
					if origResult & 0xF00 then 1 else 0
				else
					if origResult & 0xF0000 then 1 else 0

	for flagLetter in flagOrder
		newvalue = flagObj[flagLetter]
		if _.isNumber newvalue
			setFlagBit flagLetter, newvalue, machineState


pushValue = (value, machineState, memory) ->
	{ sp } = machineState
	sp -= 1
	memory[sp] = Math.floor value / 256
	# memory[sp] = (value & 0xFF00) >> 8
	sp -= 1
	memory[sp] = value & 0xFF
	machineState.sp = sp

popStack = (machineState, memory) ->
	{ sp } = machineState
	value = memory[sp] + memory[sp+1] * 256
	machineState.sp += 2
	return value

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

	call: (machineState, memory, currOpcodeObj) ->
		{ parsed, opcode, numbytes } = currOpcodeObj

		operand2 = currOpcodeObj.parsed[1]
		nextaddr = machineState.pc + 3
		if parsed.length is 2 or getFlagCondition operand2, machineState
			pushValue nextaddr, machineState, memory
			value = readSource '**', machineState, memory
			machineState.pc = value - numbytes

	ccf: (machineState, memory, currOpcodeObj) ->
		cflag = getFlag 'c', machineState
		setFlagBit 'n', 0, machineState
		setFlagBit 'h', cflag, machineState
		setFlagBit 'c', 1-cflag, machineState

	cp: (machineState, memory, currOpcodeObj) ->
		operand3 = currOpcodeObj.parsed[1]

		value2 = readSource 'a', machineState, memory
		value3 = readSource operand3, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value2, value3, value2 - value3

	cpl: (machineState, memory, currOpcodeObj) ->
		areg = readSource 'a', machineState, memory
		areg = areg ^ 0xFF
		writeDestination 'a', areg, machineState, memory
		setFlagBit 'n', 1, machineState
		setFlagBit 'h', 1, machineState

	# Binary Coded Decimal
	# a register = 8 bits
	# hex digit = 4 bits
	# a register = 2 hex digits

	# example:
	# BCD "9" + binary 2
	# BCD 1001 + 2 = 1011
	# BCD 1011 = "11"

	# example: 99
	# decimal = "99"
	# BCD 1001 1001
	# BCD "99" + 3
	# BCD "1" "0" "0"
	# binary 1001 1001 + 1 = 1001 1010

	# "99" + 2 = "9C"
	# after first conversion = "A2"
	# after 2nd conversion = "102"

	daa: (machineState, memory, currOpcodeObj) ->
		areg = readSource 'a', machineState, memory
		temp = areg
		if not getFlag 'n', machineState
			if getFlag('h', machineState) or (areg & 0x0f) > 9
				temp += 0x06
			if getFlag('c', machineState) or areg > 0x99
				temp += 0x60
		else
			if getFlag('h', machineState) or (areg & 0x0f) > 9
				temp -= 0x06
			if getFlag('c', machineState) or areg > 0x99
				temp -= 0x60

		flagval = if temp & 0x80 then 1 else 0
		setFlagBit 's', flagval, machineState

		# flags.Z = if !(temp & 0xff) then 1 else 0
		flagval = if !(temp & 0xff) then 1 else 0
		setFlagBit 'z', flagval, machineState

		# flags.H = if areg & 0x10 ^ temp & 0x10 then 1 else 0
		flagval = if areg & 0x10 ^ temp & 0x10 then 1 else 0
		setFlagBit 'h', flagval, machineState

		# flags.P = get_parity(temp & 0xff)
		flagval = parity_bits[temp & 0xff]
		setFlagBit 'v', flagval, machineState

		# DAA never clears the carry flag if it was already set,
		#  but it is able to set the carry flag if it was clear.
		# Don't ask me, I don't know.
		# Note also that we check for a BCD carry, instead of the usual.
		# flags.C = if flags.C or areg > 0x99 then 1 else 0
		flagval = if getFlag('c', machineState) or areg > 0x99 then 1 else 0
		setFlagBit 'c', flagval, machineState
		writeDestination 'a', temp & 0xff, machineState, memory

	dec: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		value = readSource operand2, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value, 0, value-1
		writeDestination operand2, value-1, machineState, memory

	di: (machineState, memory, currOpcodeObj) ->
		machineState.iff1 = 0
		machineState.iff2 = 0

	djnz: (machineState, memory, currOpcodeObj) ->
		memval = readSource '$', machineState, memory
		bval = readSource 'b', machineState, memory
		bval -= 1
		if bval > 0
			machineState.pc += memval
		writeDestination 'b', bval, machineState, memory

	ei: (machineState, memory, currOpcodeObj) ->
		machineState.iff1 = 1
		machineState.iff2 = 1

	ex: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		operand3 = currOpcodeObj.parsed[2]

		if operand2 is 'af'
			operand3 = 'af$'

		if operand2 is '(sp)' and operand3 is 'hl'
			lval = readSource 'l', machineState, memory
			hval = readSource 'h', machineState, memory
			spVal = readSource 'sp', machineState, memory
			writeDestination 'hl', memory[spVal] + memory[spVal+1]*256, machineState, memory
			memory[spVal] = lval
			memory[spVal+1] = hval
		else
			value2 = readSource operand2, machineState, memory
			value3 = readSource operand3, machineState, memory
			writeDestination operand3, value2, machineState, memory
			writeDestination operand2, value3, machineState, memory

	exx: (machineState, memory, currOpcodeObj) ->
		ar = ['bc', 'de', 'hl']
		for reg in ar
			reg$ = reg+'$'
			value1 = readSource reg, machineState, memory
			value2 = readSource reg$, machineState, memory
			writeDestination reg$, value1, machineState, memory
			writeDestination reg, value2, machineState, memory

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

	jr: (machineState, memory, currOpcodeObj) ->
		{ parsed, opcode, numbytes } = currOpcodeObj
		operand2 = currOpcodeObj.parsed[1]

		if parsed.length is 2 or getFlagCondition operand2, machineState
			value = readSource '$', machineState, memory
			newloc = machineState.pc + value
			if newloc < 0
				newloc += 0x10000 			# decimal 65536
			machineState.pc = newloc

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
		operand2 = currOpcodeObj.parsed[1]
		value = readSource operand2, machineState, memory
		pushValue value, machineState, memory

	pop: (machineState, memory, currOpcodeObj) ->
		value = popStack machineState, memory
		operand2 = currOpcodeObj.parsed[1]
		writeDestination operand2, value, machineState, memory

	ret: (machineState, memory, currOpcodeObj) ->
		{ parsed, opcode, numbytes } = currOpcodeObj
		operand2 = currOpcodeObj.parsed[1]

		if parsed.length is 1 or getFlagCondition operand2, machineState
			value = popStack machineState, memory
			machineState.pc = value - numbytes

	# 2nd rla test case input
	# 		a register = 1000 0001
	# 		f register = 0001 0010
	# 		af = 0x8112

	# 2nd rla test case output
	# 		a register = 0000 0010
	# 		f register = 0000 0001
	# 		af = 0x0201

	rla: (machineState, memory, currOpcodeObj) ->
		areg = readSource 'a', machineState, memory
		cflag = getFlag 'c', machineState
		areg = areg << 1
		areg = areg | cflag
		setFlags machineState, memory, currOpcodeObj, areg, areg, areg
		writeDestination 'a', areg, machineState, memory

	rlca: (machineState, memory, currOpcodeObj) ->
		areg = readSource 'a', machineState, memory
		bit7 = (areg & 0x80) >> 7
		areg = (areg << 1) | bit7
		setFlagBit 'c', bit7, machineState

		setFlags machineState, memory, currOpcodeObj, areg, areg, areg
		writeDestination 'a', areg, machineState, memory

	rra: (machineState, memory, currOpcodeObj) ->
		areg = readSource 'a', machineState, memory
		bit0 = areg & 0x01
		cflag = getFlag 'c', machineState
		cflag = cflag << 7
		areg = (areg >> 1) | cflag
		# areg = areg | cflag
		setFlags machineState, memory, currOpcodeObj, areg, areg, areg
		setFlagBit 'c', bit0, machineState
		writeDestination 'a', areg, machineState, memory

	rrca: (machineState, memory, currOpcodeObj) ->
		areg = readSource 'a', machineState, memory
		bit0 = areg & 0x01d
		areg = (areg >> 1) | (bit0 << 7)
		setFlags machineState, memory, currOpcodeObj, areg, areg, areg
		setFlagBit 'c', bit0, machineState
		writeDestination 'a', areg, machineState, memory

	rst: (machineState, memory, currOpcodeObj) ->
		{ parsed, opcode, numbytes } = currOpcodeObj
		operand2 = currOpcodeObj.parsed[1]
		addr = parseInt '0x'+operand2.replace 'h', ''
		pushValue machineState.pc+1, machineState, memory
		machineState.pc = addr - numbytes

	sbc: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		operand3 = currOpcodeObj.parsed[2]
		flagval = getFlag 'c', machineState

		value2 = readSource operand2, machineState, memory
		value3 = readSource operand3, machineState, memory
		setFlags machineState, memory, currOpcodeObj, value2, value3, value2 - value3 - flagval
		writeDestination operand2, value2 - value3 - flagval, machineState, memory

	scf: (machineState, memory, currOpcodeObj) ->
		setFlagBit 'c', 1, machineState
		setFlagBit 'n', 0, machineState
		setFlagBit 'h', 0, machineState

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