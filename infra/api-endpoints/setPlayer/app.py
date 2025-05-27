import json
import boto3
import datetime
import logging
from re import compile as re_compile


logger = logging.getLogger()
logger.setLevel(logging.INFO)

class Serializer:
    re_number = re_compile(r"^-?\d+?\.?\d*$")

    def serialize(self, data: any) -> dict:
        if isinstance(data, bool):
            return {'BOOL': data}
        if isinstance(data, (int, float)):
            return {'N': str(data)}
        if isinstance(data, type(None)) or not data:
            return {'NULL': True}
        if isinstance(data, (list, tuple)):
            return {'L': [self.serialize(v) for v in data]}
        if isinstance(data, set):
            if all([isinstance(v, str) for v in data]):
                return {'SS': data}
            if all([self.re_number.match(str(v)) for v in data]):
                return {'NS': [str(v) for v in data]}
        if isinstance(data, dict):
            return {'M': {k: self.serialize(v) for k, v in data.items()}}
        return {'S': str(data)}

    def deserialize(self, data: dict) -> dict:
        _out = {}
        if not data:
            return _out
        for k, v in data.items():
            if k in ('S', 'SS', 'BOOL'):
                return v
            if k == 'N':
                return float(v) if '.' in v else int(v)
            if k == 'NS':
                return [float(_v) if '.' in _v else int(_v) for _v in v]
            if k == 'M':
                return {_k: self.deserialize(_v) for _k, _v in v.items()}
            if k == 'L':
                return [self.deserialize(_v) for _v in v]
            if k == 'NULL':
                return None
            _out[k] = self.deserialize(v)
        return _out


def lambda_handler(event, context):
    # logger.info(event)

    data = json.loads(event['body'])
    data = Serializer().serialize(data)

    userId    = event['requestContext']['authorizer']['claims']['cognito:username']
    userEmail = event['requestContext']['authorizer']['claims']['email']
    userName  = event['requestContext']['authorizer']['claims']['name']

    created  = datetime.datetime.now()
    created  = created.strftime("%m/%d/%Y, %H:%M:%S")

    dynamodb = boto3.client('dynamodb')
    response = dynamodb.put_item(
        TableName="user", 
        Item={
            "UserId":    {'S': userId }, 
            "UserEmail": {'S': userEmail }, 
            "UpdatedAt": {'S': created },
            "Data": data
            }
    )

    return {
        "statusCode": 200,
        "headers": {
            "Content-Type": "application/json"
        },
        "body": json.dumps(response)
    }
