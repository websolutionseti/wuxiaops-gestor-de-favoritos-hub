
import React, { useState } from 'react';
import { useDrag, useDrop } from 'react-dnd';
import { Button } from '@/components/ui/button';
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuTrigger } from '@/components/ui/dropdown-menu';
import { ChevronDown, ChevronRight, MoreHorizontal, Edit, Trash2, ExternalLink, Copy } from 'lucide-react';
import { Bookmark, DragItem } from '@/types/bookmark';
import { useBookmarks } from '@/contexts/BookmarkContext';
import { cn } from '@/lib/utils';
import { toast } from '@/hooks/use-toast';

interface BookmarkItemProps {
  bookmark: Bookmark;
  level: number;
  onEdit: (bookmark: Bookmark) => void;
}

export const BookmarkItem: React.FC<BookmarkItemProps> = ({ bookmark, level, onEdit }) => {
  const { 
    selectedBookmark, 
    setSelectedBookmark, 
    deleteBookmark, 
    moveBookmark, 
    expandedFolders, 
    toggleFolder 
  } = useBookmarks();
  const [isHovered, setIsHovered] = useState(false);

  const isExpanded = expandedFolders.has(bookmark.id);
  const isSelected = selectedBookmark?.id === bookmark.id;

  const [{ isDragging }, dragRef] = useDrag({
    type: 'bookmark',
    item: { id: bookmark.id, type: 'bookmark', bookmark } as DragItem,
    collect: (monitor) => ({
      isDragging: monitor.isDragging(),
    }),
  });

  const [{ isOver, canDrop }, dropRef] = useDrop({
    accept: 'bookmark',
    drop: (item: DragItem) => {
      if (item.id !== bookmark.id && bookmark.type === 'folder') {
        moveBookmark(item.id, bookmark.id);
        toast({
          title: "Movido com sucesso",
          description: `"${item.bookmark.title}" foi movido para "${bookmark.title}"`,
        });
      }
    },
    canDrop: (item: DragItem) => {
      return item.id !== bookmark.id && bookmark.type === 'folder';
    },
    collect: (monitor) => ({
      isOver: monitor.isOver(),
      canDrop: monitor.canDrop(),
    }),
  });

  const handleClick = () => {
    if (bookmark.type === 'folder') {
      toggleFolder(bookmark.id);
    }
    setSelectedBookmark(bookmark);
  };

  const handleDelete = () => {
    deleteBookmark(bookmark.id);
    toast({
      title: "Excluído com sucesso",
      description: `"${bookmark.title}" foi excluído`,
    });
  };

  const handleCopyUrl = () => {
    if (bookmark.url) {
      navigator.clipboard.writeText(bookmark.url);
      toast({
        title: "URL copiada",
        description: "URL copiada para a área de transferência",
      });
    }
  };

  const handleOpenLink = () => {
    if (bookmark.url) {
      window.open(bookmark.url, '_blank');
    }
  };

  const combinedRef = (node: HTMLDivElement) => {
    dragRef(node);
    dropRef(node);
  };

  return (
    <div className="relative">
      <div
        ref={combinedRef}
        className={cn(
          'group flex items-center gap-2 px-3 py-2 rounded-lg cursor-pointer transition-all duration-200',
          'hover:bg-sidebar-accent/50',
          isSelected && 'bg-sidebar-accent text-sidebar-accent-foreground',
          isDragging && 'opacity-50',
          isOver && canDrop && 'bg-loop-purple-500/20 border border-loop-purple-400/50',
          level > 0 && 'ml-4'
        )}
        style={{ paddingLeft: `${12 + level * 16}px` }}
        onClick={handleClick}
        onMouseEnter={() => setIsHovered(true)}
        onMouseLeave={() => setIsHovered(false)}
      >
        {bookmark.type === 'folder' && (
          <Button
            variant="ghost"
            size="sm"
            className="p-0 h-4 w-4 hover:bg-transparent"
            onClick={(e) => {
              e.stopPropagation();
              toggleFolder(bookmark.id);
            }}
          >
            {isExpanded ? (
              <ChevronDown className="w-3 h-3" />
            ) : (
              <ChevronRight className="w-3 h-3" />
            )}
          </Button>
        )}

        <span className="text-lg flex-shrink-0">
          {bookmark.icon || (bookmark.type === 'folder' ? '📁' : '🔗')}
        </span>

        <span className="text-sm font-medium truncate flex-1 min-w-0">
          {bookmark.title}
        </span>

        {(isHovered || isSelected) && (
          <DropdownMenu>
            <DropdownMenuTrigger asChild>
              <Button
                variant="ghost"
                size="sm"
                className="p-0 h-6 w-6 opacity-0 group-hover:opacity-100 transition-opacity"
                onClick={(e) => e.stopPropagation()}
              >
                <MoreHorizontal className="w-4 h-4" />
              </Button>
            </DropdownMenuTrigger>
            <DropdownMenuContent align="end" className="w-48">
              <DropdownMenuItem onClick={() => onEdit(bookmark)}>
                <Edit className="w-4 h-4 mr-2" />
                Editar
              </DropdownMenuItem>
              {bookmark.type === 'link' && bookmark.url && (
                <>
                  <DropdownMenuItem onClick={handleOpenLink}>
                    <ExternalLink className="w-4 h-4 mr-2" />
                    Abrir link
                  </DropdownMenuItem>
                  <DropdownMenuItem onClick={handleCopyUrl}>
                    <Copy className="w-4 h-4 mr-2" />
                    Copiar URL
                  </DropdownMenuItem>
                </>
              )}
              <DropdownMenuItem 
                onClick={handleDelete}
                className="text-destructive focus:text-destructive"
              >
                <Trash2 className="w-4 h-4 mr-2" />
                Excluir
              </DropdownMenuItem>
            </DropdownMenuContent>
          </DropdownMenu>
        )}
      </div>

      {bookmark.type === 'folder' && isExpanded && bookmark.children && (
        <div className="animate-accordion-down">
          {bookmark.children.map((child) => (
            <BookmarkItem
              key={child.id}
              bookmark={child}
              level={level + 1}
              onEdit={onEdit}
            />
          ))}
        </div>
      )}
    </div>
  );
};
