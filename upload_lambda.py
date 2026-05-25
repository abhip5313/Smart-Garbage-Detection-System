import json
import boto3
import uuid
import os
import urllib.parse
import time

s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
table = dynamodb.Table("ImageRecognitionResults")

BUCKET_NAME = os.environ.get("BUCKET_NAME")


def lambda_handler(event, context):

    # ================= CORS (OPTIONS) =================
    if event.get("requestContext", {}).get("http", {}).get("method") == "OPTIONS":
        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "*",
                "Access-Control-Allow-Methods": "GET,POST,OPTIONS"
            },
            "body": ""
        }

    try:
        # ================= QUERY PARAMS =================
        query = event.get("queryStringParameters") or {}

        lat = str(query.get("lat", "0")).strip()
        lon = str(query.get("lon", "0")).strip()

        raw_msg = query.get("msg", "No message")
        message = urllib.parse.unquote_plus(raw_msg)

        content_type = query.get("content_type", "image/jpeg")

        # ================= ADDRESS =================
        raw_address = query.get("address", "-")
        address = urllib.parse.unquote_plus(raw_address)

        # ================= EXTENSION FIX =================
        extension = content_type.split("/")[-1]
        if extension == "webp":
            extension = "jpeg"

        # ================= UNIQUE FILE NAME =================
        unique_id = str(uuid.uuid4())
        file_name = f"{unique_id}.{extension}"

        print("Creating upload URL for:", file_name)
        print("Content-Type:", content_type)
        print("Location:", lat, lon)
        print("Address:", address)

        # ================= PRESIGNED URL =================
        upload_url = s3.generate_presigned_url(
            ClientMethod='put_object',
            Params={
                'Bucket':      BUCKET_NAME,
                'Key':         file_name,
                'ContentType': 'image/jpeg',
            },
            ExpiresIn=300
        )

        # ================= PRE-SAVE TO DYNAMODB =================
        # ✅ location/address/message इथेच save — process lambda overwrite करणार नाही
        table.put_item(
            Item={
                "ImageID":     file_name,
                "timestamp":   str(__import__('datetime').datetime.now()),
                "severity":    "Processing",
                "labels":      [],
                "garbageTags": [],
                "message":     message,
                "location": {
                    "lat": lat,
                    "lon": lon
                },
                "address":  address,
                "imageUrl": f"https://{BUCKET_NAME}.s3.amazonaws.com/{file_name}",
                "ttl":      int(time.time()) + 7 * 24 * 60 * 60
            }
        )

        print("Pre-saved to DynamoDB ✅")

        return {
            "statusCode": 200,
            "headers": {
                "Access-Control-Allow-Origin":  "*",
                "Access-Control-Allow-Headers": "*",
                "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
                "Content-Type": "application/json"
            },
            "body": json.dumps({
                "upload_url": upload_url,
                "image":      file_name
            })
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