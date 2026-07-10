# Cost Guard Procedures

This document outlines the procedures for monitoring and managing cloud costs in the Self-Healing GitOps Platform.

## Overview

The platform includes automated cost monitoring through AWS Lambda functions that check AWS costs against predefined budgets and send alerts when thresholds are exceeded.

## Components

### 1. Cost Monitoring Lambda Function

The `cost-alerts` Lambda function is responsible for:
- Checking AWS costs using the Cost Explorer API
- Comparing actual costs against budget thresholds
- Sending notifications via SNS when costs exceed thresholds
- Running on a scheduled basis (default: hourly)

### 2. Configuration

The Lambda function is configured through Terraform variables:
- `budget_amount`: The budget amount in USD that triggers an alert (default: 100.0)
- `budget_period`: The period for the budget (MONTHLY, QUARTERLY, ANNUALLY) (default: MONTHLY)
- `schedule_expression`: How often to run the check (default: "rate(1 hour)")
- `sns_topic_arn`: The SNS topic ARN for alert notifications

### 3. Alerting

When costs exceed the budget threshold:
1. The Lambda function publishes a message to the configured SNS topic
2. The SNS topic can be subscribed to by various endpoints (email, SMS, Slack, etc.)
3. Alerts include details about the current spend, budget threshold, and time period

## Procedures

### Setting Up Budgets

1. **Determine Budget Amount**: Based on project requirements and expected usage
2. **Configure Lambda**: Update the `budget_amount` variable in the Terraform module
3. **Apply Changes**: Run `terraform apply` to update the Lambda function configuration
4. **Verify**: Check that the Lambda function reflects the new budget amount

### Responding to Cost Alerts

When a cost alert is received:

1. **Acknowledge**: Confirm receipt of the alert
2. **Investigate**: 
   - Check AWS Cost Explorer for detailed breakdown
   - Identify which services are driving costs
   - Check for unexpected resource usage or scaling events
3. **Mitigate**:
   - If expected: Adjust budget and continue monitoring
   - If unexpected: Investigate root cause and take corrective action
   - Consider implementing cost optimization measures
4. **Document**: Record the incident and actions taken

### Testing the Cost Monitoring System

1. **Manual Test**: 
   - Temporarily set a low budget threshold in the Lambda environment variables
   - Verify that alerts trigger when costs exceed the threshold
   - Reset budget to normal levels after testing

2. **Schedule Verification**:
   - Check CloudWatch Logs for Lambda function execution
   - Verify the function runs according to the schedule expression
   - Check for any errors in execution

## Maintenance

### Regular Reviews

1. **Monthly**: Review actual spending vs. budget
2. **Quarterly**: Assess if budget amounts need adjustment based on usage patterns
3. **After Major Changes**: Review budget following significant deployment or architecture changes

### Lambda Function Updates

1. **Monitor Logs**: Regularly check CloudWatch Logs for errors or unexpected behavior
2. **Update Dependencies**: Periodically update the Lambda function's Python dependencies
3. **Version Control**: Keep the Lambda function code in version control

## Integration with Other Systems

### Connection to SNS

The Lambda function publishes to an SNS topic. This topic should be subscribed to by:
- Email distribution list for team alerts
- Slack channel via AWS Chatbot or Lambda integration
- PagerDuty or similar incident management system (optional)

### Connection to Monitoring

While the Lambda function provides basic cost alerting, consider integrating with:
- CloudWatch Dashboards for visualizing cost trends
- Custom dashboards in Grafana or other visualization tools
- Automated remediation systems for automatic scaling down of non-critical resources

## Best Practices

1. **Set Realistic Budgets**: Base budgets on historical usage and growth projections
2. **Use Appropriate Granularity**: Consider separate budgets for different environments (dev, staging, prod)
3. **Act Quickly**: Respond to alerts promptly to prevent unexpected charges
4. **Document Everything**: Keep records of budget changes, alerts, and actions taken
5. **Regular Audits**: Periodically review the effectiveness of the cost monitoring system

## Troubleshooting

### No Alerts Received

1. Check Lambda function execution logs in CloudWatch
2. Verify the SNS topic ARN is correctly configured
3. Check that the Lambda function has permission to publish to SNS
4. Verify the Cost Explorer API permissions are correct

### False Positives

1. Verify the budget amount is set correctly
2. Check for any data delays in Cost Explorer (can be up to 24 hours)
3. Verify the time period being checked matches the budget period

### Lambda Function Errors

1. Check CloudWatch Logs for detailed error messages
2. Verify IAM permissions for Cost Explorer and SNS
3. Check that the Lambda function has sufficient memory and timeout settings
4. Verify the Python dependencies are correctly packaged

## Revision History

- Version 1.0: Initial version
- Last Updated: 2026-07-10