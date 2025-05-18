# Base image with Node.js
FROM node:22-alpine

# Set working directory
WORKDIR /app

# Install any needed system dependencies
RUN apk add --no-cache libc6-compat

# Copy package files and install dependencies
COPY package*.json ./
RUN npm clean-install --no-audit --no-progress

# Copy source code
COPY . .

# Build the app
RUN npm run build

# Set environment and expose port
ENV NODE_ENV=production
ENV PORT=8080
EXPOSE ${PORT}

# Start the app
CMD ["npm", "start"]
