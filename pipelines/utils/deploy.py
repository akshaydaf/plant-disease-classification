#!/usr/bin/env python3
"""
Kubeflow Pipelines deployment script.
This script deploys compiled pipeline YAML files to a Kubeflow Pipelines instance.
"""

import argparse
import glob
import os
import sys
import time
from typing import List, Optional

try:
    from kfp import Client
except ImportError:
    print("Error: kfp package not found. Please install it with 'pip install kfp'.")
    sys.exit(1)


def parse_args():
    """Parse command line arguments."""
    parser = argparse.ArgumentParser(description="Deploy pipelines to Kubeflow Pipelines")
    parser.add_argument(
        "--endpoint",
        type=str,
        required=True,
        help="Kubeflow Pipelines API endpoint (e.g., http://localhost:8080)",
    )
    parser.add_argument(
        "--compiled-dir",
        type=str,
        default="compiled_pipelines",
        help="Directory containing compiled pipeline YAML files",
    )
    parser.add_argument(
        "--namespace",
        type=str,
        default="kubeflow",
        help="Kubernetes namespace where Kubeflow is deployed",
    )
    parser.add_argument(
        "--experiment",
        type=str,
        default="Default",
        help="Experiment name to organize pipelines",
    )
    parser.add_argument(
        "--create-version",
        action="store_true",
        help="Create a new version of existing pipelines",
    )
    parser.add_argument(
        "--run-pipeline",
        action="store_true",
        help="Run the pipeline after deployment",
    )
    return parser.parse_args()


def get_pipeline_files(directory: str) -> List[str]:
    """Get all compiled pipeline YAML files in the specified directory."""
    if not os.path.exists(directory):
        print(f"Error: Directory '{directory}' does not exist.")
        sys.exit(1)
    
    yaml_files = glob.glob(os.path.join(directory, "*.yaml"))
    yaml_files.extend(glob.glob(os.path.join(directory, "*.yml")))
    
    if not yaml_files:
        print(f"Warning: No YAML pipeline files found in '{directory}'.")
    
    return yaml_files


def create_experiment_if_not_exists(client: Client, experiment_name: str) -> str:
    """Create an experiment if it doesn't exist and return its ID."""
    try:
        experiment = client.get_experiment(experiment_name=experiment_name)
        print(f"Using existing experiment: {experiment_name}")
        return experiment.id
    except:
        experiment = client.create_experiment(name=experiment_name)
        print(f"Created new experiment: {experiment_name}")
        return experiment.id


def deploy_pipeline(
    client: Client,
    pipeline_file: str,
    experiment_id: str,
    create_version: bool = False,
    run_pipeline: bool = False,
) -> Optional[str]:
    """
    Deploy a pipeline to Kubeflow Pipelines.
    
    Args:
        client: Kubeflow Pipelines client
        pipeline_file: Path to the compiled pipeline YAML file
        experiment_id: ID of the experiment to use
        create_version: Whether to create a new version of an existing pipeline
        run_pipeline: Whether to run the pipeline after deployment
        
    Returns:
        Pipeline ID if successful, None otherwise
    """
    pipeline_name = os.path.basename(pipeline_file).replace(".yaml", "").replace(".yml", "")
    
    try:
        # Check if pipeline already exists
        existing_pipeline = None
        try:
            existing_pipeline = client.get_pipeline_id(pipeline_name)
        except:
            pass
        
        if existing_pipeline and create_version:
            # Create a new version of the existing pipeline
            version_name = f"{pipeline_name}-{int(time.time())}"
            pipeline = client.upload_pipeline_version(
                pipeline_package_path=pipeline_file,
                pipeline_version_name=version_name,
                pipeline_id=existing_pipeline,
            )
            print(f"Created new version of pipeline: {pipeline_name} (version: {version_name})")
            pipeline_id = existing_pipeline
        else:
            # Create a new pipeline or replace the existing one
            pipeline = client.upload_pipeline(
                pipeline_package_path=pipeline_file,
                pipeline_name=pipeline_name,
            )
            print(f"Deployed pipeline: {pipeline_name} (id: {pipeline.id})")
            pipeline_id = pipeline.id
        
        # Run the pipeline if requested
        if run_pipeline:
            run = client.run_pipeline(
                experiment_id=experiment_id,
                job_name=f"{pipeline_name}-{int(time.time())}",
                pipeline_id=pipeline_id,
            )
            print(f"Started pipeline run: {run.id}")
        
        return pipeline_id
    
    except Exception as e:
        print(f"Error deploying pipeline {pipeline_name}: {str(e)}")
        return None


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
    
    # Get pipeline files
    pipeline_files = get_pipeline_files(args.compiled_dir)
    if not pipeline_files:
        print("No pipelines to deploy.")
        sys.exit(0)
    
    # Create experiment if it doesn't exist
    experiment_id = create_experiment_if_not_exists(client, args.experiment)
    
    # Deploy each pipeline
    successful = 0
    failed = 0
    
    for pipeline_file in pipeline_files:
        pipeline_id = deploy_pipeline(
            client=client,
            pipeline_file=pipeline_file,
            experiment_id=experiment_id,
            create_version=args.create_version,
            run_pipeline=args.run_pipeline,
        )
        
        if pipeline_id:
            successful += 1
        else:
            failed += 1
    
    # Print summary
    print(f"\nDeployment summary:")
    print(f"  Total pipelines: {len(pipeline_files)}")
    print(f"  Successfully deployed: {successful}")
    print(f"  Failed to deploy: {failed}")
    
    if failed > 0:
        sys.exit(1)
    else:
        sys.exit(0)


if __name__ == "__main__":
    main()
