# parse the opcode file and save the data

fs = require 'fs'
content = fs.readFileSync './data/opcodes.html', 'utf-8'

console.log 'length:', content.length

hexAr = ['', '0','1','2','3','4','5','6','7','8','9','A','B','C','D','E','F']

getBetween = (fullstr, start, end) ->
	temp = fullstr.split(start)[1]
	temp = temp.split(end)[0]
	return temp

contains = (str, search) ->
	return str.indexOf(search) > -1

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

# JSON: javascript object notation

	# console.log '============='
	# console.log tdAr[1]

# rowAr = []
# for row in ar
# 	if not row or row.indexOf('axis') is -1
# 		continue
# 	console.log row
# 	newrow = getBetween row, 'axis="', '">'
# 	rowAr.push newrow

# console.log 'number of rows in rowAr', rowAr.length
# console.log rowAr

# console.log content

# for row, index in rowAr
# 	if index is 0
# 		field = row.split '|'
# 		console.log field