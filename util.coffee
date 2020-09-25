# utility functions
_ = require 'lodash'

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
}