pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = 'a95e4990-a361-43b0-99f3-d7606bce4909'
        NETLIFY_AUTH_TOKEN = credentials('netlify_token')
    }

    stages {


        stage('Docker') {
            steps {
                sh 'docker build -t my-playwright .'
            }
        }

        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                    args '-u 1000:1000'
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    npm ci
                    npm run build
                    ls -la
                '''
            }
        }

         stage('AWS'){
            agent{
                docker{
                    image 'amazon/aws-cli'
                    args "--entrypoint=''"
                }
            }
            steps {
                withCredentials([usernamePassword(credentialsId: 'jenkins-aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
                    sh '''
                        aws --version
                        aws s3 sync build s3://learn-jenkins-201026
                    '''
                }
            }
        }

        stage('Tests') {
            parallel {
                stage('Unit tests') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
                            args '-u 1000:1000'
                        }
                    }
                    steps {
                        sh '''
                            npm test
                        '''
                    }
                    post {
                        always {
                            junit 'jest-results/junit.xml'
                        }
                    }
                }

                stage('E2E') {
                    agent {
                        docker {
                            image 'my-playwright'
                            reuseNode true
                            args '-u 1000:1000'
                        }
                    }
                    steps {
                        sh '''
                            serve -s build &
                            sleep 10
                            node -p "require('@playwright/test/package.json').version"
                            npx playwright --version
                            npx playwright test --reporter=html
                        '''
                    }
                    post {
                        always {
                            publishHTML([
                                allowMissing: false,
                                alwaysLinkToLastBuild: false,
                                keepAll: false,
                                reportDir: 'playwright-report',
                                reportFiles: 'index.html',
                                reportName: 'Playwright HTML Report',
                                reportTitles: '',
                                useWrapperFileDirectly: true
                            ])
                        }
                    }
                }
            }
        }

        stage('Deploy Staging') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                    args '-u 1000:1000'
                }
            }
            steps {
                sh '''
                    npm install --no-save --package-lock=false netlify-cli
                    node_modules/.bin/netlify --version

                    echo "Deploying to staging. Site ID: $NETLIFY_SITE_ID"

                    node_modules/.bin/netlify deploy \
                        --dir=build \
                        --no-build \
                        --site "$NETLIFY_SITE_ID" \
                        --auth "$NETLIFY_AUTH_TOKEN" \
                        --json > deploy-output.json
                '''
            }
        }

        stage('Staging E2E') {
            agent {
                docker {
                    image 'my-playwright'
                    reuseNode true
                    args '-u 1000:1000'
                }
            }
            steps {
                sh '''
                    export CI_ENVIRONMENT_URL="$(node -p "require('./deploy-output.json').deploy_url || ''")"
                    test -n "$CI_ENVIRONMENT_URL"
                    echo "Testing staging URL: $CI_ENVIRONMENT_URL"

                    node -p "require('@playwright/test/package.json').version"
                    npx playwright --version
                    npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: false,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Staging E2E',
                        reportTitles: '',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }

        stage('Deploy Prod') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                    args '-u 1000:1000'
                }
            }
            steps {
                sh '''
                    npm install --no-save --package-lock=false netlify-cli
                    node_modules/.bin/netlify --version

                    echo "Deploying to production. Site ID: $NETLIFY_SITE_ID"

                    node_modules/.bin/netlify deploy \
                        --dir=build \
                        --prod \
                        --no-build \
                        --site "$NETLIFY_SITE_ID" \
                        --auth "$NETLIFY_AUTH_TOKEN"
                '''
            }
        }

        stage('Prod E2E') {
            agent {
                docker {
                    image 'my-playwright'
                    reuseNode true
                    args '-u 1000:1000'
                }
            }
            environment {
                CI_ENVIRONMENT_URL = 'https://transcendent-sorbet-b219d5.netlify.app/'
            }
            steps {
                sh '''
                    node -p "require('@playwright/test/package.json').version"
                    npx playwright --version
                    npx playwright test --reporter=html
                '''
            }
            post {
                always {
                    publishHTML([
                        allowMissing: false,
                        alwaysLinkToLastBuild: false,
                        keepAll: false,
                        reportDir: 'playwright-report',
                        reportFiles: 'index.html',
                        reportName: 'Playwright E2E',
                        reportTitles: '',
                        useWrapperFileDirectly: true
                    ])
                }
            }
        }
    }
}
