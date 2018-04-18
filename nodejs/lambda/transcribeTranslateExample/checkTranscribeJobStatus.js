const util = require('util');
const AWS = require('aws-sdk');
const transcribe = new AWS.TranscribeService;

exports.handler = (event, context, callback) => {
    console.log("Reading input from event:\n", util.inspect(event, {depth: 5}));
    
    var jobName = event.jobName;
    
    var params = {
        TranscriptionJobName: jobName
    }
    
    var request = transcribe.getTranscriptionJob(params, function(err, data) {
        if (err) {  // an error occurred
            console.log(err, err.stack);
            callback(err, null);
        } else {
            console.log(data);   // successful response, return job status
            var returnData = {
                jobName: jobName,
                jobStatus: data.TranscriptionJob.TranscriptionJobStatus,
                transcriptFileUri: data.TranscriptionJob.Transcript.TranscriptFileUri,
                transcriptFileName: jobName
            };
            callback(null, returnData);
        }
    });
    
};