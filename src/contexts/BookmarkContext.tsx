
import React, { createContext, useContext, useState, useCallback } from 'react';
import { Bookmark, BookmarkContextType } from '@/types/bookmark';
import { mockBookmarks } from '@/data/mockData';

const BookmarkContext = createContext<BookmarkContextType | undefined>(undefined);

export const useBookmarks = () => {
  const context = useContext(BookmarkContext);
  if (!context) {
    throw new Error('useBookmarks must be used within a BookmarkProvider');
  }
  return context;
};

const flattenBookmarks = (bookmarks: Bookmark[]): Bookmark[] => {
  const result: Bookmark[] = [];
  
  const traverse = (items: Bookmark[]) => {
    items.forEach(item => {
      result.push(item);
      if (item.children) {
        traverse(item.children);
      }
    });
  };
  
  traverse(bookmarks);
  return result;
};

const buildHierarchy = (flatList: Bookmark[]): Bookmark[] => {
  const map = new Map<string, Bookmark>();
  const roots: Bookmark[] = [];

  // Create a map of all bookmarks
  flatList.forEach(bookmark => {
    map.set(bookmark.id, { ...bookmark, children: [] });
  });

  // Build the hierarchy
  flatList.forEach(bookmark => {
    const bookmarkNode = map.get(bookmark.id)!;
    if (bookmark.parentId) {
      const parent = map.get(bookmark.parentId);
      if (parent) {
        parent.children = parent.children || [];
        parent.children.push(bookmarkNode);
      }
    } else {
      roots.push(bookmarkNode);
    }
  });

  // Sort children by order
  const sortChildren = (items: Bookmark[]) => {
    items.sort((a, b) => a.order - b.order);
    items.forEach(item => {
      if (item.children) {
        sortChildren(item.children);
      }
    });
  };

  sortChildren(roots);
  return roots;
};

export const BookmarkProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [flatBookmarks, setFlatBookmarks] = useState<Bookmark[]>(flattenBookmarks(mockBookmarks));
  const [selectedBookmark, setSelectedBookmark] = useState<Bookmark | null>(null);
  const [expandedFolders, setExpandedFolders] = useState<Set<string>>(new Set(['1', '2', '5', '7']));

  const bookmarks = buildHierarchy(flatBookmarks);

  const addBookmark = useCallback((newBookmark: Omit<Bookmark, 'id' | 'createdAt' | 'updatedAt'>) => {
    const bookmark: Bookmark = {
      ...newBookmark,
      id: `bookmark_${Date.now()}_${Math.random().toString(36).substr(2, 9)}`,
      createdAt: new Date(),
      updatedAt: new Date(),
    };

    setFlatBookmarks(prev => [...prev, bookmark]);
  }, []);

  const updateBookmark = useCallback((id: string, updates: Partial<Bookmark>) => {
    setFlatBookmarks(prev => 
      prev.map(bookmark => 
        bookmark.id === id 
          ? { ...bookmark, ...updates, updatedAt: new Date() }
          : bookmark
      )
    );
  }, []);

  const deleteBookmark = useCallback((id: string) => {
    const deleteRecursively = (bookmarkId: string) => {
      const children = flatBookmarks.filter(b => b.parentId === bookmarkId);
      children.forEach(child => deleteRecursively(child.id));
      setFlatBookmarks(prev => prev.filter(b => b.id !== bookmarkId));
    };

    deleteRecursively(id);
    if (selectedBookmark?.id === id) {
      setSelectedBookmark(null);
    }
  }, [flatBookmarks, selectedBookmark]);

  const moveBookmark = useCallback((bookmarkId: string, newParentId?: string, newOrder?: number) => {
    setFlatBookmarks(prev => {
      const bookmark = prev.find(b => b.id === bookmarkId);
      if (!bookmark) return prev;

      // Get siblings in the new parent
      const siblings = prev.filter(b => b.parentId === newParentId && b.id !== bookmarkId);
      const finalOrder = newOrder !== undefined ? newOrder : siblings.length;

      // Update order of affected siblings
      const updatedBookmarks = prev.map(b => {
        if (b.id === bookmarkId) {
          return { ...b, parentId: newParentId, order: finalOrder, updatedAt: new Date() };
        }
        if (b.parentId === newParentId && b.order >= finalOrder) {
          return { ...b, order: b.order + 1, updatedAt: new Date() };
        }
        return b;
      });

      return updatedBookmarks;
    });
  }, []);

  const toggleFolder = useCallback((folderId: string) => {
    setExpandedFolders(prev => {
      const newSet = new Set(prev);
      if (newSet.has(folderId)) {
        newSet.delete(folderId);
      } else {
        newSet.add(folderId);
      }
      return newSet;
    });
  }, []);

  const value: BookmarkContextType = {
    bookmarks,
    selectedBookmark,
    setSelectedBookmark,
    addBookmark,
    updateBookmark,
    deleteBookmark,
    moveBookmark,
    expandedFolders,
    toggleFolder,
  };

  return (
    <BookmarkContext.Provider value={value}>
      {children}
    </BookmarkContext.Provider>
  );
};
