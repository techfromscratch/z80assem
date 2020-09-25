# emulates the Z80

runOpcode = (machineState, memory) ->
	machineState.PC += 1

module.exports = {
	runOpcode
}