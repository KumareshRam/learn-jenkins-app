FROM mcr.microsoft.com/playwright:v1.61.1-jammy

RUN npm install -g netlify-cli node-jq serve
