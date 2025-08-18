FROM node:22-slim AS builder

WORKDIR /app

# Copy package files and install dependencies
COPY package*.json ./
RUN yarn install && yarn cache clean

# Copy the rest of the application files and build the app
COPY . .
RUN yarn build

###################################################

FROM nginx:stable-alpine AS runtime

# Copy built files to Nginx's default directory
COPY --from=builder /app/dist /usr/share/nginx/html

# Expose port 80 and set the default command
EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
