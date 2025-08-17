# Plant Disease Classification with Kubeflow on AWS

This project demonstrates how to deploy a plant disease classification system using Kubeflow on AWS EKS. The infrastructure is provisioned using Terraform, and the machine learning pipeline is orchestrated using Kubeflow Pipelines.

## Project Structure

- `infrastructure/`: Contains Terraform files for deploying Kubeflow on AWS EKS
- `pipelines/`: Contains Kubeflow pipeline definitions for the plant disease classification system
- `models/`: Contains machine learning models for plant disease classification
- `data/`: Contains scripts for data preparation and preprocessing
- `notebooks/`: Contains Jupyter notebooks for exploratory data analysis and model development

## Getting Started

### 1. Deploy the Infrastructure

First, deploy the Kubeflow infrastructure on AWS EKS using Terraform:

```bash
cd infrastructure
terraform init
terraform apply
```

See the [infrastructure README](infrastructure/README.md) for detailed instructions.

### 2. Access Kubeflow

After the infrastructure is deployed, you can access the Kubeflow Pipelines UI:

```bash
# Configure kubectl to connect to your EKS cluster
aws eks update-kubeconfig --region us-east-1 --name kubeflow-eks

# Get the Load Balancer URL for Kubeflow
kubectl get ingress -n kubeflow kubeflow-ingress
```

The Kubeflow Pipelines UI will be available at the AWS Load Balancer URL (HTTP only).

## Plant Disease Classification

This project uses deep learning models to classify plant diseases from images. The system can identify various diseases affecting different crops, helping farmers diagnose plant health issues early and take appropriate actions.

### Supported Crops

- Tomato
- Potato

### Model Architecture

The classification model is based on a convolutional neural network (CNN) architecture.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Acknowledgments

- [PlantVillage Dataset](https://github.com/spMohanty/PlantVillage-Dataset)
- [Kubeflow](https://www.kubeflow.org/)
- [Pytorch](https://www.pytorch.org/)
- [AWS](https://aws.amazon.com/)
