pipeline {
    agent any

    environment {
        AWS_REGION      = 'us-east-1'
        AWS_ACCOUNT_ID  = credentials('aws-account-id')          // Jenkins credential: secret text
        ECR_BACKEND     = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/auth-project-backend"
        ECR_FRONTEND    = "${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com/auth-project-frontend"
        IMAGE_TAG       = "${env.BUILD_NUMBER}"
        TF_VAR_jwt_secret = credentials('jwt-secret')            // Jenkins credential: secret text
        TF_VAR_aws_region = "${AWS_REGION}"
        TF_VAR_key_pair_name = 'devops-practice'                 // set to your actual EC2 key pair name
    }

    options {
        timestamps()
        disableConcurrentBuilds()
    }

    stages {

        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Install & Test - Backend') {
            steps {
                dir('backend') {
                    sh 'npm install'
                    // sh 'npm test'  // enable when test suite is added
                }
            }
        }

        stage('Install & Build - Frontend') {
            steps {
                dir('frontend') {
                    sh 'npm install'
                    sh 'CI=false npm run build'
                }
            }
        }

        stage('Build Docker Images') {
            steps {
                sh "docker build -t ${ECR_BACKEND}:${IMAGE_TAG} -t ${ECR_BACKEND}:latest ./backend"
                sh "docker build -t ${ECR_FRONTEND}:${IMAGE_TAG} -t ${ECR_FRONTEND}:latest ./frontend"
            }
        }

        stage('Push to ECR') {
            steps {
                withCredentials([[
                    $class: 'AmazonWebServicesCredentialsBinding',
                    credentialsId: 'aws-jenkins-creds'
                ]]) {
                    sh """
                        aws ecr get-login-password --region ${AWS_REGION} | \
                        docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com

                        docker push ${ECR_BACKEND}:${IMAGE_TAG}
                        docker push ${ECR_BACKEND}:latest
                        docker push ${ECR_FRONTEND}:${IMAGE_TAG}
                        docker push ${ECR_FRONTEND}:latest
                    """
                }
            }
        }

        stage('Terraform Apply') {
            steps {
                dir('terraform') {
                    withCredentials([[
                        $class: 'AmazonWebServicesCredentialsBinding',
                        credentialsId: 'aws-jenkins-creds'
                    ]]) {
                        sh '''
                            terraform init -input=false
                            terraform plan -input=false -out=tfplan
                            terraform apply -input=false tfplan
                        '''
                    }
                }
            }
        }

        stage('Deploy - Refresh Containers on EC2') {
            steps {
                script {
                    def appServerIp = sh(
                        script: "cd terraform && terraform output -raw app_server_public_ip",
                        returnStdout: true
                    ).trim()

                    sshagent(credentials: ['ec2-ssh-key']) {
                        sh """
                            ssh -o StrictHostKeyChecking=no ec2-user@${appServerIp} '
                                aws ecr get-login-password --region ${AWS_REGION} | \
                                docker login --username AWS --password-stdin ${AWS_ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com &&
                                cd /opt/auth-project &&
                                docker compose pull &&
                                docker compose up -d
                            '
                        """
                    }
                }
            }
        }
    }

    post {
        success {
            echo 'Pipeline finished successfully. App deployed.'
        }
        failure {
            echo 'Pipeline failed. Check logs above.'
        }
        always {
            sh 'docker image prune -f || true'
        }
    }
}
