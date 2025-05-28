# Usando uma imagem oficial do Node.js
FROM node:18

# Definindo diretório de trabalho dentro do container
WORKDIR /app

# Copiando arquivos para dentro do container
COPY package.json package-lock.json ./
RUN npm install

# Copiando o restante dos arquivos do projeto
COPY . .

# Definindo porta de execução
EXPOSE 3000

# Comando para iniciar a aplicação
CMD ["npm", "start"]
