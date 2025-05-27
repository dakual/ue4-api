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
  dig = hmac.new(
    str(CLIENT_SECRET).encode('utf-8'),
    msg = str(msg).encode('utf-8'),
    digestmod=hashlib.sha256).digest()
  d2 = base64.b64encode(dig).decode()
  return d2

def initiate_auth(client, username, password):
    secret_hash = get_secret_hash(username)
    try:
        resp = client.admin_initiate_auth(
                    UserPoolId=USER_POOL_ID,
                    ClientId=CLIENT_ID,
                    AuthFlow='ADMIN_NO_SRP_AUTH',
                    AuthParameters={
                        'USERNAME': username,
                        # 'SECRET_HASH': secret_hash,
                        'PASSWORD': password,
                    },
                ClientMetadata={
                    'username': username,
                    'password': password,
                })
    except client.exceptions.NotAuthorizedException:
        return None, "The username or password is incorrect"
    except client.exceptions.UserNotConfirmedException:
        return None, "User is not confirmed"
    except client.exceptions.UserNotFoundException:
        return None, "User does not exist"
    except Exception as e:
        return None, e.__str__()
    
    return resp, None


def lambda_handler(event, context):
    logger.info(event)
    
    data   = json.loads(event['body'])
    client = boto3.client('cognito-idp')

    for field in ["username", "password"]:
        if data.get(field) is None:
            return {
                'statusCode': 200,
                'body': json.dumps({"error": True, "message": f"{field} is required"})
            }
        
    username = data['username']
    password = data['password']
    resp, msg = initiate_auth(client, username, password)
    if msg != None:
        return {
            'statusCode': 200,
            'body': json.dumps({"error": True, "message": msg})
        }   

    if resp.get("AuthenticationResult"):
        return {
            'statusCode': 200,
            'body': json.dumps({
                "error": False,
                "id_token": resp["AuthenticationResult"]["IdToken"],
                "refresh_token": resp["AuthenticationResult"]["RefreshToken"],
                "access_token": resp["AuthenticationResult"]["AccessToken"],
                "expires_in": resp["AuthenticationResult"]["ExpiresIn"],
                "token_type": resp["AuthenticationResult"]["TokenType"]
            })}
    else: 
        return {
            'statusCode': 200,
            'body': json.dumps({"error": True, "message": "error-2"})
        }   