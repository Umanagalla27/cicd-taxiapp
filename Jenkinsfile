pipeline {
    agent {
        node {
            label 'taxi-app'
        }
    }
environment {
    PATH = "/opt/apache-maven-3.8.9/bin:/usr/local/bin:$PATH"
    SONAR_TOKEN = credentials('SONAR_TOKEN')
    AWS_REGION = 'us-east-1'
    IMAGE_TAG = "v1.${BUILD_NUMBER}"
}
   stages {
        stage("Fetch Infrastructure Details") {
            steps {
                script {
                    echo "----------- fetching dynamic infra details ----------"
                    // Find only the FIRST S3 bucket by name pattern or tags
                    env.S3_BUCKET = sh(script: "aws s3api list-buckets --query \"Buckets[?starts_with(Name, 'my-war-bucket-')].Name | [0]\" --output text", returnStdout: true).trim()
                    
                    // Find ECR repo URL (always named taxi-booking-app)
                    env.ECR_REPO_URL = sh(script: "aws ecr describe-repositories --repository-names taxi-booking-app --query 'repositories[0].repositoryUri' --output text", returnStdout: true).trim()
                    
                    echo "S3 Bucket: ${env.S3_BUCKET}"
                    echo "ECR Repo: ${env.ECR_REPO_URL}"
                    
                    if (!env.S3_BUCKET || env.S3_BUCKET == 'None') {
                        error "Could not find S3 bucket starting with 'my-war-bucket-'"
                    }
                }
            }
        }
        stage("Proactive Cleanup") {
            steps {
                echo "----------- cleaning up before build ----------"
                sh "docker system prune -f --volumes || true"
                sh "rm -rf ~/.m2/repository/com/example || true"
            }
        }
        stage("build"){
            steps {
                 echo "----------- build started ----------"
                sh 'mvn package'
                 echo "----------- build complted ----------"
            }
        }
        stage("test"){
            steps{
                echo "----------- unit test started ----------"
                sh 'mvn surefire-report:report'
                 echo "----------- unit test Complted ----------"
            }
        }
        stage('SonarQube Analysis') {
            steps {
                script {
                    // Run SonarQube analysis
                    sh 'mvn verify org.sonarsource.scanner.maven:sonar-maven-plugin:sonar -Dsonar.projectKey=taxi-app1234_taxi -Dsonar.organization=taxi-app1234 -Dsonar.host.url=https://sonarcloud.io -Dsonar.token=$SONAR_TOKEN'
                }
            }
        }
        stage('Upload WAR to S3') {
            steps {
                sh "aws s3 cp taxi-booking/target/*.war s3://${S3_BUCKET}/"
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t my-app:${IMAGE_TAG} .
                '''
            }
        }
        stage('Login to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                docker login --username AWS --password-stdin $ECR_REPO_URL
                '''
            }
        }

        stage('Tag Image') {
            steps {
                sh "docker tag my-app:${IMAGE_TAG} ${ECR_REPO_URL}:${IMAGE_TAG}"
            }
        }

        stage('Push to ECR') {
            steps {
                sh "docker push ${ECR_REPO_URL}:${IMAGE_TAG}"
            }
        }
        stage(" Deploy ") {
            steps {
            script {
                sh 'chmod +x deploy.sh'
                withEnv(["ECR_REPO=${env.ECR_REPO_URL}"]) {
                    sh './deploy.sh'
                }
                }
            }
        }
    }
    post {
        always {
            echo "Cleaning up workspace..."
            cleanWs()
            sh "docker image prune -f"
        }
    }
}
