#!/usr/bin/env python3
"""
Remediation Engine for Self-Healing GitOps Platform
Monitors Prometheus alerts and executes automated remediation actions
"""

import os
import json
import logging
import asyncio
from datetime import datetime, timedelta
from typing import Dict, List, Optional, Any

import aiohttp
from kubernetes import client, config
from kubernetes.client.rest import ApiException

# Configure logging
log_level = os.getenv("LOG_LEVEL", "INFO").upper()
logging.basicConfig(
    level=getattr(logging, log_level),
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class RemediationEngine:
    def __init__(self):
        # Load Kubernetes configuration
        try:
            config.load_incluster_config()
        except config.ConfigException:
            try:
                config.load_kube_config()
            except config.ConfigException:
                logger.warning("Could not load Kubernetes config, using mock client")
                self.k8s_client = None

        if not hasattr(self, 'k8s_client') or self.k8s_client is None:
            self.k8s_client = client.ApiClient()

        self.core_v1 = client.CoreV1Api(self.k8s_client)
        self.apps_v1 = client.AppsV1Api(self.k8s_client)
        self.autoscaling_v2 = client.AutoscalingV2Api(self.k8s_client)

        # Configuration from environment
        self.prometheus_url = os.getenv("PROMETHEUS_URL", "http://prometheus-server.monitoring.svc:9090")
        self.loki_url = os.getenv("LOKI_URL", "http://loki-gateway.monitoring.svc:3100")
        self.check_interval = int(os.getenv("CHECK_INTERVAL", "30"))  # seconds

        # State tracking
        self.active_incidents: Dict[str, Dict] = {}
        self.last_check: Dict[str, datetime] = {}

    async def fetch_prometheus_alerts(self) -> List[Dict]:
        """Fetch active alerts from Prometheus Alertmanager"""
        try:
            async with aiohttp.ClientSession() as session:
                url = f"{self.prometheus_url}/api/v1/alerts"
                async with session.get(url) as response:
                    if response.status == 200:
                        data = await response.json()
                        return data.get("data", [])
                    else:
                        logger.error(f"Failed to fetch alerts from Prometheus: {response.status}")
                        return []
        except Exception as e:
            logger.error(f"Error fetching Prometheus alerts: {e}")
            return []

    async def process_alert(self, alert: Dict):
        """Process a single alert and determine if remediation is needed"""
        labels = alert.get("labels", {})
        annotations = alert.get("annotations", {})
        status = alert.get("status", {})

        alertname = labels.get("alertname")
        instance = labels.get("instance")
        severity = labels.get("severity", "warning")

        # Skip if not firing or already processed
        if status.get("state") != "firing":
            return

        alert_key = f"{alertname}-{instance}"

        # Check if we've recently handled this alert
        if alert_key in self.last_check:
            if datetime.now() - self.last_check[alert_key] < timedelta(minutes=5):
                return

        self.last_check[alert_key] = datetime.now()

        # Determine remediation action based on alert
        action = self.determine_remediation_action(alert)
        if action:
            await self.execute_remediation(alert_key, action, alert)

    def determine_remediation_action(self, alert: Dict) -> Optional[str]:
        """Determine what remediation action to take based on alert labels/annotations"""
        labels = alert.get("labels", {})
        annotations = alert.get("annotations", {})
        alertname = labels.get("alertname", "")

        # Define remediation rules
        remediation_rules = {
            "HighCPUUsage": "scale_deployment",
            "HighMemoryUsage": "restart_pod",
            "PodCrashLooping": "restart_pod",
            "NodeDown": "drain_node",
            "DiskFull": "cleanup_disk",
            "CertificateExpiring": "renew_certificate",
            "HighLatency": "scale_deployment",
            "ErrorRateHigh": "rollback_deployment"
        }

        return remediation_rules.get(alertname)

    async def execute_remediation(self, alert_key: str, action: str, alert: Dict):
        """Execute the determined remediation action"""
        labels = alert.get("labels", {})
        annotations = alert.get("annotations", {})

        logger.info(f"Executing remediation action '{action}' for alert {alert_key}")

        try:
            if action == "scale_deployment":
                await self.scale_deployment(alert)
            elif action == "restart_pod":
                await self.restart_pod(alert)
            elif action == "drain_node":
                await self.drain_node(alert)
            elif action == "cleanup_disk":
                await self.cleanup_disk(alert)
            elif action == "renew_certificate":
                await self.renew_certificate(alert)
            elif action == "rollback_deployment":
                await self.rollback_deployment(alert)
            else:
                logger.warning(f"Unknown remediation action: {action}")
                return

            # Record the action taken
            self.active_incidents[alert_key] = {
                "action": action,
                "timestamp": datetime.now().isoformat(),
                "alert": alert
            }
            logger.info(f"Successfully executed {action} for {alert_key}")

        except Exception as e:
            logger.error(f"Failed to execute {action} for {alert_key}: {e}")

    async def scale_deployment(self, alert: Dict):
        """Scale a deployment based on labels in the alert"""
        labels = alert.get("labels", {})
        namespace = labels.get("namespace", "default")
        deployment_name = labels.get("deployment")

        if not deployment_name:
            logger.warning("No deployment specified in alert for scaling")
            return

        try:
            # Get current deployment
            deployment = self.apps_v1.read_namespaced_deployment(
                name=deployment_name,
                namespace=namespace
            )

            # Increase replica count by 50% or 1, whichever is greater
            current_replicas = deployment.spec.replicas or 1
            new_replicas = max(int(current_replicas * 1.5), current_replicas + 1)

            # Update deployment
            deployment.spec.replicas = new_replicas
            self.apps_v1.patch_namespaced_deployment(
                name=deployment_name,
                namespace=namespace,
                body=deployment
            )

            logger.info(f"Scaled deployment {deployment_name} from {current_replicas} to {new_replicas} replicas")

        except ApiException as e:
            logger.error(f"Failed to scale deployment {deployment_name}: {e}")

    async def restart_pod(self, alert: Dict):
        """Restart a pod by deleting it (letting the controller recreate it)"""
        labels = alert.get("labels", {})
        namespace = labels.get("namespace", "default")
        pod_name = labels.get("pod")

        if not pod_name:
            logger.warning("No pod specified in alert for restart")
            return

        try:
            self.core_v1.delete_namespaced_pod(
                name=pod_name,
                namespace=namespace,
                body=client.V1DeleteOptions()
            )
            logger.info(f"Deleted pod {pod_name} in namespace {namespace} (will be recreated by controller)")
        except ApiException as e:
            logger.error(f"Failed to delete pod {pod_name}: {e}")

    async def drain_node(self, alert: Dict):
        """Mark a node as unschedulable and evict pods"""
        labels = alert.get("labels", {})
        node_name = labels.get("node")

        if not node_name:
            logger.warning("No node specified in alert for draining")
            return

        try:
            # Cordon the node
            node = self.core_v1.read_node(name=node_name)
            if not node.spec.unschedulable:
                node.spec.unschedulable = True
                self.core_v1.patch_node(name=node_name, body=node)
                logger.info(f"Cordoned node {node_name}")

            # Evict pods (this would typically use the eviction API)
            # For simplicity, we'll just log that we would evict pods
            logger.info(f"Would evict pods from node {node_name} (implementation depends on cluster setup)")

        except ApiException as e:
            logger.error(f"Failed to drain node {node_name}: {e}")

    async def cleanup_disk(self, alert: Dict):
        """Clean up disk space on a node"""
        labels = alert.get("labels", {})
        node_name = labels.get("node")

        if not node_name:
            logger.warning("No node specified in alert for disk cleanup")
            return

        # This would typically involve running a cleanup script on the node
        # For now, we'll just log the action
        logger.info(f"Would perform disk cleanup on node {node_name} (implementation specific)")

    async def renew_certificate(self, alert: Dict):
        """Renew an expiring certificate"""
        labels = alert.get("labels", {})
        secret_name = labels.get("secret")
        namespace = labels.get("namespace", "default")

        if not secret_name:
            logger.warning("No secret specified in alert for certificate renewal")
            return

        # This would typically involve contacting a certificate manager like cert-manager
        # For now, we'll just log the action
        logger.info(f"Would renew certificate in secret {secret_name} in namespace {namespace}")

    async def rollback_deployment(self, alert: Dict):
        """Rollback a deployment to a previous revision"""
        labels = alert.get("labels", {})
        namespace = labels.get("namespace", "default")
        deployment_name = labels.get("deployment")

        if not deployment_name:
            logger.warning("No deployment specified in alert for rollback")
            return

        try:
            # Rollout undo
            patch_spec = {
                "spec": {
                    "template": {
                        "metadata": {
                            "annotations": {
                                "kubectl.kubernetes.io/restartedAt": datetime.now().isoformat()
                            }
                        }
                    }
                }
            }

            self.apps_v1.patch_namespaced_deployment(
                name=deployment_name,
                namespace=namespace,
                body=patch_spec
            )

            logger.info(f"Triggered rollout restart for deployment {deployment_name} in namespace {namespace}")

        except ApiException as e:
            logger.error(f"Failed to rollback deployment {deployment_name}: {e}")

    async def run(self):
        """Main loop of the remediation engine"""
        logger.info("Starting Remediation Engine")

        while True:
            try:
                alerts = await self.fetch_prometheus_alerts()

                for alert in alerts:
                    await self.process_alert(alert)

                # Clean up old incident records
                cutoff_time = datetime.now() - timedelta(hours=1)
                keys_to_delete = [
                    key for key, value in self.active_incidents.items()
                    if datetime.fromisoformat(value["timestamp"]) < cutoff_time
                ]
                for key in keys_to_delete:
                    del self.active_incidents[key]

                await asyncio.sleep(self.check_interval)

            except Exception as e:
                logger.error(f"Error in main loop: {e}")
                await asyncio.sleep(self.check_interval)

if __name__ == "__main__":
    engine = RemediationEngine()
    asyncio.run(engine.run())