const util = require('util');
const AWS = require('aws-sdk');
const https = require('https');
const S3 = new AWS.S3();

exports.handler = (event, context, callback) => {
    console.log("Reading input from event:\n", util.inspect(event, {depth: 5}));
    
    // Note: The authenticated URL that Transcribe provides to you only stays valid for a couple minutes
    var transcriptFileUri = event.transcriptFileUri;
    var transcriptFileName = event.transcriptFileName;
    
    // We have to use promises for both steps in the process because S3 operations are async
    getTranscript(transcriptFileUri).then(function(getTranscriptResponse) {
        console.log("Retrieved transcript:", getTranscriptResponse);
        return writeTranscriptToS3(getTranscriptResponse,transcriptFileName);
    }).then(function(filePathOnS3) {
        console.log("filePathOnS3 is " + filePathOnS3);
        var returnData = {
            transcriptFilePathOnS3: filePathOnS3,
            transcriptFileName: transcriptFileName
        };
        callback(null, returnData);
    }).catch(function(err) {
        console.error("Failed to write transcript file!", err);
        callback(err, null);
    })
};

function getTranscript(transcriptFileUri) {
    return new Promise(function(resolve, reject) {
        https.get(transcriptFileUri, res => {
            res.setEncoding("utf8");
            let body = "";
            res.on("data", data => {
                body += data;
            });
            res.on("end", () => {
                body = JSON.parse(body);
                let transcript = body.results.transcripts[0].transcript;
                console.log("Here's the transcript:\n", transcript);
                resolve(transcript);
            });
            res.on("error", (err) => {
                console.log("Error getting transcript:\n", err);
                reject(Error(err));
            });
        });
    });
}

function writeTranscriptToS3(transcript,transcriptFileName) {
    return new Promise(function(resolve, reject) {
        console.log("Writing transcript to S3 with the name" + transcriptFileName);
        let filePathOnS3 = 'transcripts/' + transcriptFileName + '.txt';
        var params = {
            Bucket: 'NAME OF YOUR BUCKET WHERE YOU WANT OUTPUT TO GO',
            Key: filePathOnS3,
            Body: transcript
        };
        var putObjectPromise = S3.putObject(params).promise();
        putObjectPromise.then(function(data) {
            console.log('Successfully put transcript file on S3');
            resolve(filePathOnS3);
        }).catch(function(err) {
            console.log("Error putting file on S3:\n", err);
            reject(Error(err));
        });
    });
}
