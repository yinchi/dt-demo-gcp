FROM node:22-slim AS builder

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN yarn install && yarn cache clean

# Copy the rest of the application files and build the app
COPY . .
RUN yarn build

###################################################

FROM joseluisq/static-web-server:2 AS runtime
COPY --from=builder /app/dist /public/
