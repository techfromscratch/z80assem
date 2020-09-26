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
opcodeToTest = ['nop', 'inc']

for op in opcodeToTest
	_.pull allOpcodes, op

# console.log 'opcodes not tested', allOpcodes

failedTests = 0
passedTests = 0

for testitem in testinAr
	passed = true
	{ machineState, memory, index, opcode } = testitem

	origMachineState = _.cloneDeep machineState

	opObj = allOpcodeObj[_.toUpper opcode]
	if not opObj
		continue
	# console.log opcode, opObj
	opFamily = opObj.parsed[0]

	if u.contains opcodeToTest, opFamily
		em.runOpcode machineState, memory

		testoutAr[index].machineState.af = testoutAr[index].machineState.af & 0xFF00
		machineState.af = machineState.af & 0xFF00

		# compare current machineState with expected machineState
		diffObj = u.objdiff testoutAr[index].machineState, machineState
		delete diffObj.r
		delete diffObj.tstates

		if _.keys(diffObj).length
			failedTests += 1
			passed = false
			console.log 'ERROR:', opObj.mnemonic, diffObj
			# console.log 'origMachineState', origMachineState
			# console.log 'current machineState', machineState
			console.log opObj

		# check memory locations
		for key, val of testoutAr[index].memory
			if memory[key] isnt val
				failedTests += 1
				passed = false
				console.log "ERROR: memory locations don't match"
				console.log "expected memory", testoutAr[index].memory
				console.log 'current memory', memory
				break

		if passed
			passedTests += 1

# console.log 'machineState', machineState

console.log "Passed tests: #{passedTests}, Failed tests: #{failedTests}"
if not failedTests
	console.log '  *** All tests succeeded!!'

