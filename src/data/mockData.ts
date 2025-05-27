
import { Bookmark } from '@/types/bookmark';

export const mockBookmarks: Bookmark[] = [
  {
    id: '1',
    title: 'Desenvolvimento',
    type: 'folder',
    icon: '💻',
    createdAt: new Date('2024-01-15'),
    updatedAt: new Date('2024-01-15'),
    order: 0,
    children: [
      {
        id: '2',
        title: 'Frontend',
        type: 'folder',
        icon: '🎨',
        parentId: '1',
        createdAt: new Date('2024-01-16'),
        updatedAt: new Date('2024-01-16'),
        order: 0,
        children: [
          {
            id: '3',
            title: 'React Documentation',
            url: 'https://react.dev',
            type: 'link',
            icon: '⚛️',
            parentId: '2',
            description: 'Documentação oficial do React',
            tags: ['react', 'docs', 'frontend'],
            createdAt: new Date('2024-01-17'),
            updatedAt: new Date('2024-01-17'),
            order: 0,
          },
          {
            id: '4',
            title: 'Tailwind CSS',
            url: 'https://tailwindcss.com',
            type: 'link',
            icon: '🎯',
            parentId: '2',
            description: 'Framework CSS utility-first',
            tags: ['css', 'tailwind', 'styling'],
            createdAt: new Date('2024-01-18'),
            updatedAt: new Date('2024-01-18'),
            order: 1,
          }
        ]
      },
      {
        id: '5',
        title: 'Backend',
        type: 'folder',
        icon: '⚙️',
        parentId: '1',
        createdAt: new Date('2024-01-19'),
        updatedAt: new Date('2024-01-19'),
        order: 1,
        children: [
          {
            id: '6',
            title: 'Supabase',
            url: 'https://supabase.com',
            type: 'link',
            icon: '🔥',
            parentId: '5',
            description: 'Plataforma de desenvolvimento backend',
            tags: ['backend', 'database', 'auth'],
            createdAt: new Date('2024-01-20'),
            updatedAt: new Date('2024-01-20'),
            order: 0,
          }
        ]
      }
    ]
  },
  {
    id: '7',
    title: 'Design',
    type: 'folder',
    icon: '🎨',
    createdAt: new Date('2024-01-21'),
    updatedAt: new Date('2024-01-21'),
    order: 1,
    children: [
      {
        id: '8',
        title: 'Figma',
        url: 'https://figma.com',
        type: 'link',
        icon: '🎭',
        parentId: '7',
        description: 'Ferramenta de design colaborativo',
        tags: ['design', 'prototyping', 'ui'],
        createdAt: new Date('2024-01-22'),
        updatedAt: new Date('2024-01-22'),
        order: 0,
      },
      {
        id: '9',
        title: 'Dribbble',
        url: 'https://dribbble.com',
        type: 'link',
        icon: '🏀',
        parentId: '7',
        description: 'Inspiração de design',
        tags: ['design', 'inspiration'],
        createdAt: new Date('2024-01-23'),
        updatedAt: new Date('2024-01-23'),
        order: 1,
      }
    ]
  },
  {
    id: '10',
    title: 'GitHub',
    url: 'https://github.com',
    type: 'link',
    icon: '🐙',
    description: 'Plataforma de desenvolvimento colaborativo',
    tags: ['git', 'code', 'collaboration'],
    createdAt: new Date('2024-01-24'),
    updatedAt: new Date('2024-01-24'),
    order: 2,
  },
  {
    id: '11',
    title: 'Lovable',
    url: 'https://lovable.dev',
    type: 'link',
    icon: '💜',
    description: 'Editor de aplicações web com IA',
    tags: ['ai', 'development', 'web'],
    createdAt: new Date('2024-01-25'),
    updatedAt: new Date('2024-01-25'),
    order: 3,
  }
];
