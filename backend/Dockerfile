# Use Node.js LTS version
FROM node:20-slim

# Set working directory
WORKDIR /app

# Copy package files
COPY package*.json ./

# Install production dependencies
RUN npm ci --only=production

# Copy source code
COPY . .

# Expose the port (matches PORT in .env)
EXPOSE 5000

# Start the application
CMD ["node", "src/server.js"]
