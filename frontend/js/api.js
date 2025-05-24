const API_URL = window.location.hostname === 'localhost' 
  ? 'http://localhost:3000/api' 
  : `http://${window.location.hostname}/api`;
  
export const api = {
    getNotes: async () => {
        try {
            const response = await fetch(`${API_URL}/notes`);
            if (!response.ok) throw new Error('Failed to fetch notes');
            return await response.json();
        } catch (error) {
            console.error('Error fetching notes:', error);
            return [];
        }
    },
    
    createNote: async (note) => {
        try {
            const response = await fetch(`${API_URL}/notes`, {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(note)
            });
            if (!response.ok) throw new Error('Failed to create note');
            return await response.json();
        } catch (error) {
            console.error('Error creating note:', error);
            return null;
        }
    },
    
    updateNote: async (id, note) => {
        try {
            const response = await fetch(`${API_URL}/notes/${id}`, {
                method: 'PUT',
                headers: {
                    'Content-Type': 'application/json'
                },
                body: JSON.stringify(note)
            });
            if (!response.ok) throw new Error('Failed to update note');
            return await response.json();
        } catch (error) {
            console.error('Error updating note:', error);
            return null;
        }
    },
    
    deleteNote: async (id) => {
        try {
            const response = await fetch(`${API_URL}/notes/${id}`, {
                method: 'DELETE'
            });
            if (!response.ok) throw new Error('Failed to delete note');
            return true;
        } catch (error) {
            console.error('Error deleting note:', error);
            return false;
        }
    }
};

export default api;
