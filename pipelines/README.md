# Kubeflow Pipelines

This directory contains Kubeflow pipeline definitions and utilities for the plant disease classification project.

## Structure

- `components/` - Reusable pipeline components
- `definitions/` - Pipeline definitions
- `tests/` - Unit tests for pipelines
- `utils/` - Utility scripts for deployment and verification
- `compiled_pipelines/` - Compiled pipeline YAML files (generated)

## Hello World Pipeline

The project includes a simple "Hello World" pipeline to test your Kubeflow deployment.

### Local Testing

1. **Compile the pipeline:**
   ```bash
   cd pipelines
   python definitions/sample_pipeline.py --compile
   ```

2. **Run tests:**
   ```bash
   cd pipelines
   python -m pytest tests/test_sample_pipeline.py -v
   ```

### GitHub Actions Deployment

The pipeline can be automatically deployed using the GitHub Actions workflow at `.github/workflows/kubeflow-pipelines.yml`.

**Prerequisites:**
1. EKS cluster named "kubeflow-eks" running in us-east-1
2. Kubeflow deployed on the cluster with ingress configured
3. GitHub secrets configured:
   - `AWS_ROLE_TO_ASSUME` - IAM role ARN for GitHub Actions

**To deploy:**
1. Push changes to the `main` branch or create a pull request
2. The workflow will automatically:
   - Validate pipeline definitions
   - Compile pipelines to YAML
   - Deploy to your Kubeflow instance
   - Verify the deployment

**Manual deployment:**
You can also trigger the workflow manually using the "workflow_dispatch" event in the GitHub Actions tab.

## Pipeline Components

### say_hello Component
Located in `components/hello_pipeline.py`, this is a simple component that takes a name parameter and returns a greeting message.

### hello_pipeline Pipeline
Located in `definitions/sample_pipeline.py`, this pipeline uses the `say_hello` component to create a simple "Hello World" workflow.

## Testing

Run all pipeline tests:
```bash
cd pipelines
python -m pytest tests/ -v
```

## Utility Scripts

### deploy.py
Deploys compiled pipeline YAML files to a Kubeflow Pipelines instance.

**Usage:**
```bash
python utils/deploy.py \
  --endpoint http://your-kubeflow-endpoint \
  --compiled-dir compiled_pipelines \
  --experiment "Default" \
  --run-pipeline
```

**Options:**
- `--endpoint`: Kubeflow Pipelines API endpoint (required)
- `--compiled-dir`: Directory containing compiled YAML files (default: compiled_pipelines)
- `--namespace`: Kubernetes namespace (default: kubeflow)
- `--experiment`: Experiment name to organize pipelines (default: Default)
- `--create-version`: Create new version of existing pipelines
- `--run-pipeline`: Automatically run the pipeline after deployment

### verify.py
Verifies that pipelines have been successfully deployed and optionally checks run status.

**Usage:**
```bash
python utils/verify.py \
  --endpoint http://your-kubeflow-endpoint \
  --pipeline-names "hello-world-pipeline" \
  --wait-timeout 300
```

**Options:**
- `--endpoint`: Kubeflow Pipelines API endpoint (required)
- `--namespace`: Kubernetes namespace (default: kubeflow)
- `--pipeline-names`: Comma-separated list of pipeline names to verify (default: verify all)
- `--wait-timeout`: Timeout in seconds to wait for pipeline runs to complete (default: 60)

## Dependencies

The pipelines require the following Python packages (already included in requirements.txt):
- kfp (Kubeflow Pipelines SDK)
- kubernetes
- pytest (for testing)
