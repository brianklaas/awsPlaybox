exports.handler = (event, context, callback) => {
    var resultString = "";
    var timestamp = new Date();
    
    console.log('firstName =', event.firstName);
    console.log('lastName =', event.lastName);
    console.log('email =', event.email);
    
    for (var i=0; i < event.classes.length; i++) {
        console.log("In " + event.classes[i].courseNumber + ", your role is " + event.classes[i].role);
    }
    
    resultString = "Hello " + event.firstName + " " + event.lastName + 
        ". As of " + timestamp + ", you are currently enrolled in " + 
        event.classes.length + " courses.";
    callback(null, resultString);
};