sys = require 'sys'
fs = require 'fs'
cs = require 'coffee-script'

String::trim = () ->
  this.replace /^\s*|\s*$/, ''

String::mult = (n) ->
  if n <= 0 then '' else Array(n + 1).join this

class HscProcessor
  constructor: (@filename) ->
    file_content = fs.readFileSync @filename, 'utf-8'
    @parse file_content
    return @compile()
      
  parse: (file_content) ->
    @offset = 0
    @lines = file_content.split '\n'  
    i = 0
    l = @lines.length
    while not @offset and i < l
      match = @lines[i].match /^\s+/
      if match
        @offset = match[0]
      i += 1
  
  build_compile: () ->
    offset_regex = RegExp('^' + @offset + '*$')
    res = ["({render: (c={}) ->", "res = []"]
    i = 0
    code_depth = 0
    prev_level = 0
    prev_code_level = 0
    code_levels = []
    for line in @lines
      line_offset = line.match /^\s+/
      if line_offset
        line_offset = line_offset[0]
        if not line_offset.match offset_regex
          sys.puts 'Line ' + i + '. Wrong offset:\n' + line
          return
        level = line_offset.length / @offset.length
        line = line.substr line_offset.length
      else
        line_offset = ''
        level = 0
      if (line.match '^-') and not (line.match '^-#')
        if level > prev_code_level
          code_depth += 1
          prev_code_level = level
          code_levels.push level
        line = @offset.mult(code_depth - 1) + line.substr(1).trim()
      else
        if code_depth and level <= prev_code_level
          code_depth -= 1
          if code_depth < 0
            code_depth = 0
          code_levels.pop()          
          prev_code_level = code_levels[code_depth-1]
        if code_depth
          line_prefix = @offset.mult(code_depth)
          line_offset =  @offset.mult(level - code_depth)
        else
          line_prefix = ''
        if line.match '^='
          line = '"' + line_offset + '" + (' + line.substr(1).trim() + ')'
        else
          line = '"' + line_offset + line.replace(/"/g, '\\"') + '"'
        line = line_prefix + 'res.push ' + line
      res.push line
      i += 1
      prev_level = level
    res.push 'res.join("\\n")'
    res.join('\n' + @offset) + '\n})'  

  compile: () ->
    bc = @build_compile()
    #sys.puts bc
    cs.eval bc, bare: on
        
hp = new HscProcessor('test.haml')
sys.puts hp.render({x: 5})
 