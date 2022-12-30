FROM node:8-alpine
WORKDIR /usr/app
COPY package.json .
RUN npm i --quiet
COPY . .
RUN npm install -g pm2@4.2.1
CMD ["pm2-runtime", "./index.js"]