# Remote State Configuration

This directory contains the configuration for Terraform's remote state backend. For a home lab environment, we're using MinIO as a self-hosted S3-compatible storage solution.

## Setup Instructions

1. **Install MinIO**:

   ```bash
   # Using Docker
   docker run -d \
     -p 9000:9000 \
     -p 9001:9001 \
     --name minio \
     -v ~/minio/data:/data \
     -e "MINIO_ROOT_USER=minioadmin" \
     -e "MINIO_ROOT_PASSWORD=minioadmin" \
     minio/minio server /data --console-address ":9001"
   ```

2. **Create a bucket for Terraform state**:

   - Open MinIO console at http://localhost:9001
   - Login with credentials (default: minioadmin/minioadmin)
   - Create a new bucket named `terraform-state`
   - Configure bucket policy as needed

3. **Configure Terraform to use the remote state**:
   - Copy the `backend.tf.example` file to your Terraform root directory
   - Update the endpoint, access key, and secret key as needed

## Security Considerations

For a home lab environment, this setup provides:

- Protection against state file loss
- Basic state locking to prevent concurrent modifications
- State file versioning through MinIO's versioning feature

For improved security, consider:

- Using a dedicated MinIO instance for Terraform state
- Enabling encryption for the MinIO volumes
- Enabling TLS for MinIO connections
- Setting up backup for the MinIO data
