'use strict';

exports.handler = (event, context, callback) => {
    //console.log('Received event:', JSON.stringify(event, null, 2));
    var min = event.min ? event.min : 1;
    var max = event.max ? event.max : 100;
    var result = Math.floor(Math.random() * (max - min)) + min;
    callback(null, result);
};
