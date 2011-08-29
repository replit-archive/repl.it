# Watches all coffee files and compiles them live to Javascript.
fs = require 'fs'
{spawn} = require 'child_process'
coffee = require 'coffee-script'
# Compiles a .coffee file to a .js one, synchronously.
compileCoffee = (filename) ->
  console.log "Compiling #{filename}."
  coffee_src = fs.readFileSync filename, 'utf8'
  js_src = coffee.compile coffee_src
  fs.writeFileSync filename.replace(/\.coffee$/, '.js'), js_src
  
watchFile = (filename, callback) ->
  callback filename
  fs.watchFile filename, (current, old) ->
    if +current.mtime != +old.mtime then callback filename

task 'watch', 'Watch all coffee files and compile them live to javascript', ->
  console.log 'Running JSREPL Watch'
  jsreplWatch = spawn 'cake', ['watch'], cwd: './jsrepl'
  jsreplWatch.stdout.on 'data', (d)->
    console.log d.toString()
    
  watched_files = []
  
  reload = ->
    console.log 'Reloading language config.'
    files_to_watch = ['app.coffee', 'languages.coffee']

    compileFile = (filename) ->
      try
        compileCoffee filename
      catch e
        console.log "Error compiling #{filename}: #{e}."

    for file in watched_files
      if file not in files_to_watch
        console.log "Stopped watching #{file}."
        fs.unwatchFile file
    for file in files_to_watch
      if file not in watched_files
        watchFile file, (filename) -> setTimeout (-> compileFile(filename)), 1

    watched_files = files_to_watch

  # Reading directly from a watchFile callback sometimes fails.
  watchFile 'languages.coffee', -> setTimeout reload, 1