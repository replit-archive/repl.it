repl.it
=======

An online environment for interactively exploring programming languages, based
on [jsREPL](https://github.com/replit/jsrepl).

Current Languages
-----------------

* JavaScript Variants
  * JavaScript
  * CoffeeScript
  * Kaffeine
  * Move
  * JavaScript.next

* Esoteric
  * Bloop
  * Brainfuck
  * LOLCODE
  * Unlambda
  * Emoticon

* Classic
  * Quick Basic
  * Forth

* Serious
  * Scheme
  * Lua
  * Python
  * Ruby (beta)

Getting the code
----------------

    git clone git://github.com/replit/repl.it.git
    cd repl.it
    git submodule update --init --recursive

Dependancies
------------

#### [node.js](http://nodejs.org/)  

    git clone git://github.com/joyent/node.git
    cd node
    git checkout v0.4.12
    mkdir ~/local
    ./configure --prefix=$HOME/local/node
    make
    make install
    echo 'export PATH=$HOME/local/node/bin:$PATH' >> ~/.profile
    echo 'export NODE_PATH=$HOME/local/node:$HOME/local/node/lib/node_modules' >> ~/.profile
    source ~/.profile

#### [npm](http://npmjs.org/)

    curl http://npmjs.org/install.sh | sh
   
#### [CoffeeScript](http://jashkenas.github.com/coffee-script/)
  
  Using npm:
  
    npm install -g coffee-script

#### [Pygments](http://pygments.org/)

  Using easy_install:
  
    easy_install Pygments
    
  Using pip:
  
    pip install Pygments

Running repl.it
---------------

repl.it comes bundled with a static node HTTP file server and a CoffeeScript file watcher & (re)-compiler:

    ./server.js 8888
    
repl.it can then be opened at http://localhost:8888/index.html.

License
-------

repl.it is available under the MIT license. External libraries used in repl.it
may use other licenses. Please check each library for its specific license.
