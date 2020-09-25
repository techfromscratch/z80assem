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


module.exports = {
	getBetween
	contains
	splitTrimNoNull
}