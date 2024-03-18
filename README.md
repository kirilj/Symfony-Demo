Case study from Lingoda Symfony Demo Application
================================================

Task 1
=======

1. Dockerfile

Dockerfile sets up an environment to run a Symfony 6.4 PHP application using Apache web server:
========================

Base Image

    FROM php:8.2-apache: Uses a pre-configured PHP 8.2 image with Apache as the foundation.

System Dependencies

    Installs necessary libraries for PHP extensions (internationalization, multibyte strings, ZIP, PDO for MySQL database access).
    Optimizes by installing and cleaning up in the same layer, reducing image size.

Composer

    Copies Composer (PHP dependency manager) from the official image for efficient package management.

Symfony CLI

    Installs Symfony CLI, a command-line tool for creating and managing Symfony projects.

Apache Configuration

    Copies a custom Apache configuration file (apache.conf) for your project.

Workspace Setup

    WORKDIR /usr/src/app: Sets the working directory for subsequent commands.
    COPY . /usr/src/app: Copies your Symfony project files into the container.
    Creates cache and log directories, sets appropriate permissions to be used by the web server.

Dependency Installation

    RUN composer install: Installs project dependencies using Composer.

Entrypoint Configuration

    COPY ./entrypoint.sh /usr/local/bin/entrypoint.sh: Copies a custom entrypoint script for container startup.
    Grants the script executable permissions.
    ENTRYPOINT ["/usr/local/bin/entrypoint.sh"]: Sets the entrypoint script to execute when the container starts.

Port and Healthcheck

    EXPOSE 80: Exposes port 80 to access the web application.
    HEALTHCHECK ...: Defines a health check to monitor if the application is running at http://localhost/.

Kubernetes manifest + Task 2
=============================

Deployment (symfony-app)
========================

1. **deployment.yaml**

    Kind: Defines this as a Deployment resource for managing application pods.
    Replicas: Ensures one pod of Symfony app is always running.
    RollingUpdate Strategy: Gracefully updates pods during changes with minimal downtime (max 25% unavailable, max 25% surge).
    Container spec:
        image: Docker image containing the Symfony application.
        command: Executes entrypoint script for container startup.
        volumeMounts: Connects the container to persistent storage and config files.

Volumes

    app-code (PersistentVolumeClaim): Requests persistent storage for your application code. Data survives pod restarts.
    apache-config (ConfigMap): Injects your Apache configuration into the container.
    entrypoint-script (ConfigMap): Provides your custom startup script to the container.

Migration Job (symfony-app-migrations)

    Kind: Defines this as a one-time Job to run database migrations.
    restartPolicy: Never Ensures the Job runs to completion, even if the container fails.
    initContainers: An optional container that runs before the main migration container, useful for initialization or delay.
    containers:
        image: Your Docker image (ensures code and database migration scripts are present).
        command/args: Executes the command to perform the migrations.
        volumeMounts: Accesses the shared application code volume.
 **service.yaml**
     
1. This Kubernetes manifest defines a Service resource, ensuring network accessibility within the cluster.
2. symfony-app in the dev namespace will target Pods with the label app: symfony-app, exposing port 80 and optionally making it externally accessible.

**ingress.yaml**

1. Creates an entry point for traffic from outside your cluster. This lets people access your Symfony app using the web address symfony.app.
2. Routes traffic to the correct service. It makes sure that requests to symfony.app get sent to the 'symfony-app-service' inside the cluster

 **Small script to deploy everything: deployment.sh***

    Defines variables: Sets customizable values for image name, tag, and registry.
    Builds/pushes Docker image (optional): Builds a Docker image and pushes it to a specified registry.
    Creates ConfigMaps: Establishes ConfigMaps from external configuration and script files.
    Deploys to Kubernetes: Applies Kubernetes deployment manifests to create resources within the cluster.

**How to execute deployment.sh**
```bash
    chmod +x deployment.sh
    ./deployment.sh
```    


**Task 3**

   **autoscaler.yaml**  


    This HPA automatically adjusts the number of pods running your Symfony application based on resource usage and incoming request volume.

Key parts:

    apiVersion/kind: Identifies this as a Kubernetes HorizontalPodAutoscaler resource (version v2).
    metadata: Basic information (name: symfony-app-hpa, namespace: dev).
    spec.scaleTargetRef: Specifies the deployment (symfony-app) that this HPA will manage.
    spec.minReplicas/maxReplicas: Sets the minimum (2) and maximum (5) number of pods allowed.
    spec.metrics: The rules for scaling:
        CPU Utilization: Scales if average CPU usage across pods exceeds 50%.
        HTTP Requests: Scales if the average number of HTTP requests per pod exceeds 1000 millirequests (1 request).

How it works

Kubernetes continuously monitors these metrics. If either metric exceeds the target, the HPA will tell the deployment to add pods (up to maxReplicas). If metrics fall below targets, it will decrease the number of pods (down to minReplicas).