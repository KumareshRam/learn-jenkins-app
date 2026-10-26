// pipeline {
//     agent any

//     environment {
//         NETLIFY_SITE_ID = 'a95e4990-a361-43b0-99f3-d7606bce4909'
//         NETLIFY_AUTH_TOKEN = credentials('netlify_token')
//     }

//     stages {


//         stage('Docker') {
//             steps {
//                 sh 'docker build -t my-playwright .'
//             }
//         }

//         stage('Test EC2 Connection') {
//             steps {
//                 sshagent(credentials: ['ec2-deploy-ssh']) {
//                     sh '''
//                         ssh -o BatchMode=yes \
//                             deploy@13.200.254.146 \
//                             "whoami && hostname && ls -ld /var/www/learn-jenkins-app"
//                     '''
//                 }
//             }
//         }

//         stage('Build') {
//             agent {
//                 docker {
//                     image 'node:18-alpine'
//                     reuseNode true
//                     args '-u 1000:1000'
//                 }
//             }
//             steps {
//                 sh '''
//                     ls -la
//                     node --version
//                     npm --version
//                     npm ci
//                     npm run build
//                     ls -la
//                 '''
//             }
//         }

//          stage('AWS'){
//             agent{
//                 docker{
//                     image 'amazon/aws-cli'
//                     reuseNode true
//                     args "--entrypoint=''"
//                 }
//             }
//             steps {
//                 withCredentials([usernamePassword(credentialsId: 'jenkins-aws', passwordVariable: 'AWS_SECRET_ACCESS_KEY', usernameVariable: 'AWS_ACCESS_KEY_ID')]) {
//                     sh '''
//                         aws --version
//                         aws s3 sync build s3://learn-jenkins-201026
//                     '''
//                 }
//             }
//         }

//         stage('Tests') {
//             parallel {
//                 stage('Unit tests') {
//                     agent {
//                         docker {
//                             image 'node:18-alpine'
//                             reuseNode true
//                             args '-u 1000:1000'
//                         }
//                     }
//                     steps {
//                         sh '''
//                             npm test
//                         '''
//                     }
//                     post {
//                         always {
//                             junit 'jest-results/junit.xml'
//                         }
//                     }
//                 }

//                 stage('E2E') {
//                     agent {
//                         docker {
//                             image 'my-playwright'
//                             reuseNode true
//                             args '-u 1000:1000'
//                         }
//                     }
//                     steps {
//                         sh '''
//                             serve -s build &
//                             sleep 10
//                             node -p "require('@playwright/test/package.json').version"
//                             npx playwright --version
//                             npx playwright test --reporter=html
//                         '''
//                     }
//                     post {
//                         always {
//                             publishHTML([
//                                 allowMissing: false,
//                                 alwaysLinkToLastBuild: false,
//                                 keepAll: false,
//                                 reportDir: 'playwright-report',
//                                 reportFiles: 'index.html',
//                                 reportName: 'Playwright HTML Report',
//                                 reportTitles: '',
//                                 useWrapperFileDirectly: true
//                             ])
//                         }
//                     }
//                 }
//             }
//         }

//         stage('Deploy Staging') {
//             agent {
//                 docker {
//                     image 'node:18-alpine'
//                     reuseNode true
//                     args '-u 1000:1000'
//                 }
//             }
//             steps {
//                 sh '''
//                     npm install --no-save --package-lock=false netlify-cli
//                     node_modules/.bin/netlify --version

//                     echo "Deploying to staging. Site ID: $NETLIFY_SITE_ID"

//                     node_modules/.bin/netlify deploy \
//                         --dir=build \
//                         --no-build \
//                         --site "$NETLIFY_SITE_ID" \
//                         --auth "$NETLIFY_AUTH_TOKEN" \
//                         --json > deploy-output.json
//                 '''
//             }
//         }

//         stage('Staging E2E') {
//             agent {
//                 docker {
//                     image 'my-playwright'
//                     reuseNode true
//                     args '-u 1000:1000'
//                 }
//             }
//             steps {
//                 sh '''
//                     export CI_ENVIRONMENT_URL="$(node -p "require('./deploy-output.json').deploy_url || ''")"
//                     test -n "$CI_ENVIRONMENT_URL"
//                     echo "Testing staging URL: $CI_ENVIRONMENT_URL"

//                     node -p "require('@playwright/test/package.json').version"
//                     npx playwright --version
//                     npx playwright test --reporter=html
//                 '''
//             }
//             post {
//                 always {
//                     publishHTML([
//                         allowMissing: false,
//                         alwaysLinkToLastBuild: false,
//                         keepAll: false,
//                         reportDir: 'playwright-report',
//                         reportFiles: 'index.html',
//                         reportName: 'Staging E2E',
//                         reportTitles: '',
//                         useWrapperFileDirectly: true
//                     ])
//                 }
//             }
//         }

//         stage('Deploy Prod') {
//             agent {
//                 docker {
//                     image 'node:18-alpine'
//                     reuseNode true
//                     args '-u 1000:1000'
//                 }
//             }
//             steps {
//                 sh '''
//                     npm install --no-save --package-lock=false netlify-cli
//                     node_modules/.bin/netlify --version

//                     echo "Deploying to production. Site ID: $NETLIFY_SITE_ID"

//                     node_modules/.bin/netlify deploy \
//                         --dir=build \
//                         --prod \
//                         --no-build \
//                         --site "$NETLIFY_SITE_ID" \
//                         --auth "$NETLIFY_AUTH_TOKEN"
//                 '''
//             }
//         }

//         stage('Prod E2E') {
//             agent {
//                 docker {
//                     image 'my-playwright'
//                     reuseNode true
//                     args '-u 1000:1000'
//                 }
//             }
//             environment {
//                 CI_ENVIRONMENT_URL = 'https://transcendent-sorbet-b219d5.netlify.app/'
//             }
//             steps {
//                 sh '''
//                     node -p "require('@playwright/test/package.json').version"
//                     npx playwright --version
//                     npx playwright test --reporter=html
//                 '''
//             }
//             post {
//                 always {
//                     publishHTML([
//                         allowMissing: false,
//                         alwaysLinkToLastBuild: false,
//                         keepAll: false,
//                         reportDir: 'playwright-report',
//                         reportFiles: 'index.html',
//                         reportName: 'Playwright E2E',
//                         reportTitles: '',
//                         useWrapperFileDirectly: true
//                     ])
//                 }
//             }
//         }
//     }
// }


pipeline {
    agent any

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
                            deploy@13.200.254.146:/var/www/learn-jenkins-app/

                        echo "React application deployed to EC2"
                    '''
                }
            }
        }

        stage('Verify Deployment') {
            steps {
                sh '''
                    curl --fail --silent --show-error \
                        http://13.200.254.146/ \
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
