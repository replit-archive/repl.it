#!/usr/bin/env node

var fs = require('fs'),
    http = require('http'),
    path = require('path'),
    url = require('url'),
    spawn = require('child_process').spawn,
    port = process.argv[2] || 8888;

var CONTENT_TYPES = {
  'js': 'application/javascript; charset=utf-8',
  'css': 'text/css; charset=utf-8',
  'json': 'application/json; charset=utf-8',
  'html': 'text/html; charset=utf-8',
  'htm': 'text/html; charset=utf-8',
  'jpg': 'image/jpeg',
  'jpeg': 'image/jpeg',
  'png': 'image/png',
  'ico': 'image/x-icon',
  'gif': 'image/gif',
  'txt': 'text/plain; charset=utf-8'
};

function textResponse(res, code, txt) {
  txt = txt || '';
  res.writeHead(code, {"Content-Type": "text/plain"});
  res.end(txt);
}

var httpCb = function (req, res) {
  var uri = url.parse(req.url).pathname,
      filename = path.join(process.cwd(), uri);
      
  // HACK: Mobile browsers get special treatment!
  if (req.headers['user-agent'] &&
      req.headers['user-agent'].match(/iPhone|iPad|iPod|Android/i)) {
    if (uri === '/css/style.css') {
      // Automatically switch styles.
      uri = '/css/mobile.css';
    } else if (uri.indexOf('/lib/ace/') === 0) {
      // Ace has no content for mobile.
      textResponse(res, 204);
      return;
    }
  }
  // END HACK
  
  path.exists(filename, function (exists) {
    if (!exists) {
      textResponse(res, 404, "Page Not Found!\n");
      return;
    }
    
    if (fs.statSync(filename).isDirectory()) filename += '/index.html';
    
    fs.readFile(filename, 'binary', function (err, file) {
      if (err) {
        textResponse(res, 500, err + '\n');
        return;
      }
      var ext = path.extname(filename).slice(1);
      res.writeHead(200, {'Content-Type': CONTENT_TYPES[ext] || 'text/plain'});
      res.write(file, 'binary');
      res.end();
    });
  }); 
};

var watcher = spawn('cake', ['watch']);
watcher.stdout.pipe(process.stdout);

var server_started = false,
    start_timer;
watcher.stdout.on('data', function () {
  if (server_started) return;
  clearTimeout(start_timer);
  start_timer = setTimeout(function () {
    http.createServer(httpCb).listen(port, '0.0.0.0');
    console.log('repl.it server started at http://localhost:' + port + '/');
    server_started = true;
  }, 3000);
});

