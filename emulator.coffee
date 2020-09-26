# emulates the Z80

_ = require 'lodash'
u = require './util'

allOpcodeObj = u.getAllOpcodeObj()

executeCode =
	nop: (machineState, memory, currOpcodeObj) ->
	inc: (machineState, memory, currOpcodeObj) ->
		operand2 = currOpcodeObj.parsed[1]
		if machineState[operand2]
			machineState[operand2] += 1


runOpcode = (machineState, memory) ->
	{ pc } = machineState
	currOpcode = _.toUpper ('0'+memory[pc].toString(16))[-2... ]
	currOpcodeObj = allOpcodeObj[currOpcode]
	currGroup = currOpcodeObj.parsed[0]

	console.log '--------------------'
	fn = executeCode[currGroup]
	if fn
		fn machineState, memory, currOpcodeObj

	console.log 'currOpcode', currOpcode
	console.log 'currGroup', currGroup
	console.log 'currOpcodeObj', currOpcodeObj

	machineState.pc += 1

module.exports = {
	runOpcode
}