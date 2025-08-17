#!/usr/bin/env python3
"""
Sample Hello World Pipeline for Kubeflow Pipelines.
"""

import argparse
import sys
import os
from kfp import dsl, compiler

# Add the parent directory to the path so we can import components
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from components.hello_pipeline import say_hello

@dsl.pipeline(
    name="hello-world-pipeline",
    description="A simple hello world pipeline for testing Kubeflow deployment"
)
def hello_pipeline(recipient: str = "World") -> str:
    """Simple hello world pipeline."""
    hello_task = say_hello(name=recipient)
    return hello_task.output

def main():
    """Main function to handle compilation."""
    parser = argparse.ArgumentParser(description="Hello World Pipeline")
    parser.add_argument(
        "--compile",
        action="store_true",
        help="Compile the pipeline to YAML"
    )
    parser.add_argument(
        "--output-dir",
        type=str,
        default="compiled_pipelines",
        help="Output directory for compiled pipeline"
    )
    
    args = parser.parse_args()
    
    if args.compile:
        # Create output directory if it doesn't exist
        os.makedirs(args.output_dir, exist_ok=True)
        
        # Compile the pipeline
        output_file = os.path.join(args.output_dir, "hello_pipeline.yaml")
        compiler.Compiler().compile(
            pipeline_func=hello_pipeline,
            package_path=output_file
        )
        print(f"Pipeline compiled to: {output_file}")
    else:
        print("Use --compile to compile the pipeline")

if __name__ == "__main__":
    main()
