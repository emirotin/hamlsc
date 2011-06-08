sys = require 'sys'
fs = require 'fs'
cs = require 'coffee-script'

String::trim = () ->
  this.replace /^\s*|\s*$/, ''

String::mult = (n) ->
  if n <= 0 then '' else Array(n + 1).join this
  
String::empty = () ->
  !!this.match /^\s*$/
  
String::startsWith = (str) ->
  this.indexOf(str) == 0


class CodeNode  
  constructor: (@type, @level, @line, @extra={}) ->
    @sep = '  '
    @nsep = '\n' + @sep
    @children = []
    
  add_child: (child) ->
    @children.push child
    child.parent = this
    
  raw_child_contents: (dec_level=0) ->
    (@sep.mult(child.level - dec_level) + child.line for child in @children).join '\n'
  
  child_contents: (code_level) ->
    (child.to_func(code_level) for child in @children).join @nsep
    
  to_func: (code_level=0) ->
    if @type == 'COMMENT'
      return ''
    
    if @type == 'CODE'
      code_level += 1
          
    line = @line

    if @type == 'FILTER' and line == ':coffee'
      line = ':javascript'
      child_contents = @raw_child_contents(@level + 1).replace /#{([^}]+)}/g, '__ESCAPED_SHARP($1)'
      child_contents = cs.compile(child_contents).replace /__ESCAPED_SHARP\(([^)]+)\)/g, '#{$1}'
      child_contents = child_contents.split('\n')
      child_contents = ((new CodeNode 'NORMAL', @level + 1, l).to_func() for l in child_contents)
      child_contents = child_contents.join @nsep
    else
      child_contents = @child_contents(code_level)

    if @type == 'ROOT'
      res = ["({render: (c={}) ->", "res = []", child_contents, 'res.join("\\n")']
      return res.join(@nsep) + '\n})'    
    
    if @type == 'NORMAL' or @type == 'EVAL' or @type == 'FILTER'
      line_offset =  @sep.mult(@level - code_level)
      if @type == 'EVAL'
        line = '"' + line_offset + '" + (' + line + ')' 
      else
        line = '"' + line_offset + line.replace(/"/g, '\\"') + '"'    
      line = @sep.mult(code_level) + 'res.push ' + line        
    else if @type == 'CODE'
      line = @sep.mult(code_level - 1) + line      
    
    return line + @nsep + child_contents        

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
    @build_tree()
  
  build_tree: () ->
    offset_regex = RegExp('^' + @offset + '*$')
    @ast = root = new CodeNode 'ROOT', -1, null
    current_node = root
    i = -1
    for line in @lines
      i += 1
      
      if line.empty()
        continue
      
      line_offset = line.match /^\s+/
      if line_offset
        line_offset = line_offset[0]
        if not line_offset.match offset_regex
          throw new Error 'Line ' + i + '. Wrong offset:\n' + line

        level = line_offset.length / @offset.length
        line = line.substr line_offset.length
      else
        line_offset = ''
        level = 0
      
      if level > current_node.level + 1
        throw new Error 'Line ' + i + '. Wrong offset:\n' + line
      
      type = 'NORMAL'
      extra = {}
      if line.match '^-#'
        type = 'COMMENT'
        line = ''
      else if line.match '^-'
        if not line.match '^- '
          throw new Error 'Line ' + i + '. Code lines must start with dash followed by a single space:\n' + line   

        type = 'CODE'
        line = line.substr(2)
        
        line_offset = line.match /^\s+/
        if line_offset
          line_offset = line_offset[0]
          if not line_offset.match offset_regex
            throw new Error 'Line ' + i + '. Wrong offset:\n' + line
          level += line_offset.length / @offset.length
          line = line.substr line_offset.length
        
      else if line.match '^='
        type = 'EVAL'
        line = line.substr(1).trim()
      else if line.match '^:'
        type = 'FILTER'
        line = line.trim()
          
      parent_node = current_node
      while level < parent_node.level + 1
        parent_node = parent_node.parent
                   
      new_node = new CodeNode type, level, line, extra
      parent_node.add_child new_node
      current_node = new_node  
  
  build_compile: () ->
    @ast.to_func()
    
  compile: () ->
    bc = @build_compile()
    sys.puts bc
    cs.eval bc, bare: on

hp = new HscProcessor('test.haml')
sys.puts hp.render({x: 5})