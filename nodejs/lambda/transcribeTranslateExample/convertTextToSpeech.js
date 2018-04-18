// As speaking jobs can take a few seconds, the default Lambda function timeout will not be enough. Set the timeout to 10 seconds to give Polly time to do the work.

const util = require('util');
const AWS = require('aws-sdk');
const Polly = new AWS.Polly();
const S3 = new AWS.S3();

exports.handler = (event, context, callback) => {
    console.log("Reading input from event:\n", util.inspect(event, {depth: 5}));
    
    var textToSpeak = event.textToSpeak;
    var languageOfText = event.languageOfText;
    var fileNameForOutput = event.transcriptFileName;

    // We have to use promises for both steps in the process because S3 operations are async
    makeMP3FromText(textToSpeak, languageOfText).then(function(makeMP3Result) {
        console.log("Result from speaking transcript:", makeMP3Result);
        return writeFileToS3(makeMP3Result.AudioStream, languageOfText, fileNameForOutput);
    }).then(function(mp3FileNameOnS3) {
        console.log("mp3FileNameOnS3:" + mp3FileNameOnS3);
        var returnData = {};
        returnData["mp3FileNameOnS3-"+languageOfText] = mp3FileNameOnS3
        callback(null, returnData);
    }).catch(function(err) {
        console.error("Failed to generate MP3!", err);
        callback(err, null);
    })
};

function makeMP3FromText(textToSpeak, languageOfText) {
    return new Promise(function(resolve, reject) {
        console.log("Making an MP3 in the language: " + languageOfText);
        var voiceToUse = 'Ivy';
        // Polly has a current maximum character length of 3000 characters
        var maxLength = 2900;
        var trimmedText = textToSpeak.substr(0, maxLength);
        switch(languageOfText) {
            case 'es':
                voiceToUse = (Math.random() >= 0.5) ? "Penelope" : "Miguel";
                break;
            case 'fr':
                voiceToUse = (Math.random() >= 0.5) ? "Celine" : "Mathieu";
                break;
            case 'de':
                voiceToUse = (Math.random() >= 0.5) ? "Vicki" : "Hans";
                break;
        }
        var params = {
            OutputFormat: "mp3",
            SampleRate: "8000",
            Text: trimmedText,
            VoiceId: voiceToUse
        }
        var speakPromise = Polly.synthesizeSpeech(params).promise();
        speakPromise.then(function(data) {
            console.log('Successfully generated MP3 file');
            resolve(data);
        }).catch(function(err) {
            console.log("Error generating MP3 file:\n", err);
            reject(Error(err));
        });
    });
}

function writeFileToS3(mp3AudioStream, languageOfText, fileNameForOutput) {
    return new Promise(function(resolve, reject) {
        let audioFileName = fileNameForOutput;
        // Remove .txt from the file name, if it exists
        if (audioFileName.split('.').pop() == 'txt') {
            audioFileName = audioFileName.slice(0, -4);
        }
        let filePathOnS3 = 'audio/' + audioFileName + '-' + languageOfText + '.mp3';
        var params = {
            Bucket: 'NAME OF YOUR BUCKET WHERE YOU WANT OUTPUT TO GO',
            Key: filePathOnS3,
            Body: mp3AudioStream,
            ContentType: 'audio/mpeg3'
        };
        var putObjectPromise = S3.putObject(params).promise();
        putObjectPromise.then(function(data) {
            console.log('Successfully put audio file on S3');
            resolve(filePathOnS3);
        }).catch(function(err) {
            console.log("Error putting file on S3:\n", err);
            reject(Error(err));
        });
    });
}