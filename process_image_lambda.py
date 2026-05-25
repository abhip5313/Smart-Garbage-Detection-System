import boto3
from datetime import datetime
import urllib.parse
import time

# AWS clients
s3 = boto3.client('s3')
dynamodb = boto3.resource('dynamodb')
rekognition = boto3.client('rekognition')

# DynamoDB table
table = dynamodb.Table("ImageRecognitionResults")


# ================= SEVERITY =================
def classify_severity(labels):
    garbage_keywords = ["trash", "garbage", "waste", "pollution", "plastic"]
    count = sum(1 for l in labels if l.lower() in garbage_keywords)

    if count == 0:
        return "Clean"
    elif count <= 2:
        return "Low"
    elif count <= 5:
        return "Medium"
    else:
        return "High"


# ================= MAIN =================
def lambda_handler(event, context):

    try:
        bucket = event['Records'][0]['s3']['bucket']['name']
        key = urllib.parse.unquote_plus(
            event['Records'][0]['s3']['object']['key']
        )

        print("Processing:", key)

        # avoid re-processing
        if key.startswith("processed/"):
            return

        # ================= REKOGNITION =================
        response = rekognition.detect_labels(
            Image={
                'S3Object': {
                    'Bucket': bucket,
                    'Name':   key
                }
            },
            MaxLabels=10
        )

        labels = [label['Name'] for label in response['Labels']]
        print("Labels:", labels)

        # ================= GARBAGE FILTER =================
        garbage_keywords = ["trash", "garbage", "waste", "pollution", "plastic"]
        garbage_tags = [l for l in labels if l.lower() in garbage_keywords]

        # ================= SEVERITY =================
        severity = classify_severity(labels)

        # ================= UPDATE DYNAMODB =================
        # ✅ put_item नाही — update_item वापरतो
        # फक्त labels/severity/garbageTags update होतात
        # location/address/message upload_lambda ने save केलेले तसेच राहतात
        table.update_item(
            Key={
                "ImageID": key
            },
            UpdateExpression="""
                SET labels      = :labels,
                    garbageTags = :garbageTags,
                    severity    = :severity
            """,
            ExpressionAttributeValues={
                ":labels":      labels,
                ":garbageTags": garbage_tags,
                ":severity":    severity
            }
        )

        print("DONE ✅ — location/address preserved")

        return {
            "statusCode": 200,
            "body": "Processed successfully"
        }

    except Exception as e:
        print("ERROR:", str(e))
        raise e