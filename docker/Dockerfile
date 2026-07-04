FROM node:18-alpine

# Install JRE for Firebase Emulators (Firestore requires Java)
RUN apk add --no-cache openjdk17-jre-headless bash

# Install Firebase CLI globally
RUN npm install -g firebase-tools

WORKDIR /app

EXPOSE 4000 8080 9099

CMD ["firebase", "emulators:start", "--project", "finance-manager-2026", "--only", "firestore,auth"]
