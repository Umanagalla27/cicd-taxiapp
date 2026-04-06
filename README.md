CICD Main Project Taxi Booking
 

1. Create a folder in your local system. ( taxibook )
 
2. Open git bash from that folder.
 
3. Firstly, initialize the git by using the git init command
4. then clone the repository to your folder by giving the command
git clone https://github.com/DevopsandMulticloudlearning/CICD_main_Taxibooking_S3_ECR_EKS.git
 
5. It was downloaded to your folder named CICD_main_project_Taxibooking.
6. Now rename the CICD_main_Taxibooking_S3_ECR_EKS folder name to cicd-taxiapp by giving the command
 ( mv CICD_main_Taxibooking_S3_ECR_EKS cicd-taxiapp ).
 
7. Goto browser and open your GitHub, Create a new repository with name cicd-taxiapp.
 
 
8. Now in git bash do the following commands to push our code to GitHub repository.
   * cd cicd-taxiapp/
   * ls 
   * git remote add origin < (your GitHub repository URL) >.
     git remote add origin https://github.com/sairamguthula14/cicd-taxiapp.git
   * git remote set-url origin < (your GitHub repository URL) >. 
      git remote set-url origin https://github.com/sairamguthula14/cicd-taxiapp.git
   * git branch -M main (change to the main branch)
   * git push -u origin main 
 
9. Now refresh the Your GitHub URL , you can seen the files which you are pushed local to remote
 
10. Then open Vs  code to edit the file by giving command (code .)
 
11. In the taskbar you can see that Vs code blinking tab, 
 
 
*** Note: In script change the Ami, key name and region. ***
12. Check if AWS CLI is already installed by using the aws –version command
 
If not installed on your system, then you do the Aws CLI download and configure on the environment variable
Using MSI Installer (Recommended)
Download AWS CLI for Windows: https://awscli.amazonaws.com/AWSCLIV2.msi ,Double-click the .msi file ,Follow Next → Install → Finish
   
After the installed complited, now you navigated to the file location as below  
If command not found, you need to configure the aws cli  on environment variables as below steps
 Control Panel → System → Advanced → Environment Variables
Add to PATH: C:\Program Files\Amazon\AWSCLIV2\

13.now you can create AWS Access Key & aws configure 
Login AWS Console → Select your account→ Security credentials → Create access key → CLI → Download keys, 
 
14.then Open terminal and run: aws configure  Enter: Access Key → Secret Key → Region (e.g., ap-south-1) → Output 
 
15.Create the aws keypair with the name of taxi , by run the below command
 
EC2 → Key Pairs → Create key pair → Name → PEM → Create
 
16. change the directory to the terraform_files , then run below terraform commands to create infrastructure.
 
    * terraform init
    * terraform validate
    * terraform plan
    * terraform apply
17. You can check in console now 3 servers are created in console. And also ECR and S3 bucket created with its provides the output
 
Note:- update the ECR URI and S3 bucket information on the jenkins file in the line numbers 11 and 12.
 
18. Now connect to ansible server and install ansible by using below shell script.
   Create an file and edit by using the command ( vi install_ansible.sh ) and copy & paste the script in that file save and exit by using this command ( esc  :wq!)
#! /bin/bash
echo  " Installing Ansible on Ubuntu "
sudo apt update -y
sudo apt install -y software-properties-common
sudo add-apt-repository --yes --update ppa:ansible/ansible
sudo apt install -y ansible
ansible --version
echo  " Ansible Installation Complete "
   
provide the permissions [ chmod +x install_ansible.sh ], then run it by using this command ./install_ansible.sh
 
19. Now open Vs terminal in  Ansible/
change the Private Ip addresses of the master and slave private Ip's and save them all and commit and push it to github
 
20. Now go to Ansible server and give the below commands and run the ansible-playbooks.
    * sudo -i
Then, now cloning the repo on the ansible server by using the 
[ git clone https://github.com/sairamguthula14/cicd-taxiapp.git (your github repository)]
cd Ansible
mv hosts  jenkins-master-setup.yaml  jenkins-slave-setup.yaml /opt
 
Create an taxi.pem file on the  /opt directory by using this command [ vi taxi.pem ] and paste the private key into it from the VS code
chmod 400 /opt/taxi.pem (give only read permissions to taxi.pem file for users)

 21. Now run the below shell script all 3 servers ansible, jenkins master and slave 
cd 
sudo -i
Create an shell file [ vi enable_ssh_password_login.sh ] and run the script by using [ sh enable_ssh_password_login.sh ]
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



22. Now run the below commands to install the scripts by using ansible-playbook commands on ansible server
cd /opt     
     ansible all -i hosts -m ping (type yes and yes to continue)
    ansible-playbook -i hosts jenkins-master-setup.yaml
    ansible-playbook -i hosts jenkins-slave-setup.yaml
 
23. Now check the installations by connecting to two servers of jenkins-master and build-slave
    * In jenkins-master server check Jenkins was active status by entering command (systemctl status jenkins)
 
    * In build-slave server check docker and mvn by using below commands
    * sudo -i    
 * docker --version
cd /opt/apache-maven-3.8.9/bin 
./mvn --version
 
24. create the [ vi  install-eks-tools.sh ]file and paste the below shell script to installing the kubectl and eksctl on Jenkins Slave server
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

and run the shell script by using the below command
chmod +x install-eks-tools.sh
sh install-eks-tools.sh
 
Install Aws configure on Jenkins Slave server
vi aws.sh
echo "   Installing Aws on Ubuntu  "
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
sudo apt install unzip
unzip awscliv2.zip
sudo ./aws/install
aws --version
and run the shell script by using the below command
sh ./aws.sh
 
run: aws configure  Enter: Access Key → Secret Key → Region (e.g., ap-south-1) →
 
EKS Cluster Creation on Jenkins Slave server
change the directory to the EKS, then run below terraform commands to create infrastructure.
 
    * terraform init
    * terraform validate
    * terraform plan
    * terraform apply
 

After created the Cluster , run the below commands on the slave server
Update kubeconfig  aws eks update-kubeconfig --region us-east-1 --name taxi-eks-cluster
Check nodes -> kubectl get nodes
 
------------------------------------------------------------------------------------------------------------------------------------------------------------

25. Now copy the jenkins-master public ip and go to web browser and paste with port :8080
 
    * copy the /var/lib/jenkins/secrets/initialAdminPassword path and paste in your jenkins-master server by 
      giving command sudo cat with the path, and copy paste the password to sign up to Jenkins dashboard.
 
 
Jenkins Plugins installation
26. Now in Jenkins dashboard -----> Manage Jenkins -----> Plugins -----> Available Plugins ----->  
	1. docker pipeline 2. aws credentials 3. amazon ECR  4. Kubernetes cli 5. Pipeline stage view 
6.pipeline: aws steps-->install now 
 
 Master-slave configuration
27. Now go to manage Jenkins -----> credentials -----> global -----> kind: SSH username with private key ----->
    ID: master-slave -----> Description: master-slave configuration -----> username: ubuntu -----> enter directly
    in that copy and paste taxi.pem key.
 
  
28. Now goto manage Jenkins -----> nodes -----> Name: taxi-app -----> description: master-slave configuration
    -----> Number of executors: 3 -----> Remote root directory: /home/ubuntu/jenkins -----> Labels: maven
    -----> Usage: Use this node as much as possible -----> Launch method: Launch agents via SSH ----->
    Host: Private ip of build slave -----> Credentials: we added credentials -----> Host Key Verification Strategy:
    Non verifying Verification strategy -----> Availability: Keep this agent online as much as possible
 
29. Generate the token for this go to GitHub -----> Profile -----> Settings -----> left side scroll down at 
    last you have Developer Settings -----> Personal Access token (classic) -----> Generate New Token (classic) -----> In Note name as GitHub Token -----> Check all the boxes and Generate token and copy & paste to your notepad and commit and push to GitHub
     GitHub token : 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

30. Now Sign in to Jenkins Dashboard -----> Manage Jenkins -----> Credentials -----> Kind: Username with Password -----> username: GitHub -----> password: Paste the
    generated GitHub token -----> ID: GitHubcred -----> Description -----> GitHub credentials -----> Create
 
31. Now in Jenkins Dashboard -----> New Item -----> Name: taxi-booking -----> Select Pipeline -----> Create
 
32. Configure ------> Description: master slave with Jenkins and maven -----> Select Discard old builds -----> In Max # of builds to keep: 4 ------> Pipeline
 
    -----> Definition: Pipeline Script from SCM -----> Repository URL: your GitHub project URL -----> Credentials: Select added GitHub credentials ----->
 
    Branch Specifier: */main -----> Script Path: Jenkinsfile -----> Apply & Save ----> Click on Build Now
 

33. Now Add Webhooks to trigger Automatically for this go to GitHub and your repository cicd-taxiapp -----> Settings -----> Webhooks -----> Add Webhook
    -----> Content type: application/Json -----> Payload URL: http://3.108.228.162(your jenkins public ip):8080//github-webhook/ -----> Add Webhook
 
34. Now go to Jenkins Dashboard -----> taxi-booking -----> Configure -----> Build Triggers: GitHub hook trigger for GITScm polling -----. Apply & save
 
35. Now we need to do Code Analysis test by using Sonarcloud for this go to google take new tab and search for Sonarcloud.io
36. Sign in by using GitHub credentials and login to GitHub, Right side above you have      '+' symbol -----> 
 
Create new organization -----> Click on create one manually -----> Enter Organization name-: taxi-app and choose plan select free plan and click on create organization
   
 37. Now click on Analyze project in Myprojects -----> give display name – taxi-app and project key will generated automatcically , select public radio buton and click on Next
  
Now we get another page Set up Project where we need to select previous version and create a project 
Choose Your Analysis Method and select manually and click on Maven 
 
-----> now select Manually -----> Maven ------> It will give the details take the details Copy and paste.
 
    * SONAR_TOKEN
    * 47621294ec4920503da3346cf1e96ee15bce81ac
<properties>
  <sonar.organization>taxi-app-taxi-app</sonar.organization>
</properties> 
mvn verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.projectKey=taxi-app-taxi-app_taxi 
38. In Jenkins file  After test stage that is step no36 and 37 ,update the project key and Oraganization details
    
39. Now add another credential in Jenkins Dashboard -----> Manage Jenkins -----> Credentials -----> Kind: Secret text -----> Copy and Paste the token which was in 37th point -----> 
    ID: SONAR_TOKEN -----> Description: sonar credentials
 
40. Now save the pipeline commit and push to GitHub it will automatically trigger and build the pipeline 
 
41. Now open jenkins slave server verify the docker images is created by using the docker images command
 
42.runn the docker image to create an container to view the application on web browser
    * sudo docker run -dt --name taxiapp -p 8000:8080 642391958117.dkr.ecr.us-east-1.amazonaws.com/taxi-booking-app:v1.2
 Note:-change the image name as per your image name.
 
 
    * by giving this url can see the webpage of taxi-booking, http://13.232.154.85(your build-slave publicip):8000/taxi-booking-1.0.1/
 

43. now verify the versions of both kubectl and eksctl by using the below commands on jenkins slave server
kubectl version --client
eksctl version
     aws configure  Enter: Access Key → Secret Key → Region (e.g., us-east-1) → Output

      aws eks update-kubeconfig --region us-east-1 --name taxi-eks-cluster
     aws eks --region us-east-1 describe-cluster --name taxi-eks-cluster --query cluster.status
     kubectl get nodes
 
44. Now install helm in your Jenkins-slave server by using below commands
[ vi install_helm.sh ] run this script [ sh install_helm.sh ]
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
 
45.Create the taxi namespace
 kubectl create ns taxi

 
---------------------------------------------------------------------------------------------------------------------------------------------------------------

46. Now we are creating service monitoring tools by using below commands in the slave server
vi install_monitoring.sh     chmod +x install_monitoring.sh run this ./install_monitoring.sh
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
enter the below command
kubectl get all -n monitoring
 

47.Now deploy via direct pipeline with jenkins

copy the deploy namespace, service, secret, deployment files to creating the file [ deploy.sh ]

#!/bin/bash
kubectl apply -f k8s/deployment.yaml
kubectl apply -f k8s/service.yaml
kubectl apply -f k8s/namespace.yaml  
 

Updated the deployment file , in the line 20 , image from the step number :41 

now to commit and push the files to github we need to give the permission , open VS code terminal as Gitbash 
chmod +x deploy.sh
 

copy & paste the deploy stage pipeline code to the Jenkinsfile.
stage(" Deploy ") {
       steps {
         script {
            sh 'chmod +x deploy.sh'
            sh './deploy.sh'
         }
       }
     }

Commit and push it will automatically build the stage

54. enter the below command
kubectl get all -n taxi
 

54. enter the below command
kubectl get all -n monitoring
 

55. Now edit the type ClusterIP to LoadBalancer by using the below command
kubectl edit svc prometheus-kube-prometheus-prometheus -n monitoring
Again enter the below command
kubectl get all -n monitoring

56.Now copy the DNS entry and search it in browser no need of port number as it defaults takes 80 for Grafana and Prometheus having port number 9090

For Grafana:-
username - admin
password - we need to generate the password by using the below command
kubectl get secret -n monitoring prometheus-grafana -o jsonpath="{.data.admin-password}" | base64 --decode; echo
( jO5zIlPUYFifRltN3Wo5Qsj0ncGQMTMRpgljmlrj )
  
Verify the nodes and pods status on the grafana


53. kubectl get all -n taxi , Now by using load balancer dns name access the webpage
  http://a114b7beaec3649f380222bdeab4adf8-1112331358.us-east-1.elb.amazonaws.com:8001/taxi-booking-1.0.1/

* After your project completion, we have to destroy/uninstall servers & Cluster for this go to your project where your terraform code was executed and open git bash here type
1. kubectl delete ns taxi monitoring ( run on the slave server)
Note: after step 1 completed then proceed with 2nd step.
2. terraform destroy --auto-approve   (run on VS code under terraform_files folder) 
Note: after step 2 completed then proceed with 3rd step.
3. terraform destroy --auto-approve   (run on VS code under EKS  folder)

OUTPUTS:

   <img width="1908" height="619" alt="Screenshot 2026-03-22 171618" src="https://github.com/user-attachments/assets/df5cdb4e-9c6e-4d8f-87a0-909041a11ae2" />
   <img width="1909" height="607" alt="Screenshot 2026-03-22 171637" src="https://github.com/user-attachments/assets/e3fbb6b3-7162-4821-8fa0-6ccd777516da" />
   <img width="1911" height="827" alt="Screenshot 2026-03-22 171947" src="https://github.com/user-attachments/assets/f08efa37-f6cc-42c4-ba25-a6d0f6f8f6b2" />
   <img width="1907" height="958" alt="Screenshot 2026-04-06 182511" src="https://github.com/user-attachments/assets/c5b2327e-8494-4b30-8c33-3bf5291086d3" />
   <img width="1904" height="964" alt="Screenshot 2026-04-06 185931" src="https://github.com/user-attachments/assets/28b3d16d-324d-48ea-a7f8-98fe27a6491f" />
   <img width="1911" height="958" alt="Screenshot 2026-04-06 184956" src="https://github.com/user-attachments/assets/8eb3bd34-8384-4cbf-acb0-091278229c66" />
   <img width="1908" height="985" alt="Screenshot 2026-04-06 185016" src="https://github.com/user-attachments/assets/4f5dcf9f-5ad3-4966-8962-bce314d380d8" />
   <img width="1887" height="923" alt="Screenshot 2026-04-06 185231" src="https://github.com/user-attachments/assets/fdfc2b4f-4cb7-4b1f-8fc0-3da952cb77ac" />










