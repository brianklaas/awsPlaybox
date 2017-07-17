# The AWS Playbox: Demos for "Level Up Your Web Apps With Amazon Web Services"

This repo contains the sample app used during my presentation "Level Up Your Web Apps With Amazon Web Services." It contains sample CFML and Python code for working with a number of AWS services.

There are three requirements for getting these demos working. I know that sounds like a lot, but we're dealing with a series of external services in multiple lanaguages in these demos, and each must be set up correctly.

1. Add the AWS SDK .jar and related files to your CF install.
2. Set up your own AWS credentials and add them to awsCredentials.cfc.
3. Set up your own copies of the required resources in SNS, Lambda, DynamoDB, S3, and Step Functions.

### Requirement One: The AWS SDK .jar and Related Files

The demos in this repo require that you have the following .jar files in your /coldfusion/lib/ directory:

- aws-java-sdk-1.11.120 or later
- jackson-annotations
- jackson-core
- jackson-databind
- joda-time

All of these files can be downloaded from [https://aws.amazon.com/sdk-for-java/](https://aws.amazon.com/sdk-for-java/) Files other than the actual SDK .jar itself can be found in the /third-party directory within the SDK download.

### Requirement Two: Your Own AWS Credentials

You have to create your own AWS account and provide both the AccessKey and SecretKey in model/awsCredentials.cfc.

The account for which you are providing credentials must also have permissions for the following services:

- SNS
- Lambda
- CloudWatch (for Lambda logging)
- Rekognition
- S3 (for Rekognition)
- Step Functions
- DynamoDB

For more infomration about IAM accounts, roles, and permissions, please review the [IAM guide](http://docs.aws.amazon.com/IAM/latest/UserGuide/introduction.html).

### Requirement Three: Your Own AWS Resources

You need to set up the following resources within AWS for these demos to work:

1. SNS - create a topic to which messsages can be sent. The ARN (Amazon Resource Name, like a URL) of this topic must be added to application.cfc.
2. Lambda - create a Lambda function using the code in nodejs/lambda/lambda-returnDataToCaller.js. The Lambda runtime should be NodeJS 4.3 or later, and you do not need to configure a trigger for the function, as it will be invoked from this application. The ARN of the function must be added to application.cfc. 
3. DynamoDB - create a DynamoDB table with a partition (primary) key of "userID" (String) and a sort key (range key) of "epochTime" (Number). The table name must be added to application.cfc.
4. Rekognition - add photos for Rekognition to analyze. There's a separate list of photos for matching faces, and a list for generating labels (image analysis). These photos and the name of the S3 bucket in which they can be found need to be added to the top of rekognition.cfm.
4. Step Functions - You must first create two Lambda functions using the code in nodejs/lambda/ -- generateRandomNumber.js and detectLabelsForImage.js. The ARNs of those functions must be added to stateMachines/choiceDemoStateMachine.json. Additionally, the name of the S3 bucket and the path to the photos that will be analyzed as part of this step function must be added to stateMachines/choiceDemoStateMachine.json. Once you've added all the required information, use stateMachines/choiceDemoStateMachine.json to create a new Step Function state machine in the AWS Console.

Remember, the AWS docs are pretty great. Use the [Java API Reference](http://docs.aws.amazon.com/AWSJavaSDK/latest/javadoc/index.html) often, as it'll tell you almost everything you need to know for working with a particular AWS service.

Enjoy!

### P.S.: Python

There are a number of Python examples in this repo. You can get them running pretty easily by:

1. Installing boto via pip
2. Using your own ARNs as noted in the Python code in the /python directory of the repo
3. Setting python/pythonInvoke.sh to run as an executable on your machine

Boto makes it very easy to use AWS from Python and acts as the AWS-approved and supported SDK for Python.
