import boto3
import botocore.exceptions
import hmac
import hashlib
import base64
import logging
import json
import os

DDB_USER_TABLE = os.environ.get("DDB_USER_TABLE")
USER_POOL_ID   = os.environ.get("USER_POOL_ID")
CLIENT_ID      = os.environ.get("CLIENT_ID")
CLIENT_SECRET  = os.environ.get("CLIENT_SECRET")

logger = logging.getLogger()
logger.setLevel(logging.INFO)


def get_secret_hash(username):
    msg = username + CLIENT_ID
    dig = hmac.new(str(CLIENT_SECRET).encode('utf-8'), 
        msg = str(msg).encode('utf-8'), digestmod=hashlib.sha256).digest()
    d2 = base64.b64encode(dig).decode()
    return d2

def lambda_handler(event, context):
    logger.info(event)
    data = json.loads(event['body'])

    for field in ["username", "password", "name"]:
        if not data.get(field):
            return {
                "statusCode": 200,
                "headers": {
                    "Content-Type": "application/json"
                },
                "body": json.dumps({"error": True, "message": f"{field} is not present"})
            }
        
    username = data['username']
    password = data['password']
    name     = data["name"]

    client   = boto3.client('cognito-idp')
    try:
        resp = client.sign_up(
            ClientId=CLIENT_ID,
            #SecretHash=get_secret_hash(username),
            Username=username,
            Password=password, 
            UserAttributes=[
            {
                'Name': "name",
                'Value': name
            },
            {
                'Name': "email",
                'Value': username
            }
            ],
            ValidationData=[
                {
                'Name': "email",
                'Value': username
            },
            {
                'Name': "custom:username",
                'Value': username
            }
            ])

    except client.exceptions.UsernameExistsException as e:
        return {
            'statusCode': 200,
            'body': json.dumps({"error": True, "message": "This username already exists"})
        }
    except client.exceptions.InvalidPasswordException as e:
        return {
            'statusCode': 200,
            'body': json.dumps({"error": True, "message": "Password should have Caps, Special chars, Numbers"})
        }
    except client.exceptions.UserLambdaValidationException as e:
        return {
            'statusCode': 200,
            'body': json.dumps({"error": True, "message": "Email already exists"})
        }
    except Exception as e:
        return {
            'statusCode': 200,
            'body': json.dumps({"error": True, "message": str(e)})
        }
    

    return {
        'statusCode': 200,
        'body': json.dumps({"error": False, "message": "Please confirm your signup, check Email for validation code"})
    }
