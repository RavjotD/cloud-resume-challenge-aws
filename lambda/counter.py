import json
import boto3

dynamodb = boto3.resource('dynamodb', region_name='ca-central-1')
table = dynamodb.Table('cloud-resume-visitor-count')

def lambda_handler(event, context):
    # Get current count
    response = table.get_item(Key={'id': 'visitors'})
    count = int(response['Item']['count'])

    # Increment count
    count += 1

    # Update DynamoDB
    table.update_item(
        Key={'id': 'visitors'},
        UpdateExpression='SET #c = :val',
        ExpressionAttributeNames={'#c': 'count'},
        ExpressionAttributeValues={':val': count}
    )

    # Return count with CORS headers
    return {
        'statusCode': 200,
        'headers': {
            'Access-Control-Allow-Origin': '*',
            'Access-Control-Allow-Methods': 'GET',
            'Content-Type': 'application/json'
        },
        'body': json.dumps({'count': count})
    }