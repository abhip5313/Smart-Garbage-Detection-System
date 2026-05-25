import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('ImageRecognitionResults')

def convert_decimal(obj):
    if isinstance(obj, list):
        return [convert_decimal(i) for i in obj]
    elif isinstance(obj, dict):
        return {k: convert_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, Decimal):
        return float(obj)
    return obj

def lambda_handler(event, context):
    try:
        response = table.scan()
        items = response.get("Items", [])

        clean_items = convert_decimal(items)

        # ✅ DEBUG (optional but useful)
        print("Items count:", len(clean_items))

        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"   # 🔥 ADD THIS
            },
            "body": json.dumps(clean_items)          # (same ठेव)
        }

    except Exception as e:
        print("ERROR:", str(e))  # 🔥 ADD THIS

        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"   # 🔥 ADD THIS
            },
            "body": json.dumps({
                "error": str(e)
            })
        }