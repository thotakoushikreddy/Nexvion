pipeline {
    agent any

    environment {
        IMAGE_NAME = 'nexvion-web'
        IMAGE_TAG = '1.0'
        CONTAINER_NAME = 'nexvion-app'
        APP_PORT = '8090'
    }

    stages {
        stage('Validate Source Code') {
            steps {
                sh '''
                    set -eu

                    for file in index.html products.html payment.html style.css script.js Dockerfile nginx.conf compose.yaml; do
                        test -f "$file"
                    done

                    echo "All required project files are present."
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                    set -eu
                    docker build -t ${IMAGE_NAME}:${IMAGE_TAG} .
                '''
            }
        }

        stage('Test Docker Image') {
            steps {
                sh '''
                    set -eu

                    TEST_CONTAINER="nexvion-ci-test"

                    docker rm -f "$TEST_CONTAINER" 2>/dev/null || true

                    cleanup() {
                        docker rm -f "$TEST_CONTAINER" >/dev/null 2>&1 || true
                    }

                    trap cleanup EXIT

                    docker run -d \
                        --name "$TEST_CONTAINER" \
                        -p 127.0.0.1:18089:8080 \
                        ${IMAGE_NAME}:${IMAGE_TAG}

                    READY=0

                    for attempt in $(seq 1 20); do
                        if curl -fsS http://127.0.0.1:18089/ >/dev/null; then
                            READY=1
                            break
                        fi
                        sleep 2
                    done

                    test "$READY" -eq 1

                    curl -fsS http://127.0.0.1:18089/products.html >/dev/null
                    curl -fsS http://127.0.0.1:18089/payment.html >/dev/null

                    echo "All application endpoint tests passed."
                '''
            }
        }

        stage('Deploy Application') {
            steps {
                sh '''
                    set -eu
                    docker compose -f compose.yaml up -d --build
                '''
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    set -eu

                    echo "Checking application endpoints..."

                    READY=0
                    for attempt in $(seq 1 20); do
                        if curl -fsS http://127.0.0.1:${APP_PORT}/ >/dev/null &&
                           curl -fsS http://127.0.0.1:${APP_PORT}/products.html >/dev/null &&
                           curl -fsS http://127.0.0.1:${APP_PORT}/payment.html >/dev/null; then
                            READY=1
                            break
                        fi
                        sleep 2
                    done

                    test "$READY" -eq 1
                    echo "All application endpoints returned successfully."

                    echo "Waiting for container health..."

                    HEALTHY=0
                    for attempt in $(seq 1 20); do
                        STATUS=$(docker inspect ${CONTAINER_NAME} --format '{{.State.Health.Status}}')

                        echo "Health check attempt $attempt: $STATUS"

                        if [ "$STATUS" = "healthy" ]; then
                            HEALTHY=1
                            break
                        fi

                        if [ "$STATUS" = "unhealthy" ]; then
                            docker logs --tail 50 ${CONTAINER_NAME}
                            exit 1
                        fi

                        sleep 3
                    done

                    if [ "$HEALTHY" -ne 1 ]; then
                        echo "Container did not become healthy within the timeout."
                        docker logs --tail 50 ${CONTAINER_NAME}
                        exit 1
                    fi

                    echo "Container health: healthy"
                    echo "Docker deployment verification successful."
                '''
            }
        }

        stage('Deploy to Kubernetes with Helm') {
            steps {
                sh '''
                    set -eu

                    export PATH="/opt/homebrew/bin:/Applications/Docker.app/Contents/Resources/bin:$PATH"

                    echo "Checking Kubernetes access..."
                    kubectl --context=minikube get namespace nexvion

                    echo "Validating Helm chart..."
                    helm lint helm/nexvion

                    echo "Deploying application with Helm..."
                    helm upgrade --install nexvion helm/nexvion \
                        --namespace nexvion \
                        --wait \
                        --timeout 120s

                    echo "Checking Kubernetes rollout..."
                    kubectl --context=minikube rollout status deployment/nexvion-helm \
                        --namespace nexvion \
                        --timeout=120s

                    echo "Checking Kubernetes resources..."
                    kubectl --context=minikube get deployments,pods,services \
                        --namespace nexvion

                    echo "Helm deployment verification successful."
                '''
            }
        }
    }

    post {
        success {
            echo 'SUCCESS: Nexvion CI/CD pipeline completed successfully.'
        }

        failure {
            echo 'FAILED: Check the stage logs for the error.'
        }

        always {
            echo 'Nexvion CI/CD pipeline execution finished.'
        }
    }
}

