pipeline {
    agent any

    environment {
        NETLIFY_SITE_ID = 'a95e4990-a361-43b0-99f3-d7606bce4909'
        NETLIFY_AUTH_TOKEN = credentials('netlify_token')
    }

    stages {

        stage('Build') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                }
            }
            steps {
                sh '''
                    ls -la
                    node --version
                    npm --version
                    rm -rf node_modules
                    npm ci
                    npm run build
                    ls -la
                '''
            }
        }

        stage('Tests') {
            parallel {
                stage('Unit tests') {
                    agent {
                        docker {
                            image 'node:18-alpine'
                            reuseNode true
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
                            image 'mcr.microsoft.com/playwright:v1.61.1-jammy'
                            reuseNode true
                        }
                    }

                    steps {
                        sh '''
                            npm install serve
                            node_modules/.bin/serve -s build &
                            sleep 10
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
                    args '-u root:root'
                }
            }

            environment {
                PYTHON = '/usr/bin/python3'
                npm_config_python = '/usr/bin/python3'
            }

            steps {
                sh '''
                    apk add --no-cache python3 make g++

                    python3 --version
                    make --version
                    g++ --version

                    npm install --no-save --package-lock=false netlify-cli

                    node_modules/.bin/netlify --version

                    echo "Deploying to staging. Site ID: $NETLIFY_SITE_ID"

                    node_modules/.bin/netlify deploy \
                    --dir=build \
                    --no-build \
                    --site "$NETLIFY_SITE_ID" \
                    --auth "$NETLIFY_AUTH_TOKEN"
                '''
            }
        }
        stage('Deploy Prod') {
            agent {
                docker {
                    image 'node:18-alpine'
                    reuseNode true
                    args '-u root:root'
                }
            }

            environment {
                PYTHON = '/usr/bin/python3'
                npm_config_python = '/usr/bin/python3'
            }

            steps {
                sh '''
                    apk add --no-cache python3 make g++

                    python3 --version
                    make --version
                    g++ --version

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
                        image 'mcr.microsoft.com/playwright:v1.61.1-jammy'
                        reuseNode true
                    }
                }

                environment {
                    CI_ENVIRONMENT_URL = 'https://transcendent-sorbet-b219d5.netlify.app/'
                }

                steps {
                    sh '''
                        npx playwright test  --reporter=html
                    '''
                }

                post {
                    always {
                        publishHTML([allowMissing: false, alwaysLinkToLastBuild: false, keepAll: false, reportDir: 'playwright-report', reportFiles: 'index.html', reportName: 'Playwright E2E', reportTitles: '', useWrapperFileDirectly: true])
                    }
                }
            }
        }
}