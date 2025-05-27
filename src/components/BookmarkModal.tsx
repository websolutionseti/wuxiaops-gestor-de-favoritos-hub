
import React, { useState, useEffect } from 'react';
import { Dialog, DialogContent, DialogHeader, DialogTitle } from '@/components/ui/dialog';
import { Button } from '@/components/ui/button';
import { Input } from '@/components/ui/input';
import { Label } from '@/components/ui/label';
import { Textarea } from '@/components/ui/textarea';
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from '@/components/ui/select';
import { Badge } from '@/components/ui/badge';
import { X, Plus, Folder, Link, Upload } from 'lucide-react';
import { Bookmark } from '@/types/bookmark';
import { useBookmarks } from '@/contexts/BookmarkContext';
import { toast } from '@/hooks/use-toast';

interface BookmarkModalProps {
  isOpen: boolean;
  onClose: () => void;
  bookmark?: Bookmark | null;
}

export const BookmarkModal: React.FC<BookmarkModalProps> = ({ isOpen, onClose, bookmark }) => {
  const { addBookmark, updateBookmark, bookmarks } = useBookmarks();
  const [formData, setFormData] = useState({
    title: '',
    url: '',
    icon: '',
    type: 'link' as 'folder' | 'link',
    parentId: '',
    description: '',
    tags: [] as string[],
  });
  const [newTag, setNewTag] = useState('');

  const isEditing = !!bookmark;

  useEffect(() => {
    if (bookmark) {
      setFormData({
        title: bookmark.title,
        url: bookmark.url || '',
        icon: bookmark.icon || '',
        type: bookmark.type,
        parentId: bookmark.parentId || '',
        description: bookmark.description || '',
        tags: bookmark.tags || [],
      });
    } else {
      setFormData({
        title: '',
        url: '',
        icon: '',
        type: 'link',
        parentId: '',
        description: '',
        tags: [],
      });
    }
  }, [bookmark, isOpen]);

  const getAllFolders = (items: Bookmark[], excludeId?: string): Bookmark[] => {
    const folders: Bookmark[] = [];
    
    const traverse = (bookmarks: Bookmark[]) => {
      bookmarks.forEach(item => {
        if (item.type === 'folder' && item.id !== excludeId) {
          folders.push(item);
          if (item.children) {
            traverse(item.children);
          }
        }
      });
    };
    
    traverse(items);
    return folders;
  };

  const folders = getAllFolders(bookmarks, bookmark?.id);

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    
    if (!formData.title.trim()) {
      toast({
        title: "Erro",
        description: "O título é obrigatório",
        variant: "destructive",
      });
      return;
    }

    if (formData.type === 'link' && !formData.url.trim()) {
      toast({
        title: "Erro", 
        description: "A URL é obrigatória para links",
        variant: "destructive",
      });
      return;
    }

    const order = folders.filter(f => f.parentId === formData.parentId).length;

    const bookmarkData = {
      title: formData.title.trim(),
      url: formData.type === 'link' ? formData.url.trim() : undefined,
      icon: formData.icon.trim() || (formData.type === 'folder' ? '📁' : '🔗'),
      type: formData.type,
      parentId: formData.parentId || undefined,
      description: formData.description.trim(),
      tags: formData.tags,
      order,
    };

    if (isEditing) {
      updateBookmark(bookmark.id, bookmarkData);
      toast({
        title: "Sucesso",
        description: "Favorito atualizado com sucesso!",
      });
    } else {
      addBookmark(bookmarkData);
      toast({
        title: "Sucesso",
        description: "Favorito criado com sucesso!",
      });
    }

    onClose();
  };

  const addTag = () => {
    if (newTag.trim() && !formData.tags.includes(newTag.trim())) {
      setFormData(prev => ({
        ...prev,
        tags: [...prev.tags, newTag.trim()]
      }));
      setNewTag('');
    }
  };

  const removeTag = (tagToRemove: string) => {
    setFormData(prev => ({
      ...prev,
      tags: prev.tags.filter(tag => tag !== tagToRemove)
    }));
  };

  return (
    <Dialog open={isOpen} onOpenChange={onClose}>
      <DialogContent className="sm:max-w-[500px] bg-card border-border">
        <DialogHeader>
          <DialogTitle className="flex items-center gap-2 text-xl">
            {formData.type === 'folder' ? <Folder className="w-5 h-5" /> : <Link className="w-5 h-5" />}
            {isEditing ? 'Editar Favorito' : 'Novo Favorito'}
          </DialogTitle>
        </DialogHeader>

        <form onSubmit={handleSubmit} className="space-y-6">
          <div className="grid grid-cols-2 gap-4">
            <div className="space-y-2">
              <Label htmlFor="type">Tipo</Label>
              <Select 
                value={formData.type} 
                onValueChange={(value: 'folder' | 'link') => 
                  setFormData(prev => ({ ...prev, type: value, url: value === 'folder' ? '' : prev.url }))
                }
              >
                <SelectTrigger>
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="link">🔗 Link</SelectItem>
                  <SelectItem value="folder">📁 Pasta</SelectItem>
                </SelectContent>
              </Select>
            </div>

            <div className="space-y-2">
              <Label htmlFor="icon">Ícone</Label>
              <div className="flex gap-2">
                <Input
                  id="icon"
                  value={formData.icon}
                  onChange={(e) => setFormData(prev => ({ ...prev, icon: e.target.value }))}
                  placeholder="📁 ou 🔗"
                  className="flex-1"
                />
                <Button type="button" variant="outline" size="icon">
                  <Upload className="w-4 h-4" />
                </Button>
              </div>
            </div>
          </div>

          <div className="space-y-2">
            <Label htmlFor="title">Título *</Label>
            <Input
              id="title"
              value={formData.title}
              onChange={(e) => setFormData(prev => ({ ...prev, title: e.target.value }))}
              placeholder="Digite o título do favorito"
              required
            />
          </div>

          {formData.type === 'link' && (
            <div className="space-y-2">
              <Label htmlFor="url">URL *</Label>
              <Input
                id="url"
                type="url"
                value={formData.url}
                onChange={(e) => setFormData(prev => ({ ...prev, url: e.target.value }))}
                placeholder="https://example.com"
                required
              />
            </div>
          )}

          <div className="space-y-2">
            <Label htmlFor="parentId">Pasta Pai</Label>
            <Select value={formData.parentId} onValueChange={(value) => setFormData(prev => ({ ...prev, parentId: value }))}>
              <SelectTrigger>
                <SelectValue placeholder="Selecione uma pasta (opcional)" />
              </SelectTrigger>
              <SelectContent>
                <SelectItem value="">🏠 Raiz</SelectItem>
                {folders.map((folder) => (
                  <SelectItem key={folder.id} value={folder.id}>
                    {folder.icon} {folder.title}
                  </SelectItem>
                ))}
              </SelectContent>
            </Select>
          </div>

          <div className="space-y-2">
            <Label htmlFor="description">Descrição</Label>
            <Textarea
              id="description"
              value={formData.description}
              onChange={(e) => setFormData(prev => ({ ...prev, description: e.target.value }))}
              placeholder="Descrição opcional do favorito"
              rows={3}
            />
          </div>

          <div className="space-y-2">
            <Label>Tags</Label>
            <div className="flex gap-2 mb-2">
              <Input
                value={newTag}
                onChange={(e) => setNewTag(e.target.value)}
                placeholder="Adicionar tag"
                onKeyPress={(e) => e.key === 'Enter' && (e.preventDefault(), addTag())}
                className="flex-1"
              />
              <Button type="button" onClick={addTag} variant="outline" size="icon">
                <Plus className="w-4 h-4" />
              </Button>
            </div>
            <div className="flex flex-wrap gap-2">
              {formData.tags.map((tag) => (
                <Badge key={tag} variant="secondary" className="flex items-center gap-1">
                  {tag}
                  <button
                    type="button"
                    onClick={() => removeTag(tag)}
                    className="hover:text-destructive"
                  >
                    <X className="w-3 h-3" />
                  </button>
                </Badge>
              ))}
            </div>
          </div>

          <div className="flex justify-end gap-2 pt-4">
            <Button type="button" variant="outline" onClick={onClose}>
              Cancelar
            </Button>
            <Button type="submit" className="bg-loop-purple-600 hover:bg-loop-purple-700">
              {isEditing ? 'Atualizar' : 'Criar'}
            </Button>
          </div>
        </form>
      </DialogContent>
    </Dialog>
  );
};
