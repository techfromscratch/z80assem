u = require './util'
_ = require 'lodash'

exports.sample = (test) ->
	test.equal 1,1
	test.done()

exports.getBetween = (test) ->
	test.equal 'de', u.getBetween "abcdefghij", 'c', 'f'
	test.equal 'defg', u.getBetween "abcdefghij", 'bc', 'hi'
	test.done()

exports.contains = (test) ->
	test.equal true, u.contains 'abcdef', 'bc'
	test.equal false, u.contains 'abcdef', 'bc2'
	test.equal true, u.contains [1,2,3], 2
	test.equal false, u.contains [1,2,3], 4
	test.done()

exports.splitTrimNoNull = (test) ->
	test.equal true, _.isEqual ['a','b','c','d'], u.splitTrimNoNull 'a b c   d', ' '
	test.equal true, _.isEqual ['a','b','c','d'], u.splitTrimNoNull 'a , b , c   ,  d', ','
	test.done()
