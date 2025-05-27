Build your AWS infra within seconds and destroy it within seconds using Terraform (IaC). Save time and money.

In summary, with this application you can create the all AWS services that what you needed in a very short time and start using them immediately.

Includes the following features:
- User sig-up
- User sign-in
- User forget password
- Store user game data
- Retrieve user game data
- User verification by Email
- GitLab CI

Note: This product does not contain blueprint or C++ code for unrealengine.

Features:
The following services will be created automatically when you run the application.

- AWS API Gateway
- AWS Cognito 
- AWS Lambda 
- AWS Simple Email Service (SES) 
- AWS Route53 
- AWS DynamoDB 
- AWS IAM 
- CloudFlare

Base requirements:
- AWS Key
- Terraform

Expert usage requirements:
- Terraform Cloud
- Git
- GitLab Account


We can run this application in two ways.
1. On your local
  a. without terraform cloud
  b. with terraform cloud (recomended)
2. On GitLac CI. (recomended)

Note 1: terraform stores the infrastructure that you have created in the terraform.tfstate file. if this file is lost or corrupted, you will no longer be able to access the infrastructure you have created. and you will have to make all changes manually via AWS consol. but if you use terraform cloud, terraform will store this file for you.

Note 2: If you have knowledge and experience with git, I recommend using GitLab CI. If you use it with git, you don't need to install anything on your computer, you can follow the version and control your application from anywhere.

Note 3: if you don't have a own domain name than you will use cogniton's default email service. and this has a daily email sending rate of 50.


Required envars:
export AWS_ACCESS_KEY_ID="CHANGE-ME"
export AWS_SECRET_ACCESS_KEY="CHANGE-ME"
export CLOUDFLARE_API_TOKEN="CHANGE-ME"

# required if you use terraform cloud
export TF_TOKEN="CHANGE-ME"

CLOUDFLARE_API_TOKEN this envar should be set even if you are not using Cloudflare. But you can set it with randam numbers or chars. So basically it should be exiest.


Setup AWS infrastructure:

1a. On your locally and without terraform cloud:
- Create an AWS key and secret from AWS console
- Install terraform
- Set envars
- check and update config.yml file
- go to project director via cli
- $ terraform init -upgrade
- $ terraform apply -auto-approve

1b. On your locally and with terraform cloud:
- Create an AWS key and secret from AWS console
- Install terraform
- Create terraform account and get a token
- uncomment 14-19 lines in the main.tf file
- check and update config.yml file
- Set envars with TF_TOKEN
- go to project director via cli
- $ terraform init -upgrade
- $ terraform apply -auto-approve

2. On GitLac CI.
- Create an AWS key and secret from AWS console
- uncomment 14-19 lines in the main.tf file
- check and update config.yml file
- install Git and push the code to the repository
- Set envars on the Gitlab
- Run pipeline. 

the following command to delete the infrastructure
- $ terraform destroy -auto-approve


API Usage:
1- /register
POST
{
  "username": "test.user@example.com",
  "name": "testuser",
  "password":"123456"
}

2- /login
POST
{
  "username": "test.user@example.com",
  "password": "123456"
}

3- /confirmRegister
POST
{
  "username": "test.user@example.com",
  "code": "XXXXXX"
}

4- /forgotPassword
POST
{
  "username": "test.user@example.com"
}

5- /confirmForgot
POST
{
  "username": "test.user@example.com",
  "password": "123456",
  "code": "XXXXX"
}

6- /resendCode
{
  "username": "test.user@example.com"
}

7- /setPlayer
Header: Authorization (this token is in the login response)
POST
{
  json object
}

8- /getPlayer
Header: Authorization (this token is in the login response)
GET
