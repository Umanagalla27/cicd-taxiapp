# CI/CD Taxi Booking Documentation

## Introduction
This documentation outlines the CI/CD processes for the Taxi Booking application. It describes the various stages involved and the tools used in the implementation.

## Table of Contents
1. [Overview](#overview)
2. [Prerequisites](#prerequisites)
3. [Setup](#setup)
4. [Deployment](#deployment)
5. [Testing](#testing)
6. [Monitoring](#monitoring)

## Overview
The Taxi Booking application is designed to provide seamless ride-hailing services. CI/CD practices help in automating the deployment pipeline, ensuring faster releases and robust quality checks.

## Prerequisites
- **Git**: Ensure Git is installed on your machine to version control the project.
- **Node.js**: Required for running the application and executing tests.
- **Docker**: For containerizing the application and managing dependencies seamlessly.

## Setup
1. Clone the repository:
   ```bash
   git clone https://github.com/Umanagalla27/cicd-taxiapp.git
   cd cicd-taxiapp
   ```
2. Install the necessary dependencies:
   ```bash
   npm install
   ```

## Deployment
1. Build the Docker container:
   ```bash
   docker build -t taxiapp .
   ```
2. Run the container:
   ```bash
   docker run -d -p 3000:3000 taxiapp
   ```
3. Access the application at `http://localhost:3000`.

## Testing
To run tests, execute the following command:
```bash
npm test
```

## Monitoring
Ensure that you monitor application performance using tools like Prometheus and Grafana.