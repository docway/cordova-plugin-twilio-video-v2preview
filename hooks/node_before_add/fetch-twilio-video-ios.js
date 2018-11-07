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

getFile('https://github-production-release-asset-2e65be.s3.amazonaws.com/114014791/a351ab80-d2cc-11e8-856d-ac9ec2dfc697?X-Amz-Algorithm=AWS4-HMAC-SHA256&X-Amz-Credential=AKIAIWNJYAX4CSVEH53A%2F20181107%2Fus-east-1%2Fs3%2Faws4_request&X-Amz-Date=20181107T202335Z&X-Amz-Expires=300&X-Amz-Signature=cdcb51f6b8c5ec3234d8a6bb92b1a685caa31546f5d4ab86325a26ec1e302968&X-Amz-SignedHeaders=host&actor_id=43139160&response-content-disposition=attachment%3B%20filename%3DTwilioVideo.framework.zip&response-content-type=application%2Foctet-stream', 'TwilioVideo.framework.zip', function(err) {
  if (err === null) {
    decompress('TwilioVideo.framework.zip', 'src/ios/frameworks', {
        plugins: [
            decompressUnzip()
        ]
    }).then(() => {
        fs.unlink('TwilioVideo.framework.zip', (error) => {
        });
    });
  }
});
