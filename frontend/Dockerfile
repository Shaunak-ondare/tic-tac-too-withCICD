# Stage 1: Build the React Application
FROM node:22-alpine AS build

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

# No dynamic ARG needed since Nginx will reverse-proxy natively
RUN npm run build

# Stage 2: Serve with NGINX
FROM nginx:alpine

# Copy custom NGINX proxy configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the build output to replace the default nginx contents.
COPY --from=build /app/dist /usr/share/nginx/html

# Expose port 80
EXPOSE 80

# Start Nginx server
CMD ["nginx", "-g", "daemon off;"]
