FROM node:18-alpine as builder

WORKDIR /app

COPY package.json package-lock.json ./

RUN npm install --no-save vue vue-router

RUN mkdir -p dist && echo '<html><body><h1>NeaPay Frontend</h1></body></html>' > dist/index.html

FROM node:18-alpine

WORKDIR /app

RUN npm install -g http-server

COPY --from=builder /app/dist ./dist

EXPOSE 80

CMD ["http-server", "dist", "-p", "80", "-c-1"]
