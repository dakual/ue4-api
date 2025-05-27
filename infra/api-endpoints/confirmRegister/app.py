import json
import boto3
import botocore.exceptions
import hmac
import hashlib
import base64
import logging
import uuid
import os

USER_POOL_ID  = os.environ.get("USER_POOL_ID")
CLIENT_ID     = os.environ.get("CLIENT_ID")
CLIENT_SECRET = os.environ.get("CLIENT_SECRET")

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

    client = boto3.client('cognito-idp')
    try:
        username = data['username']
        code     = data['code']
        response = client.confirm_sign_up(
            ClientId=CLIENT_ID,
            #SecretHash=get_secret_hash(username),
            Username=username,
            ConfirmationCode=code,
            ForceAliasCreation=False,
        )
    except client.exceptions.UserNotFoundException:
        return {
            'statusCode': 200,
            'body': json.dumps({"error": True, "message": "Username doesnt exists"})
        }
    except client.exceptions.CodeMismatchException:
        return {
            'statusCode': 200,
            'body': json.dumps({"error": True, "message": "Invalid Verification code"})
        }
    except client.exceptions.NotAuthorizedException:
        return {
            'statusCode': 200,
            'body': json.dumps({"error": True, "message": "User is already confirmed"})
        }
    except Exception as e:
        return {
            'statusCode': 200,
            'body': json.dumps({"error": True, "message": f"Unknown error {e.__str__()} "})
        }

    return {
        'statusCode': 200,
        'body': json.dumps({"error": False, "message": "Confirmed"})
    }