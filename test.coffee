sys = require 'sys'
hsc = require './hsc.coffee'

hp = new hsc.HscProcessor('test.haml')
sys.puts hp.render({x: 5})