const getApiUrl = () => {
  if (window.location.hostname === 'localhost' || window.location.hostname === '127.0.0.1') {
    return 'http://localhost:3000/api';
  }
  return `http://${window.location.hostname}/api`;
};

const API_URL = getApiUrl();

export const api = {
    getNotes: async () => {
        try {
            const response = await fetch(`${API_URL}/notes`);
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
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
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
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
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
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
            if (!response.ok) throw new Error(`HTTP error! status: ${response.status}`);
            return true;
        } catch (error) {
            console.error('Error deleting note:', error);
            return false;
        }
    }
};

export default api;