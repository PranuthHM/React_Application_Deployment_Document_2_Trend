# Stage 1: Use a minimal Nginx image to serve the application
# We use alpine because it is a very lightweight Linux distribution
FROM nginx:alpine

# Copy the custom Nginx configuration file into the container
# This file will tell Nginx to listen on port 3000
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy the pre-built React application files from your local 'dist' folder
# into Nginx's default HTML directory in the container.
# The 'dist' folder contains your index.html and other assets.
COPY dist /usr/share/nginx/html

# Expose port 3000, so it's accessible from outside the container
EXPOSE 3000

# The default command to start Nginx in the foreground
# This is required for Docker containers
CMD ["nginx", "-g", "daemon off;"]