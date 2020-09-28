# utility functions
fs = require 'fs'
_ = require 'lodash'

allopcodeObj = JSON.parse fs.readFileSync './data/opcodes2.json', 'utf-8'
opcodeGroups = {}
for op in allopcodeObj
	opcodeGroups[ op.parsed[0] ] = 1
opcodeGroups = _.keys opcodeGroups
allopcodeObj = _.keyBy allopcodeObj, 'opcode'


getAllOpcodeObj = ->
	return allopcodeObj

getOpcodeGroups = ->
	return opcodeGroups

getBetween = (fullstr, start, end) ->
	temp = fullstr.split(start)[1]
	temp = temp.split(end)[0]
	return temp

contains = (str, search) ->
	return str.indexOf(search) > -1

splitTrimNoNull = (origstr, splitstr) ->
	ar = origstr.split splitstr
	newar = []
	for item in ar
		item = _.trim item
		if item
			newar.push item
	return newar

num2binary = (num) ->
	return ('0000000000000000'+num.toString(2))[-8...]

displayFlag = (machineState) ->
	flagbyte = machineState.af & 0xFF
	num2binary flagbyte

###*
# Deep diff between two object, using lodash
# @param  {Object} object Object compared
# @param  {Object} base   Object to compare with
# @return {Object}        Return a new object that represents the diff
###
objdiff = (object, base) ->
	changes = (object, base) ->
		_.transform object, (result, value, key) ->
			if !_.isEqual(value, base[key])
				result[key] = if _.isObject(value) and _.isObject(base[key]) then changes(value, base[key]) else value
			return
	changes object, base



module.exports = {
	getBetween
	contains
	splitTrimNoNull
	objdiff
	getAllOpcodeObj
	getOpcodeGroups
	num2binary
	displayFlag
}
