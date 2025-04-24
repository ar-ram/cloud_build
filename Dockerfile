# Use the official Nginx image
FROM nginx:alpine

# Remove the default nginx index page
RUN rm -rf /usr/share/nginx/html/*

# Copy our custom index.html into the NGINX directory
COPY index.html /usr/share/nginx/html/

# Expose port 80
EXPOSE 80

# Default command to run NGINX
CMD ["nginx", "-g", "daemon off;"]
