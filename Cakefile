# Watches all coffee files and compiles them live to Javascript.
fs = require 'fs'
{spawn, exec} = require 'child_process'
coffee = require 'coffee-script'

INCLUDES = ['images', 'lib']
LIBRARIES = ['lib/jqconsole-2.7.4.min.js', 'lib/bootstrap-tooltip.js', 'lib/page.js']
CSS = ['style.css', 'mobile.css', 'print.css', 'ansi.css']
APP_FILES = ['base.coffee', 'browser-check.coffee', 'dom.coffee',
             'repl.coffee', 'pager.coffee', 'router.coffee', 'session.coffee',
             'languages.coffee', 'analytics.coffee']
JS_MINIFIER = "uglifyjs -nc --unsafe "
CSS_MINIFIER = "java -jar ./jsrepl/tools/yuicompressor-2.4.6/build/yuicompressor-2.4.6.jar "

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
      
  exec 'which python2', (err, py_path) ->
    if err
      PYTHON = 'python'
    else
      PYTHON = py_path
    
    for [example_name, example], index in examples
      do (example_name, example, index) ->
        example = example.replace /^\s+|\s+$/g, ''
        child = exec "#{PYTHON} pyg.py #{language}", (error, result) ->
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
  jsreplWatch.stdout.on 'data', (d) ->
    console.log '  ' + d.toString().slice(0, -1)

  # Our coffee files.
  coffee_to_watch = [].concat APP_FILES
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

task 'bake', 'Build a final folder ready for deployment', ->
  console.log 'Baking repl.it.'

  gzip = ->
    console.log 'GZipping.'
    cmd = 'for file in `find . -type f`; do gzip -c -9 $file > $file.gz; done;'
    exec cmd, cwd: 'build'

  updateHTML = ->
    console.log 'Updating HTML.'
    html = fs.readFileSync 'index.html', 'utf8'
    html = html.replace /<!--BAKED\b([^]*?)\bUNBAKED-->[^]*?<!--\/UNBAKED-->/g, '$1'
    html = html.replace /{{CACHE_BUSTER}}/g, Date.now()
    fs.writeFileSync 'build/index.html', html
    gzip()

  minifyCSS = ->
    console.log 'Minifying CSS.'
    fs.mkdirSync 'build/css', 0o755
    minify = (i) ->
      return updateHTML() if not CSS[i]?
      exec "#{CSS_MINIFIER} -o build/css/#{CSS[i]} css/#{CSS[i]}", -> minify i + 1
    minify 0

  buildCore = ->
    console.log 'Baking core JS.'
    contents = (fs.readFileSync(lib, 'utf8') for lib in LIBRARIES)
    for file in APP_FILES
      compileCoffee file
      contents.push fs.readFileSync file.replace(/\.coffee$/, '.js'), 'utf8'
    fs.writeFileSync 'build/repl.it.tmp.js', contents.join ';\n'
    exec "#{JS_MINIFIER} build/repl.it.tmp.js", (error, minified) ->
      if error
        console.log 'Minifying repl.it failed.'
        process.exit 1
      fs.writeFileSync 'build/repl.it.js', minified
      exec 'rm build/repl.it.tmp.js', minifyCSS

  exec 'rm -rf build', ->
    fs.mkdirSync 'build', 0o755
    console.log 'Baking jsREPL.'
    subcake = spawn 'cake', ['bake'], cwd: './jsrepl'
    subcake.stdout.on 'data', (d) ->
      console.log '  ' + d.toString().slice(0, -1).replace '\n', '\n  '
    subcake.on 'exit', ->
      fs.mkdirSync 'build/jsrepl', 0o755
      exec 'cp -r jsrepl/build/* build/jsrepl', ->
        exec "cp -r #{INCLUDES.join ' '} build", ->
          console.log 'Highlighting examples.'
          fs.mkdirSync 'build/langs', 0o755
          for lang in fs.readdirSync 'langs'
            for examples_file in fs.readdirSync 'langs/' + lang
              if examples_file.match /\.txt$/
                file = "langs/#{lang}/#{examples_file}"
                pygmentizeExample lang, file
          exec 'cp -r langs/* build/langs', buildCore

task 'langs-html', ->
  {Languages} = require './languages.coffee'
  language_group = (data) ->
    {category, languages} = data
    """

    <div class="language-group">
      <h3 class="language-group-header">#{category}</h3>
      <ul>
        #{(language_entry(language) for language in languages).join('')}
      </ul>
    </div>

    """

  language_entry = (data) ->
    {name, shortcut, system_name, tagline} = data
    shortcut_index = name.indexOf(shortcut)
    """

    <li>
      <a href="/languages/#{system_name}"><b>#{name[0...shortcut_index]}<em>#{shortcut}</em>#{name[shortcut_index + 1...]}:</b>&nbsp;
        #{tagline}</a>
    </li>
    
    """

  render = ->
    html = []
    categories_order = [
      'Classic'
      'Practical'
      'Esoteric'
      'Web'
    ]
    template_data =
      Classic:
        category: 'Classic'
        languages: ['QBasic', 'Forth']
      Practical:
        category: 'Practical'
        languages: ['Ruby', 'Python', 'Lua', 'Scheme']
      Esoteric:
        category: 'Esoteric'
        languages: ['Emoticon', 'Brainfuck', 'LOLCODE', 'Unlambda', 'Bloop']
      Web:
        category: 'Web'
        languages: ['JavaScript', 'Traceur', 'Move', 'Kaffeine', 'CoffeeScript', 'Roy']

    for _, category of template_data
      for lang_name, index in category.languages
        lang = Languages[lang_name.toLowerCase()]
        lang.system_name = lang_name
        category.languages[index] = lang
    for category in categories_order
      html.push language_group template_data[category]

    return html.join ''

  console.log render()
