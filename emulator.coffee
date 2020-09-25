# emulates the Z80

runOpcode = (machineState, memory) ->
	machineState.pc += 1

module.exports = {
	runOpcode
}