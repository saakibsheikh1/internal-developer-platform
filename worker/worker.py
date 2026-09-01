import os
import time
import boto3


QUEUE_URL = os.environ["QUEUE_URL"]

sqs = boto3.client("sqs")


def process_message(message):
    body = message["Body"]

    print(f"Processing message: {body}")

    # Simulate work
    time.sleep(2)

    print(f"Successfully processed message: {body}")


def main():
    print("Order processor worker started")
    print(f"Queue: {QUEUE_URL}")

    while True:
        response = sqs.receive_message(
            QueueUrl=QUEUE_URL,
            MaxNumberOfMessages=10,
            WaitTimeSeconds=20,
            VisibilityTimeout=60,
        )

        messages = response.get("Messages", [])

        if not messages:
            continue

        for message in messages:
            try:
                process_message(message)

                sqs.delete_message(
                    QueueUrl=QUEUE_URL,
                    ReceiptHandle=message["ReceiptHandle"],
                )

                print("Message deleted from queue")

            except Exception as error:
                print(f"Message processing failed: {error}")

                # Do not delete the message.
                # SQS will make it visible again after
                # the visibility timeout.


if __name__ == "__main__":
    main()