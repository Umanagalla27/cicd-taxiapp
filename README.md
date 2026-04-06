CICD Taxi Booking Application Deployment Pipeline
Summary of changes
This project sets up a complete CI/CD pipeline for deploying a taxi booking web application using Jenkins, Docker, Kubernetes (EKS), and monitoring tools
Infrastructure is provisioned using Terraform for EC2 instances (Ansible server, Jenkins master, Jenkins slave), S3 bucket, ECR repository, and EKS cluster
Ansible automates the configuration of Jenkins master and slave servers
Jenkins pipeline handles build, test, code quality analysis (SonarCloud), Docker image creation, ECR push, and Kubernetes deployment
Monitoring stack includes Prometheus and Grafana deployed on EKS for observability
The application is a Java Maven web application packaged as WAR and containerized with Tomcat
Execution Steps
Step 1: Local Environment Setup
Prepare the local development environment with required tools and repository structure.

1.1: Configure local workspace and clone source repository
Set up the local project folder, initialize Git, and clone the upstream taxi booking application repository.

Create a folder named taxibook on your local system
Open Git Bash terminal in the taxibook folder
Initialize Git repository with git init
Clone the source repository: git clone https://github.com/DevopsandMulticloudlearning/CICD_main_Taxibooking_S3_ECR_EKS.git
Rename the cloned folder from CICD_main_Taxibooking_S3_ECR_EKS to cicd-taxiapp using mv CICD_main_Taxibooking_S3_ECR_EKS cicd-taxiapp
1.2: Create GitHub repository and push source code
Create a new remote GitHub repository and push the local code to establish version control.

Navigate to GitHub and create a new repository named cicd-taxiapp
Change directory to cicd-taxiapp/ folder
Add the remote origin: git remote add origin <your-github-repo-url>
Set the remote URL explicitly: git remote set-url origin <your-github-repo-url>
Switch to main branch: git branch -M main
Push the code to remote repository: git push -u origin main
1.3: Install and configure AWS CLI
Install AWS Command Line Interface and configure credentials for infrastructure provisioning.

Check if AWS CLI is installed with aws --version
If not installed on Windows, download AWS CLI MSI installer from https://awscli.amazonaws.com/AWSCLIV2.msi
Run the MSI installer and complete installation
Add AWS CLI to system PATH: Navigate to Control Panel → System → Advanced → Environment Variables and add C:\Program Files\Amazon\AWSCLIV2\ to PATH
Log in to AWS Console → Security credentials → Create access key → Select CLI option → Download keys
Configure AWS CLI by running aws configure and entering Access Key, Secret Key, Region (e.g., us-east-1), and output format
1.4: Create AWS EC2 key pair
Generate an EC2 key pair that will be used for SSH access to all EC2 instances.

Navigate to AWS Console → EC2 → Key Pairs → Create key pair
Enter key pair name as taxi
Select format as PEM
Create and download the taxi.pem file to your local system
Step 2: Infrastructure Provisioning with Terraform
Deploy the foundational AWS infrastructure including EC2 instances, S3 bucket, and ECR repository.

2.1: Update Terraform configuration with environment-specific values
Customize the Terraform configuration files with correct AMI ID, key name, and region for your AWS environment.

Open VS Code in the project root with code .
Edit terraform_files/taxi-infra.tf and verify/update the following values:
AMI ID (line 157, 172, 187): Ensure ami-0030e4319cbf4dbf2 is valid for your region, or replace with appropriate Ubuntu AMI
Key name (line 159, 174, 189): Verify it references taxi key pair
Region: Confirm all resources use us-east-1 or your preferred region
Save all changes
2.2: Initialize and apply Terraform for EC2 infrastructure
Execute Terraform commands to provision EC2 instances, security groups, IAM roles, S3 bucket, and ECR repository.

Change directory to terraform_files/
Initialize Terraform providers: terraform init
Validate configuration syntax: terraform validate
Review execution plan: terraform plan
Apply the infrastructure changes: terraform apply and confirm with yes
Note the outputs displayed: s3_bucket name and ecr_repo_url
Verify in AWS Console that 3 EC2 instances are created: ansible, jenkins-master, jenkins-slave
Verify S3 bucket my-war-bucket and ECR repository taxi-booking-app are created
2.3: Update Jenkins pipeline with AWS resource identifiers
Update the Jenkinsfile with the actual ECR repository URI and S3 bucket name from Terraform outputs.

Edit Jenkinsfile in the project root
Update line 11: Set S3_BUCKET variable to the S3 bucket name from Terraform output (e.g., my-war-bucket)
Update line 12: Set ECR_REPO variable to the ECR repository URL from Terraform output (e.g., 642391958117.dkr.ecr.us-east-1.amazonaws.com/taxi-booking-app)
Commit and push changes to GitHub
Step 3: Ansible Server Configuration
Set up the Ansible control node and prepare it to configure Jenkins infrastructure.

3.1: Install Ansible on the Ansible server
Connect to the Ansible EC2 instance and install Ansible using automation script.

SSH into the ansible server using its public IP and taxi.pem key
Create installation script: vi install_ansible.sh
Paste the Ansible installation script contents and save (:wq!)
Make script executable: chmod +x install_ansible.sh
Execute the installation script: ./install_ansible.sh
Verify installation with ansible --version
3.2: Update Ansible inventory with private IPs
Configure the Ansible hosts file with the private IP addresses of Jenkins master and slave servers.

In VS Code terminal, navigate to Ansible/ directory
Edit Ansible/hosts file
Update line 2 with the private IP address of jenkins-master EC2 instance
Update line 9 with the private IP address of jenkins-slave EC2 instance
Save the file, commit, and push to GitHub
3.3: Prepare Ansible playbooks and SSH configuration
Clone the repository on Ansible server and configure SSH access for playbook execution.

SSH into ansible server and switch to root: sudo -i
Clone your GitHub repository: git clone <your-github-repo-url>
Change directory to cicd-taxiapp/Ansible
Move Ansible files to /opt directory: mv hosts jenkins-master-setup.yaml jenkins-slave-setup.yaml /opt
Create PEM key file: vi /opt/taxi.pem
Paste the contents of your taxi.pem private key and save
Set restrictive permissions on key: chmod 400 /opt/taxi.pem
3.4: Enable SSH password authentication on all servers
Run script on all three servers (Ansible, Jenkins master, Jenkins slave) to enable password-based SSH for Ansible connectivity.

On each of the three servers (ansible, jenkins-master, jenkins-slave), execute the following steps:
SSH into the server and switch to root: sudo -i
Create script file: vi enable_ssh_password_login.sh
Paste the SSH configuration script that sets ubuntu user password to ubuntu, enables PasswordAuthentication in /etc/ssh/sshd_config, and restarts SSH service
Execute the script: sh enable_ssh_password_login.sh
Verify SSH service restarted successfully
3.5: Execute Ansible playbooks to configure Jenkins infrastructure
Run Ansible playbooks from the Ansible server to install and configure Jenkins master and slave.

On ansible server, change to /opt directory: cd /opt
Test Ansible connectivity to all hosts: ansible all -i hosts -m ping (enter yes for SSH fingerprint prompts and ubuntu as password)
Execute Jenkins master playbook: ansible-playbook -i hosts jenkins-master-setup.yaml
Execute Jenkins slave playbook: ansible-playbook -i hosts jenkins-slave-setup.yaml
Verify playbooks complete successfully without errors
3.6: Verify Jenkins and build tools installation
Connect to Jenkins master and slave servers to confirm services and tools are installed correctly.

SSH into jenkins-master server
Check Jenkins service status: systemctl status jenkins (should show active/running)
SSH into jenkins-slave server and switch to root: sudo -i
Verify Docker installation: docker --version
Verify Maven installation: cd /opt/apache-maven-3.8.9/bin && ./mvn --version
Step 4: Build Slave Additional Tooling
Install Kubernetes CLI tools, AWS CLI, and provision the EKS cluster from the Jenkins slave server.

4.1: Install kubectl and eksctl on Jenkins slave
Install Kubernetes command-line tools required for EKS cluster management and deployment.

SSH into jenkins-slave server and switch to root: sudo -i
Create installation script: vi install-eks-tools.sh
Paste the EKS tools installation script that downloads kubectl (version 1.32.9) and eksctl (latest release) and moves them to /usr/local/bin/
Make script executable: chmod +x install-eks-tools.sh
Execute the script: sh install-eks-tools.sh
Verify installations: kubectl version --client and eksctl version
4.2: Install AWS CLI on Jenkins slave
Install AWS Command Line Interface on the build slave for ECR authentication and EKS cluster access.

On jenkins-slave server, create AWS CLI installation script: vi aws.sh
Paste the AWS CLI installation script that downloads the Linux installer, extracts it, and installs to /usr/local/bin/
Execute the script: sh ./aws.sh
Verify installation: aws --version
Configure AWS credentials: aws configure and enter Access Key, Secret Key, Region (us-east-1), and output format
4.3: Provision EKS cluster using Terraform
Create the Kubernetes cluster on AWS EKS with node group for application deployment.

On jenkins-slave server, clone your GitHub repository if not already present: git clone <your-github-repo-url>
Change directory to cicd-taxiapp/EKS
Initialize Terraform: terraform init
Validate configuration: terraform validate
Review execution plan: terraform plan
Apply the EKS infrastructure: terraform apply and confirm with yes
Wait for cluster creation to complete (approximately 10-15 minutes)
Note the cluster name from output: taxi-eks-cluster
4.4: Configure kubectl access to EKS cluster
Update kubeconfig to enable kubectl commands to interact with the newly created EKS cluster.

On jenkins-slave server, update kubeconfig: aws eks update-kubeconfig --region us-east-1 --name taxi-eks-cluster
Verify cluster status: aws eks --region us-east-1 describe-cluster --name taxi-eks-cluster --query cluster.status (should return ACTIVE)
List cluster nodes: kubectl get nodes (should show 2 nodes in Ready state)
4.5: Install Helm package manager
Install Helm 3 on the Jenkins slave for managing Kubernetes applications and charts.

On jenkins-slave server, create Helm installation script: vi install_helm.sh
Paste the Helm installation script that downloads the official Helm installer script, makes it executable, runs it, and adds stable Helm repository
Make script executable: chmod +x install_helm.sh
Execute the script: sh install_helm.sh
Verify Helm installation: helm version and helm list
4.6: Create Kubernetes namespace for application
Create a dedicated namespace for the taxi booking application resources in the EKS cluster.

On jenkins-slave server, create namespace: kubectl create ns taxi
Verify namespace creation: kubectl get ns (should show taxi namespace)
Step 5: Jenkins Configuration and Pipeline Setup
Configure Jenkins with required plugins, credentials, master-slave architecture, and create the CI/CD pipeline.

5.1: Access Jenkins and complete initial setup
Access the Jenkins web interface and unlock Jenkins using the initial admin password.

Copy the public IP address of jenkins-master server
Open web browser and navigate to http://<jenkins-master-public-ip>:8080
SSH into jenkins-master server
Retrieve initial admin password: sudo cat /var/lib/jenkins/secrets/initialAdminPassword
Copy the password and paste it in the Jenkins unlock page
Complete the initial setup wizard
5.2: Install required Jenkins plugins
Install Jenkins plugins necessary for Docker, AWS, Kubernetes, and pipeline functionality.

In Jenkins dashboard, navigate to Manage Jenkins → Plugins → Available Plugins
Search for and select the following plugins:
Docker Pipeline
AWS Credentials
Amazon ECR
Kubernetes CLI
Pipeline Stage View
Pipeline: AWS Steps
Click Install and wait for installation to complete
Restart Jenkins if prompted
5.3: Configure Jenkins master-slave credentials
Create SSH credentials in Jenkins for master-slave communication using the taxi PEM key.

In Jenkins dashboard, navigate to Manage Jenkins → Credentials → System → Global credentials → Add Credentials
Select Kind: SSH username with private key
Set ID to master-slave
Set Description to master-slave configuration
Set Username to ubuntu
Select Enter directly for private key
Paste the contents of taxi.pem key
Click Create
5.4: Configure Jenkins slave node
Add the build slave as a Jenkins agent node with Maven label for distributed builds.

In Jenkins dashboard, navigate to Manage Jenkins → Nodes → New Node
Set Name to taxi-app
Set Description to master-slave configuration
Set Number of executors to 3
Set Remote root directory to /home/ubuntu/jenkins
Set Labels to maven
Set Usage to Use this node as much as possible
Set Launch method to Launch agents via SSH
Set Host to the private IP address of jenkins-slave
Select Credentials: ubuntu (master-slave)
Set Host Key Verification Strategy to Non verifying Verification Strategy
Set Availability to Keep this agent online as much as possible
Click Save
Verify the node connects successfully and shows as online
5.5: Create GitHub Personal Access Token
Generate a GitHub personal access token for Jenkins to access the repository via API.

Log in to GitHub
Navigate to Settings → Developer settings → Personal access tokens → Tokens (classic)
Click Generate new token (classic)
Set Note to GitHub Token
Select all scopes/permissions
Click Generate token
Copy the generated token immediately and save it securely
5.6: Configure GitHub credentials in Jenkins
Add GitHub personal access token as credentials in Jenkins for repository access.

In Jenkins dashboard, navigate to Manage Jenkins → Credentials → System → Global credentials → Add Credentials
Select Kind: Username with password
Set Username to GitHub
Set Password to the GitHub personal access token from previous step
Set ID to GitHubcred
Set Description to GitHub credentials
Click Create
5.7: Configure SonarCloud for code quality analysis
Set up SonarCloud organization and project, then add credentials to Jenkins.

Open browser and navigate to https://sonarcloud.io
Sign in using GitHub credentials
Click + symbol and select Create new organization
Click create one manually
Enter Organization name as taxi-app and choose Free plan
Click Create organization
Click Analyze new project and set display name as taxi-app
Project key will be auto-generated (e.g., taxi-app-taxi-app_taxi)
Select Public and click Next
On Set up Project page, select Previous version and click Create project
Choose analysis method as Manually → Maven
Copy the SONAR_TOKEN value displayed
Copy the sonar.organization and sonar.projectKey values
In Jenkins, navigate to Manage Jenkins → Credentials → System → Global credentials → Add Credentials
Select Kind: Secret text
Paste the SONAR_TOKEN as secret
Set ID to SONAR_TOKEN
Set Description to sonar credentials
Click Create
5.8: Update Jenkinsfile with SonarCloud configuration
Modify the pipeline configuration with SonarCloud project key and organization details.

In VS Code, edit Jenkinsfile
Update line 37: Set -Dsonar.projectKey= to the project key from SonarCloud (e.g., taxi-app-taxi-app_taxi)
Update line 38: Set -Dsonar.organization= to the organization from SonarCloud (e.g., taxi-app-taxi-app)
Verify line 40 references the SONAR_TOKEN credential
Commit and push changes to GitHub
5.9: Create Jenkins pipeline job
Create a new Jenkins pipeline that builds from the GitHub repository using the Jenkinsfile.

In Jenkins dashboard, click New Item
Enter name as taxi-booking
Select Pipeline as job type
Click OK
In Description, enter master slave with Jenkins and maven
Check Discard old builds and set Max # of builds to keep to 4
Under Pipeline section, set Definition to Pipeline script from SCM
Set SCM to Git
Set Repository URL to your GitHub repository URL
Set Credentials to GitHub (GitHubcred)
Set Branch Specifier to */main
Set Script Path to Jenkinsfile
Click Apply and Save
5.10: Configure GitHub webhook for automatic builds
Set up a webhook in GitHub to trigger Jenkins builds automatically on code push.

Navigate to your GitHub repository
Go to Settings → Webhooks → Add webhook
Set Payload URL to http://<jenkins-master-public-ip>:8080/github-webhook/
Set Content type to application/json
Click Add webhook
In Jenkins pipeline taxi-booking, click Configure
Under Build Triggers, check GitHub hook trigger for GITScm polling
Click Apply and Save
5.11: Execute initial pipeline build and verify
Trigger the first pipeline build manually and verify all stages complete successfully.

In Jenkins dashboard, open the taxi-booking pipeline
Click Build Now
Monitor the build progress through the stage view
Verify all stages complete: build, test, SonarQube Analysis, Upload WAR to S3, Build Docker Image, Login to ECR, Tag Image, Push to ECR, Deploy
Check SonarCloud dashboard for code quality metrics
Verify WAR file uploaded to S3 bucket
Verify Docker image pushed to ECR repository
Step 6: Application Verification and Monitoring Setup
Verify the application deployment, configure monitoring stack, and access the taxi booking application.

6.1: Verify application deployment on EKS
Check that the application pods and services are running correctly in the EKS cluster.

SSH into jenkins-slave server
Check taxi namespace resources: kubectl get all -n taxi
Verify 2 replicas of taxi-booking deployment are running
Verify taxi-booking-service LoadBalancer service is created with external DNS
Copy the LoadBalancer DNS name from the EXTERNAL-IP column
6.2: Access taxi booking application
Open the taxi booking web application in a browser to confirm successful deployment.

Open web browser
Navigate to http://<loadbalancer-dns>:8001/taxi-booking-1.0.1/
Verify the taxi booking homepage loads successfully with all assets (images, CSS, JavaScript)
Test navigation through different pages (about, cars, drivers, contact, etc.)
6.3: Install Prometheus and Grafana monitoring stack
Deploy the Prometheus and Grafana monitoring solution on EKS using Helm.

SSH into jenkins-slave server
Create monitoring installation script: vi install_monitoring.sh
Paste the monitoring installation script that creates monitoring namespace, adds Prometheus Helm repository, pulls kube-prometheus-stack chart, and installs it
Make script executable: chmod +x install_monitoring.sh
Execute the script: ./install_monitoring.sh
Verify monitoring resources: kubectl get all -n monitoring
Confirm Prometheus and Grafana pods are in Running state
6.4: Expose Prometheus service externally
Change the Prometheus service type to LoadBalancer to access the Prometheus UI externally.

On jenkins-slave server, edit Prometheus service: kubectl edit svc prometheus-kube-prometheus-prometheus -n monitoring
Locate the spec.type field and change value from ClusterIP to LoadBalancer
Save and exit the editor
Wait for AWS to provision the LoadBalancer (1-2 minutes)
Check service status: kubectl get svc -n monitoring | grep prometheus
Copy the LoadBalancer DNS for prometheus-kube-prometheus-prometheus service
6.5: Access Prometheus monitoring interface
Open Prometheus web UI to view metrics and monitoring data.

Open web browser
Navigate to http://<prometheus-loadbalancer-dns>:9090
Verify Prometheus UI loads successfully
Explore targets, alerts, and metrics in the interface
6.6: Access Grafana monitoring dashboards
Log in to Grafana and verify pre-configured Kubernetes monitoring dashboards.

Open web browser
Navigate to http://<grafana-loadbalancer-dns> (port 80, already configured in service)
Login with username admin
Retrieve Grafana admin password: kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode; echo
Enter the decoded password and log in
Navigate to Dashboards section
Verify pre-configured Kubernetes dashboards are available (Nodes, Pods, Cluster)
Check that metrics are being collected and displayed for the EKS cluster and taxi application
Step 7: [NO-CODE-CHANGE] Infrastructure Teardown
Clean up all AWS resources to avoid ongoing costs after project completion.

7.1: [NO-CODE-CHANGE] Delete Kubernetes resources
Remove all Kubernetes namespaces and resources from the EKS cluster.

SSH into jenkins-slave server
Delete taxi namespace and all resources: kubectl delete ns taxi
Delete monitoring namespace and all resources: kubectl delete ns monitoring
Wait for all resources to be fully deleted (verify with kubectl get all -n taxi and kubectl get all -n monitoring returning not found)
7.2: [NO-CODE-CHANGE] Destroy EKS cluster
Tear down the EKS cluster infrastructure using Terraform destroy.

On jenkins-slave server, change directory to cicd-taxiapp/EKS
Run Terraform destroy: terraform destroy --auto-approve
Wait for EKS cluster and node groups to be completely deleted (10-15 minutes)
Verify in AWS Console that EKS cluster is removed
7.3: [NO-CODE-CHANGE] Destroy EC2 infrastructure
Tear down all EC2 instances, S3 bucket, ECR repository, and related resources using Terraform destroy.

On your local machine or any server with the Terraform state, change directory to terraform_files/
Run Terraform destroy: terraform destroy --auto-approve
Wait for all resources to be deleted: EC2 instances, security groups, IAM roles, S3 bucket, ECR repository
Verify in AWS Console that all resources are removed
Optionally delete the taxi EC2 key pair from AWS Console if no longer needed
