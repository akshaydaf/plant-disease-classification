#!/usr/bin/env python3
"""
Tests for the sample Kubeflow Pipeline.
"""

import os
import sys
import unittest
import tempfile

# Add the parent directory to the path so we can import the pipeline
sys.path.append(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
from definitions.sample_pipeline import hello_pipeline


class TestSamplePipeline(unittest.TestCase):
    """Tests for the sample pipeline."""

    def test_pipeline_compilation(self):
        """Test that the pipeline can be compiled."""
        import kfp
        
        with tempfile.NamedTemporaryFile(suffix=".yaml") as f:
            # Compile the pipeline
            kfp.compiler.Compiler().compile(
                pipeline_func=hello_pipeline,
                package_path=f.name,
            )
            
            # Check that the file exists and has content
            self.assertTrue(os.path.exists(f.name))
            self.assertGreater(os.path.getsize(f.name), 0)
    
    def test_pipeline_function_exists(self):
        """Test that the pipeline function exists and is callable."""
        # Check that the pipeline function exists
        self.assertTrue(callable(hello_pipeline))
        
        # Check that the pipeline has the expected attributes
        self.assertEqual(hello_pipeline.name, "hello-world-pipeline")
        self.assertEqual(hello_pipeline.description, "A simple hello world pipeline for testing Kubeflow deployment")


if __name__ == "__main__":
    unittest.main()
