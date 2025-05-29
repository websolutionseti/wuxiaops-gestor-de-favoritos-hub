# Usa a versão mais leve do Node.js
FROM node:18-alpine AS builder  
WORKDIR /app  
COPY . .  

# Instala dependências de produção apenas
RUN npm ci --only=production  

# Segunda etapa: remove camadas intermediárias
FROM node:18-alpine AS runtime  
WORKDIR /app  
COPY --from=builder /app .  
CMD ["npm", "start"]
