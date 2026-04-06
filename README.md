# 🚖 CICD Main Project: Taxi Booking
### 💻 Step 1: Local Environment & Repository Setup
1.	Create a folder in your local system named taxibook.

2.	Open Git Bash from that folder.

3.	Firstly, initialize the git by using the git init command.

4.	Then clone the repository to your folder by giving the command: git clone https://github.com/DevopsandMulticloudlearning/CICD_main_Taxibooking_S3_ECR_EKS.git

5.	It will be downloaded to your folder named CICD_main_project_Taxibooking.

6.	Now rename the CICD_main_Taxibooking_S3_ECR_EKS folder name to cicd-taxiapp by giving the command: mv CICD_main_Taxibooking_S3_ECR_EKS cicd-taxiapp

7.	Go to your browser and open your GitHub. Create a new repository with the name cicd-taxiapp.

8.	Now in Git Bash, perform the following commands to push your code to the GitHub repository:

o	cd cicd-taxiapp/

o	ls

o	git remote add origin <your GitHub repository URL> (Example: git remote add origin https://github.com/sairamguthula14/cicd-taxiapp.git)

o	git remote set-url origin <your GitHub repository URL> (Example: git remote set-url origin https://github.com/sairamguthula14/cicd-taxiapp.git)

o	git branch -M main (change to the main branch)

o	git push -u origin main

9.	Now refresh your GitHub URL, and you can see the files pushed from local to remote.

10.	Then open VS Code to edit the files by giving the command: code .

11.	In your taskbar, you will see the blinking VS Code tab.
________________________________________
### ☁️ Step 2: AWS CLI & Infrastructure Provisioning

Note: In the script, change the AMI, key name, and region.

12.	Check if AWS CLI is already installed by using the aws --version command. If not installed on your system, do the AWS CLI download and configure it in the environment variable.

o	Using MSI Installer (Recommended): Download AWS CLI for Windows: https://awscli.amazonaws.com/AWSCLIV2.msi. Double-click the .msi file and follow Next → Install → Finish.

o	After the installation is completed, navigate to the file location. If the command is not found, you need to configure the AWS CLI on environment variables as follows: Control Panel → System → Advanced → Environment Variables → Add to PATH: C:\Program Files\Amazon\AWSCLIV2\

13.	Now you can create an AWS Access Key. Login to AWS Console → Select your Account → Security credentials → Create access key → CLI → Download keys.

14.	Then open terminal and run: aws configure and enter your Access Key, Secret Key, Region (e.g., ap-south-1), and Output format.

15.	Create an AWS key pair with the name of taxi by running the below command or going to: EC2 → Key Pairs → Create key pair → Name: taxi → PEM → Create.

16.	Change the directory to terraform_files, then run the below Terraform commands to create your infrastructure:

o	terraform init

o	terraform validate

o	terraform plan

o	terraform apply

17.	You can check in the console that 3 servers are created. Also, an ECR and S3 bucket are created, and Terraform provides the output. Note: Update the ECR URI and S3 bucket information on the Jenkinsfile in lines 11 and 12.
________________________________________
### 🛠️ Step 3: Ansible Configuration

18.	Now connect to the Ansible server and install Ansible by using the below shell script. Create a file and edit it by using the command vi install_ansible.sh, copy & paste the script below, and save and exit with [Esc] :wq!:

Bash

#! /bin/bash

echo " Installing Ansible on Ubuntu "

sudo apt update -y

sudo apt install -y software-properties-common

sudo add-apt-repository --yes --update ppa:ansible/ansible

sudo apt install -y ansible

ansible --version

echo " Ansible Installation Complete "

Provide the permissions using chmod +x install_ansible.sh, then run it by using this command: ./install_ansible.sh

19.	Now open your VS Code terminal in the Ansible/ directory. Change the Private IP addresses to match your master and slave private IPs. Save them all, commit, and push them to GitHub.

20.	Now go to your Ansible server, execute the below commands, and run the Ansible playbooks:

o	sudo -i

o	Clone the repo on the Ansible server: git clone https://github.com/sairamguthula14/cicd-taxiapp.git

o	cd Ansible

o	mv hosts jenkins-master-setup.yaml jenkins-slave-setup.yaml /opt

o	Create a taxi.pem file in the /opt directory using vi taxi.pem and paste the private key into it from VS Code.

o	chmod 400 /opt/taxi.pem (gives only read permissions to the file).

21.	Now run the below shell script on all 3 servers (Ansible, Jenkins master, and slave).                                                                      Run cd, then sudo -i.                                                                                                                                       Create a shell file vi enable_ssh_password_login.sh and run the script by using sh enable_ssh_password_login.sh:

Bash

#!/bin/bash

set -e

echo "Setting password for ubuntu user..."

echo "ubuntu:ubuntu" | chpasswd

echo "Password set"

echo "Backing up sshd_config..."

cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

echo "Backup created"

echo "Enabling PasswordAuthentication..."

sed -i 's/^#\?PasswordAuthentication .*/PasswordAuthentication yes/' /etc/ssh/sshd_config

sed -i 's/^#\?KbdInteractiveAuthentication .*/#KbdInteractiveAuthentication no/' /etc/ssh/sshd_config

echo "SSH config updated"

echo "Restarting SSH service..."

service ssh restart

echo "SSH restarted"

echo "Script completed successfully"

22.	Now run the following commands to install the scripts using Ansible playbook commands on the Ansible server:

o	cd /opt

o	ansible all -i hosts -m ping (type "yes" to continue)

o	ansible-playbook -i hosts jenkins-master-setup.yaml

o	ansible-playbook -i hosts jenkins-slave-setup.yaml

23.	Now check the installations by connecting to the two servers (jenkins-master and build-slave):

o	In the jenkins-master server, check if Jenkins is active by entering: systemctl status jenkins

o	In the build-slave server, check Docker and Maven by using the below commands:

	sudo -i

	docker --version

	cd /opt/apache-maven-3.8.9/bin

	./mvn --version
________________________________________
### ☸️ Step 4: Kubernetes Tools & EKS Setup

24.	Create the vi install-eks-tools.sh file and paste the below shell script to install kubectl and eksctl on the Jenkins Slave server:

Bash

#!/bin/bash

set -e

echo "Installing kubectl..."

curl -LO https://s3.us-west-2.amazonaws.com/amazon-eks/1.32.9/2025-11-13/bin/linux/amd64/kubectl

chmod +x kubectl

sudo mv kubectl /usr/local/bin/

echo "Installing eksctl..."

curl -sL https://github.com/eksctl-io/eksctl/releases/latest/download/eksctl_Linux_amd64.tar.gz | tar xz

sudo mv eksctl /usr/local/bin/

echo "kubectl version:"

kubectl version --client

echo "eksctl version:"

eksctl version

echo "EKS tools installed successfully"

Run the shell script by using the below commands:

o	chmod +x install-eks-tools.sh

o	sh install-eks-tools.sh

Install AWS configure on the Jenkins Slave server: Create a file vi aws.sh and paste:

Bash

echo " Installing Aws on Ubuntu "

curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"

sudo apt install unzip

unzip awscliv2.zip

sudo ./aws/install

aws --version

Run the script by using: sh ./aws.sh Run: aws configure → Enter: Access Key → Secret Key → Region (e.g., ap-south-1).

EKS Cluster Creation on Jenkins Slave server: Change the directory to EKS, then run the below Terraform commands to create the infrastructure:

o	terraform init

o	terraform validate

o	terraform plan

o	terraform apply After creating the Cluster, run the following commands on the slave server:

o	Update kubeconfig: aws eks update-kubeconfig --region us-east-1 --name taxi-eks-cluster

o	Check nodes: kubectl get nodes

________________________________________
### 🤖 Step 5: Jenkins Dashboard & Plugin Setup

25.	Now copy the jenkins-master public IP and go to your web browser and paste it with port :8080.

o	Copy the /var/lib/jenkins/secrets/initialAdminPassword path and paste it in your jenkins-master server by giving the command sudo cat with that path. Copy and paste the password to sign up to the Jenkins dashboard.

26.	Now in the Jenkins dashboard: Manage Jenkins → Plugins → Available Plugins → Install:

1.	docker pipeline 2. aws credentials 3. amazon ECR 4. Kubernetes cli 5. Pipeline stage view 6. pipeline: aws steps (Install without restart).
Master-Slave Configuration

27.	Go to Manage Jenkins → Credentials → Global → Kind: SSH username with private key → ID: master-slave → Description: master-slave configuration → Username: ubuntu → Enter the private key directly by copying and pasting the taxi.pem key.

28.	Go to Manage Jenkins → Nodes → Name: taxi-app → Description: master-slave configuration → Number of executors: 3 → Remote root directory: /home/ubuntu/jenkins → Labels: maven → Usage: Use this node as much as possible → Launch method: Launch agents via SSH → Host: Private IP of build slave → Credentials: [Select the master-slave credential created] → Host Key Verification Strategy: Non verifying Verification strategy → Availability: Keep this agent online as much as possible.
GitHub Token & Webhooks Setup

29.	Generate a token. Go to GitHub → Profile → Settings → Developer Settings → Personal Access tokens (classic) → Generate New Token (classic). In Note name it as GitHub Token. Check all the boxes, generate the token, copy and paste it to your notepad, and push it to GitHub.

o	GitHub token: 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

30.	Now Sign in to the Jenkins Dashboard → Manage Jenkins → Credentials → Kind: Username with Password → Username: GitHub → Password: [Paste the generated GitHub token] → ID: GitHubcred → Description: GitHub credentials → Create.

31.	Now in Jenkins Dashboard → New Item → Name: taxi-booking → Select Pipeline → Create.

32.	Configure → Description: master slave with Jenkins and maven → Select Discard old builds → In Max # of builds to keep: 4 → Pipeline Definition: Pipeline Script from SCM → Repository URL: [your GitHub project URL] → Credentials: [Select added GitHub credentials] → Branch Specifier: */main → Script Path: Jenkinsfile → Apply & Save → Click on Build Now.

33.	Now add Webhooks to trigger automatically. Go to GitHub and your repository cicd-taxiapp → Settings → Webhooks → Add Webhook → Content type: application/json → Payload URL: http://3.108.228.162:8080/github-webhook/ (replace with your Jenkins public IP) → Add Webhook.

34.	Now go back to Jenkins Dashboard → taxi-booking → Configure → Build Triggers: GitHub hook trigger for GITScm polling → Apply & Save.
________________________________________
### 🔍 Step 6: SonarCloud Code Analysis

35.	Search for Sonarcloud.io in a new browser tab.

36.	Sign in using GitHub credentials. On the top right click the '+' symbol → Create new organization → Click on create one manually → Enter Organization name: taxi-app and choose the free plan, click on create organization.

37.	Now click on Analyze project in Myprojects → Give display name: taxi-app (project key will generate automatically). Select the public radio button and click on Next. Set up the project by selecting the previous version. Choose Your Analysis Method and select Manually and click on Maven. It will give details. Copy and paste them:

o	SONAR_TOKEN: 47621294ec4920503da3346cf1e96ee15bce81ac

XML
<properties>
  <sonar.organization>taxi-app-taxi-app</sonar.organization>
</properties> 

o	Command: mvn verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.projectKey=taxi-app-taxi-app_taxi

38.	In the Jenkinsfile, after the test stage, update the project key and organization details.

39.	Add another credential in Jenkins Dashboard → Manage Jenkins → Credentials → Kind: Secret text → Copy and paste the token from step 37 → ID: SONAR_TOKEN → Description: sonar credentials.

40.	Now save the pipeline, commit, and push to GitHub. It will automatically trigger and build the pipeline.

41.	Open the Jenkins slave server and verify that the Docker image is created by using the docker images command.

42.	Run the Docker image to create a container to view the application:

o	sudo docker run -dt --name taxiapp -p 8000:8080 642391958117.dkr.ecr.us-east-1.amazonaws.com/taxi-booking-app:v1.2 (Note: Change the image name as per your generated image name.)

o	By browsing this URL, you can see the webpage of taxi-booking: http://<your build-slave publicip>:8000/taxi-booking-1.0.1/
________________________________________
### 📊 Step 7: Helm & Monitoring Stack

43.	Verify the versions of both kubectl and eksctl on the Jenkins Slave server:

o	kubectl version --client

o	eksctl version

o	aws configure (Verify setup)

o	aws eks update-kubeconfig --region us-east-1 --name taxi-eks-cluster

o	aws eks --region us-east-1 describe-cluster --name taxi-eks-cluster --query cluster.status

o	kubectl get nodes

44.	Now install Helm in your jenkins-slave server by creating a file vi install_helm.sh and running it with sh install_helm.sh:

Bash

#!/bin/bash

set -e   

echo " Downloading Helm install script..."

curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3

echo "Setting execute permission..."

chmod 700 get_helm.sh

echo "Installing Helm..."

./get_helm.sh

echo "Verifying Helm installation..."

helm version

echo "Listing installed Helm releases..."

helm list

echo " Adding stable Helm repository..."

helm repo add stable https://charts.helm.sh/stable

echo "Listing Helm repositories..."

helm repo list

echo "Searching for Jenkins chart..."

helm search repo jenkins

echo "Helm installation and setup completed successfully!"

45.	Create the taxi namespace: kubectl create ns taxi

46.	Create service monitoring tools by creating vi install_monitoring.sh, make it executable with chmod +x install_monitoring.sh, and run it with
    ./install_monitoring.sh:

Bash

#!/bin/bash

set -e   # Exit if any command fails

NAMESPACE="monitoring"

HELM_REPO_NAME="prometheus-grafana-community"

HELM_REPO_URL="https://prometheus-community.github.io/helm-charts"

CHART_NAME="kube-prometheus-stack"

echo " Creating namespace (if not exists)..."

kubectl create namespace $NAMESPACE || echo "Namespace already exists"

echo " Listing Helm repositories..."

helm repo list

echo "Adding Prometheus Helm repository..."

helm repo add $HELM_REPO_NAME $HELM_REPO_URL || echo "Repo already exists"

echo "Updating Helm repositories..."

helm repo update

echo "Pulling Helm chart..."

helm pull $HELM_REPO_NAME/$CHART_NAME


echo "Extracting chart..."

tar -xzvf ${CHART_NAME}-*.tgz

echo "Navigating to chart directories..."

cd $CHART_NAME/templates

ls

echo "Installing Prometheus + Grafana..."

helm install prometheus $HELM_REPO_NAME/$CHART_NAME --namespace $NAMESPACE

echo "Returning to home directory..."

cd ~

echo "Verifying Kubernetes resources..."

kubectl get all

kubectl get all -n $NAMESPACE

echo "Monitoring stack installed successfully!"

Check deployments: kubectl get all -n monitoring
________________________________________
### 🚀 Step 8: Continuous Deployment Pipeline

47.	Now deploy via a direct pipeline with Jenkins. Copy the deploy namespace, service, secret, and deployment instructions to create the file deploy.sh:

Bash

#!/bin/bash

kubectl apply -f k8s/deployment.yaml

kubectl apply -f k8s/service.yaml

kubectl apply -f k8s/namespace.yaml  

o	Update the deployment file in line 20 with the image from step 41.

o	Now to commit and push the files to GitHub we need to give the permission. Open VS Code terminal as Git Bash and run: chmod +x deploy.sh

o	Copy & paste the deploy stage pipeline code to the Jenkinsfile:

Groovy
stage(" Deploy ") {
   steps {
     script {
        sh 'chmod +x deploy.sh'
        sh './deploy.sh'
     }
   }
 }

o	Commit and push. It will automatically build the stage.

48.	Run the following command to check app resources: kubectl get all -n taxi

49.	Run the following command to check monitoring resources: kubectl get all -n monitoring

50.	Now edit the service from ClusterIP to LoadBalancer by using the command: kubectl edit svc prometheus-kube-prometheus-prometheus -n monitoring Run the command again: kubectl get all -n monitoring

51.	Now copy the DNS entry and search it in the browser. (Grafana defaults to port 80 and Prometheus to port 9090).

o	For Grafana: Username is admin. Password can be generated using: kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode; echo (Example output: jO5zIlPUYFifRltN3Wo5Qsj0ncGQMTMRpgljmlrj)

o	Verify the nodes and pods status on Grafana.

52.	Run kubectl get all -n taxi and use the load balancer DNS name to access the webpage. Example: http://a114b7beaec3649f380222bdeab4adf8-1112331358.us-east-1.elb.amazonaws.com:8001/taxi-booking-1.0.1/
________________________________________
### 🚮 Step 9: Infrastructure Teardown

After your project completion, you must destroy/uninstall servers & clusters to avoid AWS charges:
1.	Run on the slave server: kubectl delete ns taxi monitoring (Note: Wait for step 1 to complete before proceeding).
2.	Run on VS Code under the terraform_files folder: terraform destroy --auto-approve
3.	Run on VS Code under the EKS folder: terraform destroy --auto-approve
________________________________________
### 🖼️ OUTPUTS:
<img width="1908" height="619" alt="Screenshot 2026-03-22 171618" src="https://github.com/user-attachments/assets/df5cdb4e-9c6e-4d8f-87a0-909041a11ae2" /> <img width="1909" height="607" alt="Screenshot 2026-03-22 171637" src="https://github.com/user-attachments/assets/e3fbb6b3-7162-4821-8fa0-6ccd777516da" /> <img width="1911" height="827" alt="Screenshot 2026-03-22 171947" src="https://github.com/user-attachments/assets/f08efa37-f6cc-42c4-ba25-a6d0f6f8f6b2" /> <img <img width="1910" height="957" alt="Screenshot 2026-04-06 200029" src="https://github.com/user-attachments/assets/a4164fa6-3e5d-423f-a4bf-e266a76a69c6" />
width="1904" height="964" alt="Screenshot 2026-04-06 185931" src="https://github.com/user-attachments/assets/28b3d16d-324d-48ea-a7f8-98fe27a6491f" /> <img width="1911" height="958" alt="Screenshot 2026-04-06 184956" src="https://github.com/user-attachments/assets/8eb3bd34-8384-4cbf-acb0-091278229c66" /> <img width="1908" height="985" alt="Screenshot 2026-04-06 185016" src="https://github.com/user-attachments/assets/4f5dcf9f-5ad3-4966-8962-bce314d380d8" /> <img width="1887" height="923" alt="Screenshot 2026-04-06 185231" src="https://github.com/user-attachments/assets/fdfc2b4f-4cb7-4b1f-8fc0-3da952cb77ac" />

