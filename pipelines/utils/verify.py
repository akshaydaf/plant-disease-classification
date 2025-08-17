#!/usr/bin/env python3
"""
Kubeflow Pipelines verification script.
This script verifies that pipelines have been successfully deployed to a Kubeflow Pipelines instance.
"""

import argparse
import sys
import time
from typing import Dict, List, Optional

try:
    from kfp import Client
except ImportError:
    print("Error: kfp package not found. Please install it with 'pip install kfp'.")
    sys.exit(1)


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Verify pipeline deployments in Kubeflow Pipelines")
    parser.add_argument(
        "--endpoint",
        type=str,
        required=True,
        help="Kubeflow Pipelines API endpoint (e.g., http://localhost:8080)",
    )
    parser.add_argument(
        "--namespace",
        type=str,
        default="kubeflow",
        help="Kubernetes namespace where Kubeflow is deployed",
    )
    parser.add_argument(
        "--pipeline-names",
        type=str,
        help="Comma-separated list of pipeline names to verify (default: verify all)",
    )
    parser.add_argument(
        "--wait-timeout",
        type=int,
        default=60,
        help="Timeout in seconds to wait for pipeline runs to complete",
    )
    return parser.parse_args()


def get_pipelines(client: Client) -> List[Dict]:
    """Get all pipelines from Kubeflow Pipelines."""
    try:
        response = client.list_pipelines()
        return response.pipelines or []
    except Exception as e:
        print(f"Error listing pipelines: {str(e)}")
        return []


def get_pipeline_runs(client: Client, pipeline_id: Optional[str] = None) -> List[Dict]:
    """Get all pipeline runs from Kubeflow Pipelines."""
    try:
        if pipeline_id:
            response = client.list_runs(pipeline_id=pipeline_id)
        else:
            response = client.list_runs()
        return response.runs or []
    except Exception as e:
        print(f"Error listing pipeline runs: {str(e)}")
        return []


def verify_pipeline_exists(client: Client, pipeline_name: str) -> bool:
    """Verify that a pipeline exists in Kubeflow Pipelines."""
    try:
        pipeline_id = client.get_pipeline_id(pipeline_name)
        return pipeline_id is not None
    except:
        return False


def verify_pipeline_run_status(client: Client, pipeline_id: str, timeout: int = 60) -> bool:
    """Verify that a pipeline run has completed successfully."""
    runs = get_pipeline_runs(client, pipeline_id)
    if not runs:
        print(f"No runs found for pipeline {pipeline_id}")
        return False
    
    # Get the most recent run
    run = runs[0]
    run_id = run.id
    
    # Check if the run is already completed
    if run.status == "Succeeded":
        return True
    elif run.status in ["Failed", "Error", "Skipped", "Terminated"]:
        print(f"Run {run_id} failed with status: {run.status}")
        return False
    
    # Wait for the run to complete
    print(f"Waiting for run {run_id} to complete...")
    start_time = time.time()
    while time.time() - start_time < timeout:
        run = client.get_run(run_id)
        if run.status == "Succeeded":
            return True
        elif run.status in ["Failed", "Error", "Skipped", "Terminated"]:
            print(f"Run {run_id} failed with status: {run.status}")
            return False
        
        time.sleep(5)
    
    print(f"Timeout waiting for run {run_id} to complete")
    return False


def main():
    """Main function."""
    args = parse_args()
    
    # Connect to Kubeflow Pipelines
    try:
        client = Client(host=args.endpoint, namespace=args.namespace)
        print(f"Connected to Kubeflow Pipelines at {args.endpoint}")
    except Exception as e:
        print(f"Error connecting to Kubeflow Pipelines: {str(e)}")
        sys.exit(1)
    
    # Get pipeline names to verify
    pipeline_names = []
    if args.pipeline_names:
        pipeline_names = [name.strip() for name in args.pipeline_names.split(",")]
    else:
        # Verify all pipelines
        pipelines = get_pipelines(client)
        pipeline_names = [p.name for p in pipelines]
    
    if not pipeline_names:
        print("No pipelines to verify.")
        sys.exit(0)
    
    # Verify each pipeline
    successful = 0
    failed = 0
    
    for pipeline_name in pipeline_names:
        print(f"Verifying pipeline: {pipeline_name}")
        
        # Verify pipeline exists
        if not verify_pipeline_exists(client, pipeline_name):
            print(f"  Pipeline {pipeline_name} does not exist")
            failed += 1
            continue
        
        # Get pipeline ID
        pipeline_id = client.get_pipeline_id(pipeline_name)
        print(f"  Pipeline ID: {pipeline_id}")
        
        # Verify pipeline runs (if any)
        runs = get_pipeline_runs(client, pipeline_id)
        if runs:
            print(f"  Found {len(runs)} runs for pipeline {pipeline_name}")
            if verify_pipeline_run_status(client, pipeline_id, args.wait_timeout):
                print(f"  Pipeline {pipeline_name} has successful runs")
                successful += 1
            else:
                print(f"  Pipeline {pipeline_name} has failed runs")
                failed += 1
        else:
            print(f"  No runs found for pipeline {pipeline_name}, but pipeline exists")
            successful += 1
    
    # Print summary
    print(f"\nVerification summary:")
    print(f"  Total pipelines: {len(pipeline_names)}")
    print(f"  Successfully verified: {successful}")
    print(f"  Failed verification: {failed}")
    
    if failed > 0:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
