FROM node:15.10-alpine

USER root
WORKDIR /app

ARG ENV=build

RUN chmod 750 . -R

COPY package* ./
RUN npm install --no-package-lock
USER node

################################
FROM gcr.io/distroless/nodejs:10

WORKDIR /app
EXPOSE 3000
ARG ENV=production
ENV NODE_ENV $ENV
COPY --from=build /app/node_modules node_modules/
COPY src src
COPY package.json .
CMD ["src/index.js"]
