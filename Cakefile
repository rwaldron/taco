{spawn, exec} = require 'child_process'

option '-p', '--prefix [DIR]', 'set the installation prefix for `cake install`'

task 'build', 'continually build the taco library with --watch', ->
  coffee = spawn 'coffee', ['-cw', '-o', 'lib', 'src']
  coffee.stdout.on 'data', (data) -> console.log data.toString().trim()

task 'install', 'install the `taco` command into /usr/local (or --prefix)', (options) ->
  base = options.prefix or '/usr/local'
  lib  = base + '/lib/taco'
  exec([
    'mkdir -p ' + lib
    'cp -rf bin README resources vendor lib ' + lib
    'ln -sf ' + lib + '/bin/taco ' + base + '/bin/taco'
  ].join(' && '), (err, stdout, stderr) ->
   if err then console.error stderr
  )

task 'doc', 'rebuild the taco documentation', ->
  exec([
    'bin/taco src/taco.coffee'
    'sed "s/taco.css/resources\\/taco.css/" < docs/taco.html > index.html'
    'rm -r docs'
  ].join(' && '), (err) ->
    throw err if err
  )
