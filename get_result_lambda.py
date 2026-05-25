import json
import boto3
from decimal import Decimal

dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table('ImageRecognitionResults')


# ================= DECIMAL FIX =================
def convert_decimal(obj):
    if isinstance(obj, list):
        return [convert_decimal(i) for i in obj]
    elif isinstance(obj, dict):
        return {k: convert_decimal(v) for k, v in obj.items()}
    elif isinstance(obj, Decimal):
        return float(obj)
    else:
        return obj


# ================= MAIN =================
def lambda_handler(event, context):

    try:
        # 🔥 GET PARAMS
        params = event.get('queryStringParameters') or {}
        image = params.get('image')

        if not image:
            return {
                "statusCode": 400,
                "headers": {
                    "Access-Control-Allow-Origin": "*"
                },
                "body": json.dumps({
                    "error": "Missing image parameter"
                })
            }

        print("Fetching result for:", image)

        # ================= DYNAMODB =================
        response = table.get_item(
            Key={
                "ImageID": image
            }
        )

        # 🔥 NOT READY YET
        if 'Item' not in response:
            return {
                "statusCode": 200,
                "headers": {
                    "Access-Control-Allow-Origin": "*"
                },
                "body": json.dumps({
                    "severity": "Processing"
                })
            }

        item = response['Item']

        # 🔥 CLEAN DECIMAL
        clean_item = convert_decimal(item)

        # ================= SAFE RESPONSE =================
        result = {
            "ImageID": clean_item.get("ImageID"),
            "labels": clean_item.get("labels", []),
            "garbageTags": clean_item.get("garbageTags", []),
            "severity": clean_item.get("severity", "-"),
            "message": clean_item.get("message", "-"),
            "location": clean_item.get("location", {}),
            "address": clean_item.get("address", "-"),  # NEW: Address added
            "imageUrl": clean_item.get("imageUrl", ""),
            "timestamp": clean_item.get("timestamp", "-")
        }

        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Content-Type": "application/json"
            },
            "body": json.dumps(result)
        }

    except Exception as e:
        print("ERROR:", str(e))

        return {
            "statusCode": 500,
            "headers": {
                "Access-Control-Allow-Origin": "*"
            },
            "body": json.dumps({
                "error": str(e)
            })
        }