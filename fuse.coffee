# run FUSE tests

fs = require 'fs'
_ = require 'lodash'
u = require './util'
em = require './emulator'

testinAr = JSON.parse fs.readFileSync './data/testin.json', 'utf-8'
testoutAr = JSON.parse fs.readFileSync './data/testout.json', 'utf-8'
for item, index in testinAr
	item.index = index

allOpcodeObj = u.getAllOpcodeObj()
allOpcodes = u.getOpcodeGroups()
opcodeToTest = [
	'nop'
	'inc'
	'dec'
	'ei'
	'di'
	'in'
	'out'
	'halt'
	'ld'
	'push'
	'pop'
	'add'
	'sub'
	'adc'
	'sbc'
	'cp'
	'and'
	'or'
	'xor'
	'jp'
	'jr'
	'call'
	'ret'
	'rst'
	'ex'
	'exx'
	'djnz'
	'rla'
	'rra'
	'rlca'
	'rrca'
	'ccf'
	'scf'
	'cpl'
	'daa'
]

for op in opcodeToTest
	_.pull allOpcodes, op

console.log 'opcodes not tested', allOpcodes

failedTests = 0
passedTests = 0

for testitem in testinAr
	passed = true
	{ machineState, memory, index, opcode } = testitem

	origMachineState = _.cloneDeep machineState

	opObj = allOpcodeObj[_.toUpper opcode]
	if not opObj
		continue
	# console.log 'opcode:', opcode, opObj.mnemonic
	opFamily = opObj.parsed[0]

	if u.contains opcodeToTest, opFamily
		if opcode is '10'
			while _.isNumber memory[machineState.pc]
				em.runOpcode machineState, memory
		else
			em.runOpcode machineState, memory

		testoutMachineState = testoutAr[index].machineState

		testoutAr[index].machineState.af = testoutMachineState.af & 0xFFD7
		machineState.af = machineState.af & 0xFFD7

		# compare current machineState with expected machineState
		diffObj = u.objdiff testoutMachineState, machineState
		delete diffObj.r
		delete diffObj.tstates

		if _.keys(diffObj).length
			failedTests += 1
			passed = false

			currObj = {}
			expectedObj = {}
			for key in _.keys diffObj
				currObj[key] = machineState[key]
				expectedObj[key] = testoutMachineState[key]

			console.log 'ERROR:', opObj.mnemonic, diffObj
			console.log 'current machineState:', currObj
			console.log 'expected machineState:', expectedObj
			console.log 'current a register: ', u.num2binary (machineState.af & 0xFF00) >> 8
			console.log 'expected a register:', u.num2binary (testoutMachineState.af & 0xFF00) >> 8
			console.log '                sz_h_vnc'
			console.log 'current flags: ', u.num2binary machineState.af & 0xFF
			console.log 'expected flags:', u.num2binary testoutMachineState.af & 0xFF
			console.log opObj

		# check memory locations
		for key, val of testoutAr[index].memory
			if memory[key] isnt val
				failedTests += 1
				passed = false
				console.log "ERROR: memory locations don't match", opObj.mnemonic
				console.log "expected memory", testoutAr[index].memory
				console.log 'current memory', memory
				console.log opObj
				break

		if passed
			console.log opObj.opcode, ':', opObj.mnemonic
			passedTests += 1

# console.log 'machineState', machineState

console.log "Passed tests: #{passedTests}, Failed tests: #{failedTests}"
if not failedTests
	console.log '  *** All tests succeeded!!'

