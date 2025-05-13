
# SOP: Cloud Build for Docker Deployment to Compute Engine

## 1. **Theory Section**

### Introduction to Google Cloud Build

**Google Cloud Build** is a fully managed CI/CD platform provided by Google Cloud that automates the build, test, and deployment process for your applications. With Cloud Build, you can define a set of steps in a configuration file (either YAML or JSON format) that will be executed in sequence to carry out the desired tasks.

This SOP, focus on building a Docker image, pushing it to Docker Hub, and then deploying the container to a **Google Compute Engine** instance using Cloud Build. This process involves the following steps:

1. **Building a Docker Image** – The Docker image for an application (in this case, an Nginx web server) is built from a `Dockerfile`.
2. **Pushing the Image to Docker Hub** – Once the image is built, it is pushed to a Docker registry (Docker Hub in this case).
3. **Deploying the Container on Compute Engine** – Finally, the Docker image is pulled from Docker Hub and deployed to a Compute Engine instance.


### Cloud Build Service Account Permissions

Ensure that Cloud Build has the necessary permissions to access Google Compute Engine:
- **IAM Permissions**: Grant Cloud Build access to Compute Engine via the `roles/compute.admin` role or similar.
- **Secret Manager Permissions**: If you're using Docker Hub credentials from the Secret Manager, ensure Cloud Build has access to the required secret.

### Setting up GitHub and Cloud Build Integration

To trigger a build from GitHub directly, you need to link your GitHub repository to Google Cloud Build. This allows you to automatically trigger builds in Cloud Build whenever code is pushed to the repository.

Steps to link GitHub to Cloud Build:
1. Go to [Cloud Build Triggers page](https://console.cloud.google.com/cloud-build/triggers).
2. Click **Create Trigger**.
3. Select **GitHub** as your repository source and authorize Google Cloud to access your GitHub account.
4. After authorization, select the repository you want to link.
5. Specify the trigger conditions, such as whether to trigger the build on push to a specific branch or tag.

### Cloud Build Trigger

A **trigger** is a mechanism that automatically starts a build when certain conditions are met, such as a commit to a branch in your GitHub repository.

You can create triggers to automatically start builds based on specific GitHub events like:
- **Push to Branch**: The build will start whenever code is pushed to a specific branch.
- **Pull Request**: The build will start when a pull request is created or updated.

---

## 2. **Configuration Section**

### Step 1: **Create a Docker Image Using Cloud Build**

1. **Create a Dockerfile**:
   Ensure that your Dockerfile is in the root of your project directory and is configured to build your application (e.g., an Nginx web server).

```dockerfile
# Use the official Nginx image
FROM nginx:latest

# Copy the index.html to the default Nginx location
COPY index.html /usr/share/nginx/html/index.html

# Expose port 80
EXPOSE 80
```

2. **Create `index.html`**:
   Create a simple `index.html` file to serve as the web page.

```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Welcome to Nginx!</title>
</head>
<body>
    <h1>Success! The Nginx container is up and running!</h1>
</body>
</html>
```

3. **Create `cloudbuild.yaml`**:
   The Cloud Build configuration file defines the steps to build the Docker image, push it to Docker Hub, and deploy it to the Compute Engine instance.

```yaml
steps:
  - name: 'gcr.io/cloud-builders/docker'
    args: ['build', '-t', 'nginx-temp', '.']

  - name: 'gcr.io/cloud-builders/docker'
    entrypoint: 'bash'
    args:
      - '-c'
      - 'echo "$_DOCKER_PASSWORD" | docker login -u $_DOCKER_USERNAME --password-stdin'

  - name: 'gcr.io/cloud-builders/docker'
    args: ['tag', 'nginx-temp', 'docker.io/ram0810/nginx-sample:latest']

  - name: 'gcr.io/cloud-builders/docker'
    args: ['push', 'docker.io/ram0810/nginx-sample:latest']

  - name: 'gcr.io/cloud-builders/gcloud'
    args:
      [
        'compute',
        'ssh',
        'USERNAME@INSTANCE_NAME',
        '--zone=ZONE',
        '--command',
        'docker stop web || true && docker rm web || true && docker pull docker.io/ram0810/nginx-sample:latest && docker run -d --name web -p 80:80 docker.io/ram0810/nginx-sample:latest'
      ]
```

### Step 2: **Configure Google Compute Engine**

1. **Create a Compute Engine Instance**:
   - Go to the [Compute Engine Console](https://console.cloud.google.com/compute).
   - Create a new instance with Docker installed.
   - Ensure the firewall allows incoming HTTP traffic on port 80.

2. **Enable SSH Access for Cloud Build**:
   - From the Cloud Shell or your local terminal, run the following command to SSH into the instance and set up key access for Cloud Build:

```bash
gcloud compute ssh USERNAME@INSTANCE_NAME --zone=ZONE --command="echo Hello"
```

This step ensures that Cloud Build can SSH into the instance and deploy the container.

### Step 3: **Link GitHub Repository to Cloud Build and Create Trigger**

1. **Link GitHub to Cloud Build**:
   - Go to [Google Cloud Console](https://console.cloud.google.com/cloud-build/triggers).
   - Click on **Create Trigger**.
   - Select **GitHub** as your repository source.
   - Authorize Google Cloud to access your GitHub account.
   - Select the GitHub repository you want to link.
   - Specify the trigger conditions (e.g., **push** to **main** branch).

2. **Create the Trigger**:
   - The trigger will be configured to automatically start the build process whenever you push changes to the repository.
   - Set the event type, for example, **Push to a branch**.
   - Save the trigger configuration.

### Step 4: **Run the Cloud Build**

Once the `cloudbuild.yaml` and `index.html` are in place, commit and push your changes to a Git repository (GitHub, Cloud Source Repositories, etc.).

To trigger the build manually:
1. Go to [Google Cloud Console](https://console.cloud.google.com/cloud-build).
2. Select your project and navigate to the **Cloud Build** section.
3. Trigger a new build or configure automatic triggers for each commit to your repository.
