
import React, { useState } from 'react';
import { DndProvider } from 'react-dnd';
import { HTML5Backend } from 'react-dnd-html5-backend';
import { ScrollArea } from '@/components/ui/scroll-area';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Plus, Search, FolderPlus, Link2 } from 'lucide-react';
import { BookmarkItem } from './BookmarkItem';
import { BookmarkModal } from './BookmarkModal';
import { useBookmarks } from '@/contexts/BookmarkContext';
import { Bookmark } from '@/types/bookmark';

export const BookmarkSidebar: React.FC = () => {
  const { bookmarks } = useBookmarks();
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [editingBookmark, setEditingBookmark] = useState<Bookmark | null>(null);
  const [searchQuery, setSearchQuery] = useState('');
  const [newItemType, setNewItemType] = useState<'folder' | 'link'>('link');

  const handleNewBookmark = (type: 'folder' | 'link') => {
    setNewItemType(type);
    setEditingBookmark(null);
    setIsModalOpen(true);
  };

  const handleEditBookmark = (bookmark: Bookmark) => {
    setEditingBookmark(bookmark);
    setIsModalOpen(true);
  };

  const filterBookmarks = (items: Bookmark[], query: string): Bookmark[] => {
    if (!query) return items;
    
    return items.filter(item => {
      const matchesTitle = item.title.toLowerCase().includes(query.toLowerCase());
      const matchesDescription = item.description?.toLowerCase().includes(query.toLowerCase());
      const matchesTags = item.tags?.some(tag => tag.toLowerCase().includes(query.toLowerCase()));
      const hasMatchingChildren = item.children && filterBookmarks(item.children, query).length > 0;
      
      return matchesTitle || matchesDescription || matchesTags || hasMatchingChildren;
    }).map(item => ({
      ...item,
      children: item.children ? filterBookmarks(item.children, query) : undefined
    }));
  };

  const filteredBookmarks = filterBookmarks(bookmarks, searchQuery);

  return (
    <DndProvider backend={HTML5Backend}>
      <div className="w-80 h-screen bg-sidebar border-r border-sidebar-border flex flex-col">
        {/* Header */}
        <div className="p-4 border-b border-sidebar-border">
          <div className="flex items-center justify-between mb-4">
            <h1 className="text-xl font-bold bg-gradient-to-r from-loop-purple-400 to-loop-blue-400 bg-clip-text text-transparent">
              Favoritos
            </h1>
            <div className="flex gap-1">
              <Button
                size="sm"
                variant="ghost"
                onClick={() => handleNewBookmark('folder')}
                className="p-2 h-8 w-8"
                title="Nova pasta"
              >
                <FolderPlus className="w-4 h-4" />
              </Button>
              <Button
                size="sm"
                variant="ghost"
                onClick={() => handleNewBookmark('link')}
                className="p-2 h-8 w-8"
                title="Novo link"
              >
                <Link2 className="w-4 h-4" />
              </Button>
            </div>
          </div>

          {/* Search */}
          <div className="relative">
            <Search className="absolute left-3 top-1/2 transform -translate-y-1/2 w-4 h-4 text-muted-foreground" />
            <Input
              placeholder="Buscar favoritos..."
              value={searchQuery}
              onChange={(e) => setSearchQuery(e.target.value)}
              className="pl-10"
            />
          </div>
        </div>

        {/* Quick Actions */}
        <div className="p-4 border-b border-sidebar-border">
          <div className="grid grid-cols-2 gap-2">
            <Button
              variant="outline"
              size="sm"
              onClick={() => handleNewBookmark('folder')}
              className="flex items-center gap-2 justify-start"
            >
              <FolderPlus className="w-4 h-4" />
              Nova Pasta
            </Button>
            <Button
              variant="outline"
              size="sm"
              onClick={() => handleNewBookmark('link')}
              className="flex items-center gap-2 justify-start"
            >
              <Plus className="w-4 h-4" />
              Novo Link
            </Button>
          </div>
        </div>

        {/* Bookmark List */}
        <ScrollArea className="flex-1">
          <div className="p-2">
            {filteredBookmarks.length === 0 ? (
              <div className="text-center py-8 text-muted-foreground">
                {searchQuery ? (
                  <div>
                    <Search className="w-8 h-8 mx-auto mb-2 opacity-50" />
                    <p>Nenhum resultado encontrado</p>
                  </div>
                ) : (
                  <div>
                    <FolderPlus className="w-8 h-8 mx-auto mb-2 opacity-50" />
                    <p>Nenhum favorito ainda</p>
                    <p className="text-sm">Clique em + para adicionar</p>
                  </div>
                )}
              </div>
            ) : (
              <div className="space-y-1">
                {filteredBookmarks.map((bookmark) => (
                  <BookmarkItem
                    key={bookmark.id}
                    bookmark={bookmark}
                    level={0}
                    onEdit={handleEditBookmark}
                  />
                ))}
              </div>
            )}
          </div>
        </ScrollArea>

        {/* Modal */}
        <BookmarkModal
          isOpen={isModalOpen}
          onClose={() => {
            setIsModalOpen(false);
            setEditingBookmark(null);
          }}
          bookmark={editingBookmark}
        />
      </div>
    </DndProvider>
  );
};
