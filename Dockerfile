FROM node:22-bookworm-slim

WORKDIR /app
ENV NODE_ENV=production

COPY package.json package-lock.json ./
RUN npm ci

COPY . .
ARG DATABASE_URL="postgresql://build:build@localhost:5432/airo_xpress?schema=public"
ARG DIRECT_URL="postgresql://build:build@localhost:5432/airo_xpress?schema=public"
ARG APP_URL
ARG NEXT_PUBLIC_META_PIXEL_ID
RUN npm run build

RUN chown -R node:node /app
USER node

EXPOSE 3000
CMD ["npm", "run", "start"]
