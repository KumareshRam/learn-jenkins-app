pipeline {
    agent any

     triggers {
        pollSCM('H/5 * * * *')
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

        stage('Build Playwright Image') {
            steps {
                sh 'docker build -t my-playwright .'
            }
        }

        stage('React Build') {
            agent {
                docker {
                    image 'node:22-alpine'
                    reuseNode true
                    args '-u 1000:1000'
                }
            }
            steps {
                sh '''
                    node --version
                    npm --version
                    npm ci
                    npm run build

                    test -f build/index.html
                    echo "React build successful"
                '''
            }
        }

        stage('Unit Tests') {
            agent {
                docker {
                    image 'node:22-alpine'
                    reuseNode true
                    args '-u 1000:1000'
                }
            }
            steps {
                sh '''
                    CI=true npm test -- --watchAll=false --runInBand
                '''
            }
            post {
                always {
                    junit allowEmptyResults: true,
                          testResults: 'jest-results/junit.xml'
                }
            }
        }

        stage('Playwright E2E') {
            agent {
                docker {
                    image 'my-playwright'
                    reuseNode true
                    args '-u 1000:1000'
                }
            }
            steps {
                sh '''
                    set -e

                    serve -s build -l 3000 \
                        > /tmp/react-serve.log 2>&1 &
                    SERVER_PID=$!
                    trap 'kill $SERVER_PID 2>/dev/null || true' EXIT

                    for i in $(seq 1 30); do
                        if curl -fsS http://localhost:3000/ \
                            > /dev/null; then
                            break
                        fi
                        sleep 2
                    done

                    curl -fsS http://localhost:3000/ \
                        > /dev/null

                    CI=true npx playwright test --reporter=html,junit
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Playwright HTML Report'
                    ])
                }
            }
        }

        stage('Deploy to EC2') {
            steps {
                sshagent(credentials: ['ec2-deploy-ssh']) {
                    sh '''
                        set -e

                        test -f build/index.html

                        rsync -avz --delete \
                            -e "ssh -o BatchMode=yes" \
                            build/ \
                            deploy@13.233.227.159:/var/www/learn-jenkins-app/

                        echo "React application deployed to EC2"
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    curl --fail --silent --show-error \
                        http://13.233.227.159/ \
                        -o deployed.html

                    grep -qi '<html' deployed.html

                    echo "React website is responding"
                '''
            }
        }
    }

    post {
        success {
            echo 'React application successfully deployed'
        }

        failure {
            echo 'Pipeline failed. Check Jenkins console output.'
        }
    }
}
