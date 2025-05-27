
import React, { useState } from 'react';
import { BookmarkProvider } from '@/contexts/BookmarkContext';
import { BookmarkSidebar } from '@/components/BookmarkSidebar';
import { BookmarkDetails } from '@/components/BookmarkDetails';
import { BookmarkModal } from '@/components/BookmarkModal';
import { useBookmarks } from '@/contexts/BookmarkContext';

const MainContent: React.FC = () => {
  const [isEditModalOpen, setIsEditModalOpen] = useState(false);
  const { selectedBookmark } = useBookmarks();

  const handleEdit = () => {
    setIsEditModalOpen(true);
  };

  return (
    <div className="h-screen flex bg-background overflow-hidden">
      <BookmarkSidebar />
      <BookmarkDetails onEdit={handleEdit} />
      
      <BookmarkModal
        isOpen={isEditModalOpen}
        onClose={() => setIsEditModalOpen(false)}
        bookmark={selectedBookmark}
      />
    </div>
  );
};

const Index: React.FC = () => {
  return (
    <BookmarkProvider>
      <MainContent />
    </BookmarkProvider>
  );
};

export default Index;
