const util = require('util');
const AWS = require('aws-sdk');
const rekognition = new AWS.Rekognition();

exports.handler = (event, context, callback) => {
    console.log("Reading input from event:\n", util.inspect(event, {depth: 5}));

    const srcBucket = event.s3Bucket;
    // Object key may have spaces or unicode non-ASCII characters.
    const srcKey = decodeURIComponent(event.s3Key.replace(/\+/g, " "));

    var params = {
        Image: {
            S3Object: {
                Bucket: srcBucket,
                Name: srcKey
            }
        },
        MaxLabels: 10,
        MinConfidence: 70
    };
    
    rekognition.detectLabels(params).promise().then(function (data) {
        data.s3Bucket = srcBucket;
        data.s3Key = srcKey;
        callback(null, data);
    }).catch(function (err) {
        callback(err);
    });

};