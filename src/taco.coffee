# **taco** is a quick-and-dirty, hundred-line-long, literate-programming-style
# documentation generator. It produces HTML that displays your comments
# alongside your code. Comments are passed through
# [Markdown](http://daringfireball.net/projects/markdown/syntax), and code is
# passed through [Pygments](http://pygments.org/) syntax highlighting.
# This page is the result of running taco against its own source file.
#
# If you install taco, you can run it from the command-line:
#
#     $ taco src/*.coffee
#
# ...will generate an HTML documentation page for each of the named source files,
# with a menu linking to the other pages, saving it into a `docs` folder.
#
# The [source for taco](http://github.com/fat/taco) is available on GitHub,
# and released under the MIT license.
#
# To install taco, first make sure you have [Node.js](http://nodejs.org/),
# [Pygments](http://pygments.org/) (install the latest dev version of Pygments
# from [its Mercurial repo](http://dev.pocoo.org/hg/pygments-main)), and
# [CoffeeScript](http://coffeescript.org/). Then, with NPM:
#
#     $ sudo npm install taco
#

# ### Contents
# - [Introduction](#)
#   - [Partners in Crime](#section-3)
#   - [How it works](#section-4)
#   - [Original Docco](http://jashkenas.github.com/docco/)

# ### Partners in Crime:
#
# * If **Node.js** doesn't run on your platform, or you'd prefer a more
# convenient package, get [Ryan Tomayko](http://github.com/rtomayko)'s
# [Rocco](http://rtomayko.github.com/rocco/rocco.html), the Ruby port that's
# available as a gem.
#
# * If you're writing shell scripts, try
# [Shocco](http://rtomayko.github.com/shocco/), a port for the **POSIX shell**,
# also by Mr. Tomayko.
#
# * If Python's more your speed, take a look at
# [Nick Fitzgerald](http://github.com/fitzgen)'s [Pycco](http://fitzgen.github.com/pycco/).
#
# * For **Clojure** fans, [Fogus](http://blog.fogus.me/)'s
# [Marginalia](http://fogus.me/fun/marginalia/) is a bit of a departure from
# "quick-and-dirty", but it'll get the job done.
#
# * **Lua** enthusiasts can get their fix with
# [Robert Gieseke](https://github.com/rgieseke)'s [Locco](http://rgieseke.github.com/locco/).
#
# * And if you happen to be a **.NET**
# aficionado, check out [Don Wilson](https://github.com/dontangg)'s
# [Nocco](http://dontangg.github.com/nocco/).

# ### How it works:
#
# Taco parses your src files for comments. Taco is more about api documentation, and less about code commenting.
# This is how taco expects your comments to be setup.
#
# - 1st section - Introduction
# - 2nd section - Table of Contents (a nest ul list for navigation)
# - All subsequent sections are to be used for relevant api docs
#
# If you pass multiple files to taco, it will automatically add teh appropriate links to the topbar navigation.
# For example:
#
#     $ taco js/*.js # this will add a link to the topbar for each navigation item generated

generate_documentation = (source, callback) ->
  fs.readFile source, "utf-8", (error, code) ->
    throw error if error
    sections = parse source, code
    highlight source, sections, ->
      generate_html source, sections
      callback()

parse = (source, code) ->
  lines    = code.split '\n'
  sections = []
  language = get_language source
  has_code = docs_text = code_text = ''

  save = (docs, code) ->
    sections.push docs_text: docs, code_text: code

  for line in lines
    if line.match(language.comment_matcher) and not line.match(language.comment_filter)
      if has_code
        save docs_text, code_text
        has_code = docs_text = code_text = ''
      docs_text += line.replace(language.comment_matcher, '') + '\n'
    else
      has_code = yes
      code_text += line + '\n'
  save docs_text, code_text
  sections

highlight = (source, sections, callback) ->
  language = get_language source
  pygments = spawn 'pygmentize', ['-l', language.name, '-f', 'html', '-O', 'encoding=utf-8,tabsize=2']
  output   = ''

  pygments.stderr.addListener 'data',  (error)  ->
    console.error error.toString() if error

  pygments.stdin.addListener 'error',  (error)  ->
    console.error "Could not use Pygments to highlight the source."
    process.exit 1

  pygments.stdout.addListener 'data', (result) ->
    output += result if result

  pygments.addListener 'exit', ->
    output = output.replace(highlight_start, '').replace(highlight_end, '')
    fragments = output.split language.divider_html
    for section, i in sections
      section.code_html = highlight_start + fragments[i] + highlight_end
      section.docs_html = showdown.makeHtml section.docs_text
    callback()

  if pygments.stdin.writable
    pygments.stdin.write((section.code_text for section in sections).join(language.divider_text))
    pygments.stdin.end()

generate_html = (source, sections) ->
  title = path.basename source
  dest  = destination source
  html  = taco_template {
    title: title, sections: sections, sources: sources, path: path, destination: destination
  }
  console.log "taco: #{source} -> #{dest}"
  fs.writeFile dest, html

fs       = require 'fs'
path     = require 'path'
showdown = require('./../vendor/showdown').Showdown
{spawn, exec} = require 'child_process'

languages =
  '.coffee':
    name: 'coffee-script', symbol: '#'
  '.js':
    name: 'javascript', symbol: '//'
  '.rb':
    name: 'ruby', symbol: '#'
  '.py':
    name: 'python', symbol: '#'

for ext, l of languages

  l.comment_matcher = new RegExp('^\\s*' + l.symbol + '\\s?')

  l.comment_filter = new RegExp('(^#![/]|^\\s*#\\{)')

  l.divider_text = '\n' + l.symbol + 'DIVIDER\n'

  l.divider_html = new RegExp('\\n*<span class="c1?">' + l.symbol + 'DIVIDER<\\/span>\\n*')

get_language = (source) -> languages[path.extname(source)]

destination = (filepath) ->
  'docs/' + path.basename(filepath, path.extname(filepath)) + '.html'

ensure_directory = (dir, callback) ->
  exec "mkdir -p #{dir}", -> callback()

template = (str) ->
  new Function 'obj',
    'var p=[],print=function(){p.push.apply(p,arguments);};' +
    'with(obj){p.push(\'' +
    str.replace(/[\r\t\n]/g, " ")
       .replace(/'(?=[^<]*%>)/g,"\t")
       .split("'").join("\\'")
       .split("\t").join("'")
       .replace(/<%=(.+?)%>/g, "',$1,'")
       .split('<%').join("');")
       .split('%>').join("p.push('") +
       "');}return p.join('');"

taco_template  = template fs.readFileSync(__dirname + '/../resources/taco.jst').toString()

taco_styles    = fs.readFileSync(__dirname + '/../resources/taco.css').toString()

highlight_start = '<div class="highlight"><pre>'

highlight_end   = '</pre></div>'

sources = process.ARGV.sort()
if sources.length
  ensure_directory 'docs', ->
    fs.writeFile 'docs/taco.css', taco_styles
    files = sources.slice(0)
    next_file = -> generate_documentation files.shift(), next_file if files.length
    next_file()

