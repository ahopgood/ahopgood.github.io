pipeline {
    agent { label 'Docker && Grype' }
    environment {
        JEKYLL_VERSION = '4.4.1'
    }
    stages {
        stage('Build Docker Image') {
            steps {
                sh 'docker --version'
                sh 'git --version'
                sh '''
                    chmod +x getVersionTag.sh
                    VERSION=$(./getVersionTag.sh)
                    IMAGE_NAME="jekyll-${JEKYLL_VERSION}"

                    docker build . -t ${IMAGE_NAME}:${VERSION}

                    echo "Docker Image version: ${VERSION}"
                '''
            }
        } //End build stage
        stage('Docker Image Vulnerability Scan') {
            steps {
                sh'''
                    grype version
                    chmod +x getVersionTag.sh
                    VERSION=$(./getVersionTag.sh)
                    IMAGE_NAME="jekyll-${JEKYLL_VERSION}"
                    grype ${IMAGE_NAME}:${VERSION} -c .grype.yaml
                '''
            }
        } //End Vulnerability Scan Stage
        stage ('Push Docker Image to Prod Registry') {
            when {
                branch 'master'
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'docker', usernameVariable: 'USERNAME', passwordVariable: 'PASSWORD')]) {
                    sh '''
                        chmod +x getVersionTag.sh
                        VERSION=$(./getVersionTag.sh)
                        IMAGE_NAME="jekyll-${JEKYLL_VERSION}"
                        NAMESPACE="reclusive/"

                        echo "Docker Image version: ${VERSION}"
                        echo "Docker registry: ${DOCKER_REGISTRY}"

                        echo ${PASSWORD} | docker login --username ${USERNAME} --password-stdin  https://${DOCKER_REGISTRY}
                        docker tag ${IMAGE_NAME}:${VERSION} ${DOCKER_REGISTRY}${NAMESPACE}${IMAGE_NAME}:${VERSION}
                        docker tag ${IMAGE_NAME}:${VERSION} ${DOCKER_REGISTRY}${NAMESPACE}${IMAGE_NAME}:latest

                        docker push ${DOCKER_REGISTRY}${NAMESPACE}${IMAGE_NAME}:${VERSION}
                        docker push ${DOCKER_REGISTRY}${NAMESPACE}${IMAGE_NAME}:latest
                        docker logout https://${DOCKER_REGISTRY}
                    '''
                } //End credentials block
            }
        } //End push to registry stage
    }
}