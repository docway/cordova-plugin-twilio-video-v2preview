var http = require('http');
var https = require('https');
var fs = require('fs');
var decompress = require('decompress');
var decompressUnzip = require('decompress-unzip');

function getFile(url, path, cb) {
    var http_or_https = http;
    if (/^https:\/\//.test(url)) {
        http_or_https = https;
    }
    http_or_https.get(url, function(response) {
        var headers = JSON.stringify(response.headers);
        switch(response.statusCode) {
            case 200:
                var file = fs.createWriteStream(path);
                response.on('data', function(chunk){
                    file.write(chunk);
                }).on('end', function(){
                    file.end();
                    cb(null);
                });
                break;
            case 301:
            case 302:
            case 303:
            case 307:
                getFile('https://github.com' + response.headers.location, path, cb);
            default:
                cb(new Error('Server responded with status code ' + response.statusCode));
        }

    })
    .on('error', function(err) {
        cb(err);
    });
}

getFile('https://github.com/twilio/twilio-video-ios/releases/download/2.5.3/TwilioVideo.framework.zip', 'TwilioVideo.framework.zip', function(err) {
  if (err === null) {
    decompress('TwilioVideo.framework.zip', 'src/ios/frameworks', {
        plugins: [
            decompressUnzip()
        ]
    }).then(() => {
        fs.unlink('TwilioVideo.framework.zip');
    });
  }
});
