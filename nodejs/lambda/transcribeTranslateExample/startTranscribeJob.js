const util = require('util');
const AWS = require('aws-sdk');
const transcribe = new AWS.TranscribeService;

exports.handler = (event, context, callback) => {
    console.log("Reading input from event:\n", util.inspect(event, {depth: 5}));
    
    // The job name must be unique to your account
    var jobName = 'confDemo-' + Date.now();
    var srcFile = event.urlOfFileOnS3;
    var mediaType = event.mediaType;
    var returnData = {
        jobName: jobName
    }
    
    var params = {
        LanguageCode: 'en-US',
        Media: {
            MediaFileUri: srcFile
        },
        MediaFormat: mediaType,
        TranscriptionJobName: jobName
    }
    
    transcribe.startTranscriptionJob(params, function(err, data) {
        if (err) {
            console.log(err, err.stack);
            callback(err, null)
        } else {
            console.log(data);           // successful response
            callback(null, returnData);
        }
    });
    
};