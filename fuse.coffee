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
opcodeToTest = ['nop']

for op in opcodeToTest
	_.pull allOpcodes, op

console.log 'opcodes not tested', allOpcodes

failedTests = false
for testitem in testinAr
	{ machineState, memory, index, opcode } = testitem

	opObj = allOpcodeObj[_.toUpper opcode]
	if not opObj
		continue
	# console.log opcode, opObj
	opFamily = opObj.parsed[0]

	if u.contains opcodeToTest, opFamily
		em.runOpcode machineState, memory
		diffObj = u.objdiff testoutAr[index].machineState, machineState
		delete diffObj.r
		delete diffObj.tstates

		if _.keys(diffObj).length
			failedTests = true
			console.log 'ERROR:', opObj.mnemonic, diffObj

if not failedTests
	console.log 'All tests succeeded!!'

