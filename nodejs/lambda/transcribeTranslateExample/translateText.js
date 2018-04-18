// As the Translate service doesn't run ansynchronously, and the jobs take longer than 3 seconds (the default Lambda function timeout), set the timeout to 10 seconds to give Translate time to do the work.

const util = require('util');
const AWS = require('aws-sdk');
const S3 = new AWS.S3();
const Translate = new AWS.Translate();

exports.handler = (event, context, callback) => {
    console.log("Reading input from event:\n", util.inspect(event, {depth: 5}));
    
    var transcriptFileOnS3 = event.transcriptFilePathOnS3;
    var sourceTranscriptFileName = transcriptFileOnS3.split('/').pop();
    var languageToUse = event.languageToUse;
    
    // We have to use promises for all steps in the process because S3 operations are async
    getTranscriptFile(transcriptFileOnS3).then(function(getTranscriptResponse) {
        console.log("Retrieved transcript:", getTranscriptResponse);
        return translateText(getTranscriptResponse, languageToUse);
    }).then(function(translatedTextObj) {
        console.log("Here's the translation:\n", translatedTextObj);
        var returnData = {
            translatedText: translatedTextObj.TranslatedText,
            languageOfText: languageToUse,
            sourceTranscriptFileName: sourceTranscriptFileName
        }
        callback(null, returnData);
    }).catch(function(err) {
        console.error("Failure during translation!\n", err, err.stack);
        callback(err, null);
    })
};

function getTranscriptFile(transcriptFileOnS3) {
    return new Promise(function(resolve, reject) {
        var params = {
            Bucket: 'NAME OF YOUR BUCKET WHERE YOU WANT OUTPUT TO GO',
            Key: transcriptFileOnS3
        };
        var getObjectPromise = S3.getObject(params).promise();
        getObjectPromise.then(function(data) {
            console.log('Successfully retrieved transcript file from S3');
            // S3 returns the body of the result as a JS Buffer object, so we have to convert it
            let resultText = data.Body.toString('ascii');
            resolve(resultText);
        }).catch(function(err) {
            console.log("Error getting file from S3:\n", err);
            reject(Error(err));
        });
    });
}

function translateText(textToTranslate, languageToUse) {
    return new Promise(function(resolve, reject) {
        // Translate has a current maximum length for translation of 5000 bytes
        var maxLength = 4500;
        var trimmedString = textToTranslate.substr(0, maxLength);
        // We don't want to pass in words that are cut off in the middle
        trimmedString = trimmedString.substr(0, Math.min(trimmedString.length, trimmedString.lastIndexOf(" ")));
        console.log("We're going to translate:\n", trimmedString);
        var params = {
            SourceLanguageCode: 'en',
            TargetLanguageCode: languageToUse,
            Text: trimmedString
        };
        Translate.translateText(params, function(err, data) {
            if (err) {
                console.log("Error calling Translate");
                reject(Error(err));
            } else {
                console.log("Successful translation:\n");
                console.log(data);
                resolve(data);
            }
        });
    });
}