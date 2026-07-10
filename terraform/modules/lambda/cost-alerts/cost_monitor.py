#!/usr/bin/env python3
"""
AWS Cost Monitoring Lambda Function
Monitors AWS costs and sends alerts via SNS when thresholds are exceeded
"""

import os
import json
import logging
import boto3
from datetime import datetime, timedelta

# Configure logging
logger = logging.getLogger()
logger.setLevel(logging.INFO)

# Initialize AWS clients
ce_client = boto3.client('ce')  # Cost Explorer
sns_client = boto3.client('sns')

# Environment variables
SNS_TOPIC_ARN = os.environ['SNS_TOPIC_ARN']
BUDGET_AMOUNT = float(os.environ['BUDGET_AMOUNT'])
BUDGET_PERIOD = os.environ['BUDGET_PERIOD']
TIME_ZONE = os.environ.get('TIME_ZONE', 'UTC')

def lambda_handler(event, context):
    """
    Main Lambda handler function
    Checks current period costs against budget and sends alert if exceeded
    """
    logger.info("Starting cost monitoring check")

    try:
        # Get cost and usage data
        end_date = datetime.utcnow().date()

        if BUDGET_PERIOD == "MONTHLY":
            start_date = end_date.replace(day=1)
        elif BUDGET_PERIOD == "QUARTERLY":
            # Start of current quarter
            quarter_month = ((end_date.month - 1) // 3) * 3 + 1
            start_date = end_date.replace(month=quarter_month, day=1)
        elif BUDGET_PERIOD == "ANNUALLY":
            start_date = end_date.replace(month=1, day=1)
        else:
            # Default to monthly
            start_date = end_date.replace(day=1)

        logger.info(f"Checking costs from {start_date} to {end_date}")

        # Query Cost Explorer
        response = ce_client.get_cost_and_usage(
            TimePeriod={
                'Start': start_date.strftime('%Y-%m-%d'),
                'End': end_date.strftime('%Y-%m-%d')
            },
            Granularity='MONTHLY',
            Metrics=['UnblendedCost'],
            GroupBy=[
                {
                    'Type': 'DIMENSION',
                    'Key': 'SERVICE'
                }
            ]
        )

        # Calculate total cost
        total_cost = 0.0
        service_costs = {}

        for result in response['ResultsByTime']:
            for group in result['Groups']:
                service = group['Keys'][0]
                amount = float(group['Metrics']['UnblendedCost']['Amount'])
                total_cost += amount
                service_costs[service] = amount

        logger.info(f"Total cost for period: ${total_cost:.2f}")
        logger.info(f"Budget threshold: ${BUDGET_AMOUNT:.2f}")

        # Check if budget is exceeded
        if total_cost > BUDGET_AMOUNT:
            logger.warning(f"Budget exceeded! Current cost: ${total_cost:.2f}, Budget: ${BUDGET_AMOUNT:.2f}")

            # Prepare alert message
            subject = f"AWS Budget Alert: ${total_cost:.2f} exceeds ${BUDGET_AMOUNT:.2f} budget"

            # Format service costs for the message
            service_details = "\n".join([
                f"  • {service}: ${cost:.2f}"
                for service, cost in sorted(service_costs.items(), key=lambda x: x[1], reverse=True)[:10]
            ])

            message = f"""
AWS Budget Alert

Period: {start_date} to {end_date}
Budget: ${BUDGET_AMOUNT:.2f} ({BUDGET_PERIOD})
Current Cost: ${total_cost:.2f}
Over Budget By: ${(total_cost - BUDGET_AMOUNT):.2f}

Top Services by Cost:
{service_details}

This is an automated alert from the Self-Healing GitOps Platform Cost Monitoring Lambda.
            """.strip()

            # Send SNS notification
            sns_response = sns_client.publish(
                TopicArn=SNS_TOPIC_ARN,
                Subject=subject,
                Message=message
            )

            logger.info(f"Sent SNS alert: {sns_response['MessageId']}")

            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Budget exceeded, alert sent',
                    'cost': total_cost,
                    'budget': BUDGET_AMOUNT,
                    'alert_sent': True
                })
            }
        else:
            logger.info(f"Cost within budget: ${total_cost:.2f} <= ${BUDGET_AMOUNT:.2f}")
            return {
                'statusCode': 200,
                'body': json.dumps({
                    'message': 'Cost within budget',
                    'cost': total_cost,
                    'budget': BUDGET_AMOUNT,
                    'alert_sent': False
                })
            }

    except Exception as e:
        logger.error(f"Error in cost monitoring: {str(e)}", exc_info=True)
        return {
            'statusCode': 500,
            'body': json.dumps({
                'error': 'Internal server error',
                'message': str(e)
            })
        }