# nsync-fs
This module is used by the [Learn IDE](https://github.com/learn-co/learn-ide), via the [Learn IDE Tree](https://github.com/learn-co/learn-ide-tree) package, to mirror a remote filesystem on the client's local machine. This is accomplished by both by maintaining a virtual filesystem that reflects the remote's full tree along with some data about each node (exposed by the included `nsync.fs` module), and by copying the remote files to the local disk. All of this is synchronized over a websocket connection, which can be shared by multiple processes via [atom-socket](https://github.com/learn-co/nsync-fs).

### Installation
```shell
$ npm install nsync-fs --save
```

### Usage
Configure, then wait for the primary node to be set before using the `nsync.fs` module:
```javascript
var nsync = require('nsync-fs');

nsync.configure({
  localRoot: '/path/to/local-mirror',
  connection: {
    url: 'wss://ide.learn.co/file_sync_server'
  }
});

nsync.onDidSetPrimary(function(data) {
  var fs = nsync.fs; 
  var stat = fs.statSync('/some/remote/path'); // stat object of remote path
})
```

Custom commands can be passed from the server to the client, to be handled like this:
```javascript
nsync.onDidReceiveCustomCommand(function(commandPayload) {
  console.log('Custom command received:', commandPayload);
});
```

For example, the Learn IDE's server watches a file on the remote filesystem, `~/.custom_commands.log`, which can be written to by any process running on the host. It only requires that the write be a line of valid JSON with a `command` key:

```json
{"command": "atom_open", "path": "/some/remote/path"}
```

The server then sends this line to the client, where it is parsed into an object and passed along to the callbacks defined with `onDidReceiveCustomCommand`. For more on this, see how custom commands are handled in the [Learn IDE Tree](https://github.com/learn-co/learn-ide-tree/blob/f3314a482cc19b42bcc99f9fc40c6b38a9ef0dbc/lib/nsync/nsync-helper.coffee#L163-L164).

### Development
This project is written in coffescript, use the default `gulp` task to start watching `./src/` and transpiling to `./lib/`:
```shell
$ git clone https://github.com/learn-co/nsync-fs.git
$ cd nsync-fs
$ npm install
$ npm link
$ gulp
```
