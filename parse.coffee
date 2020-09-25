# parse the opcode file and save the data

fs = require 'fs'
content = fs.readFileSync './data/opcodes.html', 'utf-8'

console.log 'length:', content.length

content = content.split('table1')[1]
content = content.split('</table>')[0]

console.log content[0... 100]
console.log '-----'
console.log content[-100 ... ]

# content now contains the parts that we're interested in

console.log 'new length:', content.length
