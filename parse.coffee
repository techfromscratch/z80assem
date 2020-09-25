# parse the opcode file and save the data

fs = require 'fs'
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

parseHTML = ->
	content = fs.readFileSync './data/opcodes.html', 'utf-8'
	hexAr = ['', '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F']
	content = getBetween content, 'table1', '</table>'

	console.log content[0... 100]
	console.log '-----'
	console.log content[-100 ... ]

	# content now contains the parts that we're interested in

	console.log 'new length:', content.length

	rowAr = content.split '<tr'
	console.log 'rowAr length', rowAr.length

	allOperands = []

	for row in rowAr
		if not contains row, 'axis'
			continue
		rowOpcode = getBetween row, '<th>', '</th>'
		tdAr = row.split '<td'

		# console.log tdAr
		for cell, index in tdAr
			if not contains cell, 'axis'
				continue
			cellstr = getBetween cell, 'axis="', '">'
			mnemonic = getBetween cell, '">', '</td>'
			opcode = rowOpcode + hexAr[index]
			fields = cellstr.split '|'

			# console.log opcode, mnemonic, fields
			newobj = {
				"opcode": opcode
				"mnemonic": mnemonic
				flags: fields[0]
				numbytes: parseInt fields[1]
				cycles: fields[2]
				description: fields[3]
			}
			allOperands.push newobj

	# console.log allOperands

	filecontents = JSON.stringify allOperands
	fs.writeFileSync './data/opcodes.json', filecontents, 'utf-8'

addParseFields = ->
	content = fs.readFileSync './data/opcodes.json', 'utf-8'
	opAr = JSON.parse content

	console.log opAr.length
	console.log opAr[1]

	for item in opAr
		item.decimal = parseInt item.opcode, 16
		ar = splitTrimNoNull item.mnemonic, ' '
		ar2 = []
		if ar[1]
			# console.log ar[1]+''
			ar2 = splitTrimNoNull ar[1], ','
		item.parsed = _.concat ar[0], ar2

	outstr = JSON.stringify opAr
	fs.writeFileSync './data/opcodes2.json', outstr, 'utf-8'


parseTestIn = ->
	regAr = ['AF', 'BC', 'DE', 'HL', 'AF$', 'BC$', 'DE$', 'HL$', 'IX', 'IY', 'SP', 'PC']
	reg2Ar = ['I', 'R', 'IFF1', 'IFF2', 'IM', 'halted', 'tstates']

	# <arbitrary test description>
	# 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000
	# 00 00 0 0 0 0     1
	# <start address> <byte1> <byte2> ... -1

	content = fs.readFileSync './data/test.in', 'utf-8'
	lineAr = content.split '\n'

	index = 0
	len = lineAr.length

	testInAr = []

	while index < len
		line = lineAr[index]
		if not line or line is '-1'
			index += 1
			continue

		newobj =
			description: line
			machineState:
				memory: {}

		line2 = lineAr[index+1]
		line3 = lineAr[index+2]

		# console.log 'line2', line2
		# console.log 'line3', line3

		ar = splitTrimNoNull line2, ' '
		for prop, propindex in regAr
			newobj.machineState[regAr[propindex]] = parseInt ar[propindex], 16

		ar = splitTrimNoNull line3, ' '
		for prop, propindex in reg2Ar
			newobj.machineState[reg2Ar[propindex]] = parseInt ar[propindex], 16
		testInAr.push newobj

		index += 3

		while lineAr[index] isnt '-1'
			line = lineAr[index]
			ar = splitTrimNoNull line, ' '
			addr = parseInt ar[0], 16
			for item, memindex in ar[1... ]
				if item isnt '-1'
					newobj.machineState.memory[addr + memindex] = parseInt item, 16
				else
					break
			index += 1


	str = JSON.stringify testInAr
	fs.writeFileSync './data/testin.json', str, 'utf-8'

parseTestIn()


parseTestOut = ->
	regAr = ['AF', 'BC', 'DE', 'HL', 'AF$', 'BC$', 'DE$', 'HL$', 'IX', 'IY', 'SP', 'PC']
	reg2Ar = ['I', 'R', 'IFF1', 'IFF2', 'IM', 'halted', 'tstates']

	# <arbitrary test description>
	# 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000 0000
	# 00 00 0 0 0 0     1
	# <start address> <byte1> <byte2> ... -1

	content = fs.readFileSync './data/test.out', 'utf-8'
	lineAr = content.split '\n'

	index = 0
	len = lineAr.length

	testOutAr = []

	while index < len
		line = lineAr[index]
		if not line or line is '-1' or line[0] is ' '
			index += 1
			continue

		newobj =
			description: line
			machineState: {}
			memory: {}

		index += 1
		while lineAr[index][0] is ' '
			index += 1

		line2 = lineAr[index]
		line3 = lineAr[index+1]

		# console.log 'line2', line2
		# console.log 'line3', line3

		ar = splitTrimNoNull line2, ' '
		for prop, propindex in regAr
			newobj.machineState[regAr[propindex]] = parseInt ar[propindex], 16

		ar = splitTrimNoNull line3, ' '
		for prop, propindex in reg2Ar
			newobj.machineState[reg2Ar[propindex]] = parseInt ar[propindex], 16
		testOutAr.push newobj

		index += 2

		while lineAr[index]
			line = lineAr[index]
			ar = splitTrimNoNull line, ' '
			addr = parseInt ar[0], 16
			for item, memindex in ar[1... ]
				if item isnt '-1'
					newobj.memory[addr + memindex] = parseInt item, 16
				else
					break
			index += 1


	str = JSON.stringify testOutAr
	fs.writeFileSync './data/testout.json', str, 'utf-8'

# parseTestOut()

