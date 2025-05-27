
export interface Bookmark {
  id: string;
  title: string;
  url?: string;
  icon?: string;
  type: 'folder' | 'link';
  parentId?: string;
  children?: Bookmark[];
  description?: string;
  tags?: string[];
  createdAt: Date;
  updatedAt: Date;
  order: number;
}

export interface BookmarkContextType {
  bookmarks: Bookmark[];
  selectedBookmark: Bookmark | null;
  setSelectedBookmark: (bookmark: Bookmark | null) => void;
  addBookmark: (bookmark: Omit<Bookmark, 'id' | 'createdAt' | 'updatedAt'>) => void;
  updateBookmark: (id: string, updates: Partial<Bookmark>) => void;
  deleteBookmark: (id: string) => void;
  moveBookmark: (bookmarkId: string, newParentId?: string, newOrder?: number) => void;
  expandedFolders: Set<string>;
  toggleFolder: (folderId: string) => void;
}

export interface DragItem {
  id: string;
  type: 'bookmark';
  bookmark: Bookmark;
}
