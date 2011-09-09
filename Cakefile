# Watches all coffee files and compiles them live to Javascript.
fs = require 'fs'
{spawn, exec} = require 'child_process'
coffee = require 'coffee-script'

# Compiles a .coffee file to a .js one, synchronously.
compileCoffee = (filename) ->
  console.log "Compiling #{filename}."
  coffee_src = fs.readFileSync filename, 'utf8'
  js_src = coffee.compile coffee_src
  fs.writeFileSync filename.replace(/\.coffee$/, '.js'), js_src

pygmentizeExample = (language, filename) ->
  console.log "Highlighting #{filename}."
  raw_examples = fs.readFileSync(filename, 'utf8').replace /^\s+|\s+$/g, ''
  raw_examples = raw_examples.split /\*{60,}/
  index = 0
  examples = []
  while index + 1 < raw_examples.length
    examples.push [raw_examples[index].replace(/^\s+|\s+$/g, ''),
                   raw_examples[index + 1].replace(/^\s+|\s+$/g, '')]
    index += 2

  highlighted = Array examples.length

  examplesToHighlight = examples.length
  writeResult = ->
    if --examplesToHighlight == 0
      html_filename = filename.replace(/\.txt$/, '.html')
      separator = (('*' for i in [0..80]).join '') + '\n'
      highlighted = (i.join '\n' + separator for i in highlighted)
      result = highlighted.join(separator + '\n') + separator
      fs.writeFileSync html_filename, result

  for [example_name, example], index in examples
    do (example_name, example, index) ->
      example = example.replace /^\s+|\s+$/g, ''
      child = exec "./pyg.py #{language}", (error, result) ->
        if error
          console.log "Highlighting #{filename} failed:\n#{error.message}."
        else
          highlighted[index] = [example_name, result]
          writeResult()
      child.stdin.write example
      child.stdin.end()

watchFile = (filename, callback) ->
  callback filename
  fs.watchFile filename, (current, old) ->
    if +current.mtime != +old.mtime then callback filename

task 'watch', 'Watch all coffee files and compile them live to javascript', ->
  # jsREPL files.
  console.log 'Running JSREPL Watch'
  jsreplWatch = spawn 'cake', ['watch'], cwd: './jsrepl'
  jsreplWatch.stdout.on 'data', (d)->
    console.log '  ' + d.toString().slice(0, -1)

  # Our coffee files.
  coffee_to_watch = ['base.coffee', 'dom.coffee', 'repl.coffee', 'pager.coffee',
                     'session.coffee', 'languages.coffee', 'analytics.coffee']
  compileFile = (filename) ->
    try
      compileCoffee filename
    catch e
      console.log "Error compiling #{filename}: #{e}."
  for file in coffee_to_watch
    watchFile file, (filename) -> setTimeout (-> compileFile(filename)), 1

  # Our examples.
  for lang in fs.readdirSync 'langs'
    for examples_file in fs.readdirSync 'langs/' + lang
      if examples_file.match /\.txt$/
        file = "langs/#{lang}/#{examples_file}"
        do (file, lang) -> watchFile file, (filename) ->
          setTimeout (-> pygmentizeExample(lang, file)), 1
