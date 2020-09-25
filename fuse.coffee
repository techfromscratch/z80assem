# run FUSE tests

fs = require 'fs'
_ = require 'lodash'
em = require './emulator'


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


testinAr = JSON.parse fs.readFileSync './data/testin.json', 'utf-8'
testoutAr = JSON.parse fs.readFileSync './data/testout.json', 'utf-8'

for item, index in testinAr
	item.index = index

{ machineState, memory, index } = testinAr[0]
em.runOpcode machineState

diffObj = objdiff testoutAr[index].machineState, machineState
delete diffObj.R
delete diffObj.tstates

console.log diffObj
