FROM node:18-alpine

WORKDIR /app

# Copy source directly without package.json requirement
COPY server.js .

EXPOSE 3000

CMD ["node", "server.js"]
