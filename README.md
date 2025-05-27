
# Sistema de Gerenciamento de Favoritos

Um aplicativo web moderno para organizar e gerenciar seus favoritos com interface intuitiva em português brasileiro.

## 🚀 Características Principais

- **Interface Hierárquica**: Organize favoritos em pastas e subpastas
- **Drag & Drop**: Reorganize itens facilmente arrastando e soltando
- **Sistema de Tags**: Categorize e encontre favoritos rapidamente
- **Busca Inteligente**: Pesquise por título, descrição ou tags
- **Design Responsivo**: Funciona perfeitamente em todos os dispositivos
- **Tema Escuro**: Interface moderna com glassmorphism

## 🛠️ Tecnologias Utilizadas

- **Frontend**: React 18, TypeScript, Tailwind CSS
- **Componentes**: shadcn/ui, Lucide React
- **Funcionalidades**: React DnD, React Query, date-fns
- **Backend**: Supabase (PostgreSQL, Auth, Edge Functions)
- **Build**: Vite

## 📂 Estrutura do Projeto

```
├── src/
│   ├── components/          # Componentes React
│   ├── contexts/           # Contextos do React
│   ├── hooks/              # Hooks customizados
│   ├── pages/              # Páginas da aplicação
│   ├── types/              # Definições TypeScript
│   └── lib/                # Utilitários
├── imagens/                # Assets e mockups
├── testes/                 # Testes automatizados
├── roadmap/                # Documentação e planejamento
└── supabase/               # Configurações do Supabase
```

## 🚀 Como Executar

### Pré-requisitos
- Node.js 18+ 
- npm ou yarn
- Conta no Supabase (opcional)

### Instalação

```bash
# Clone o repositório
git clone <URL_DO_REPOSITORIO>

# Entre na pasta do projeto
cd sistema-favoritos

# Instale as dependências
npm install

# Inicie o servidor de desenvolvimento
npm run dev
```

### Configuração do Supabase (Opcional)

1. Crie um projeto no [Supabase](https://supabase.com)
2. Configure as variáveis de ambiente
3. Execute as migrações do banco de dados

## 📋 Funcionalidades Implementadas

- ✅ Sistema de favoritos com pastas e links
- ✅ Interface drag-and-drop
- ✅ Sistema de tags
- ✅ Busca e filtros avançados
- ✅ Modal de criação/edição
- ✅ Interface completamente em português
- ✅ Design responsivo com tema escuro

## 🚧 Próximas Funcionalidades

- [ ] Sincronização com Supabase
- [ ] Sistema de autenticação
- [ ] Compartilhamento de favoritos
- [ ] Importação/exportação
- [ ] Temas personalizáveis
- [ ] Atalhos de teclado

## 📖 Documentação

- [PRD - Documento de Requisitos](./roadmap/prd.md)
- [Roadmap de Desenvolvimento](./roadmap/README.md)

## 🤝 Como Contribuir

1. Faça um fork do projeto
2. Crie uma branch para sua feature (`git checkout -b feature/AmazingFeature`)
3. Commit suas mudanças (`git commit -m 'feat: adiciona nova funcionalidade'`)
4. Push para a branch (`git push origin feature/AmazingFeature`)
5. Abra um Pull Request

## 📝 Licença

Este projeto está licenciado sob a Licença MIT - veja o arquivo [LICENSE](LICENSE) para detalhes.

## 🎯 Status do Projeto

**Fase Atual**: MVP Concluído  
**Próxima Fase**: Integração com Supabase  
**Versão**: 1.0.0

---

**Desenvolvido com ❤️ pela equipe Aluno PaaS**

Para mais informações técnicas, consulte a [documentação completa](./roadmap/prd.md).
