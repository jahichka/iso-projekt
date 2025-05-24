import { api } from './api.js';

const notesList = document.getElementById('notesList');
const titleInput = document.getElementById('noteTitle');
const contentInput = document.getElementById('noteContent');
const categoryInput = document.getElementById('recipeCategory');
const cookTimeInput = document.getElementById('recipeCookTime');
const saveButton = document.getElementById('saveNote');

let currentNoteId = null;

document.addEventListener('DOMContentLoaded', loadRecipes);

saveButton.addEventListener('click', saveRecipe);

async function loadRecipes() {
    const recipes = await api.getNotes();
    renderRecipes(recipes);
}

function renderRecipes(recipes) {
    notesList.innerHTML = '';
    
    if (recipes.length === 0) {
        notesList.innerHTML = '<div class="empty-state">No recipes yet. Add your first recipe above!</div>';
        return;
    }
    
    recipes.forEach(recipe => {
        let category = 'Recipe';
        let cookTime = '30';
        
        if (recipe.content.includes('CATEGORY:')) {
            const contentParts = recipe.content.split('\n');
            for (const part of contentParts) {
                if (part.startsWith('CATEGORY:')) {
                    category = part.replace('CATEGORY:', '').trim();
                }
                if (part.startsWith('COOK_TIME:')) {
                    cookTime = part.replace('COOK_TIME:', '').trim();
                }
            }
        }
        
        let displayContent = recipe.content
            .replace(/CATEGORY:.*\n/, '')
            .replace(/COOK_TIME:.*\n/, '');
        
        const recipeElement = document.createElement('div');
        recipeElement.className = 'note';
        recipeElement.innerHTML = `
            <span class="recipe-category">${category}</span>
            <h3>${recipe.title}</h3>
            <div class="recipe-time">
                <i class="fas fa-clock"></i>
                <span>${cookTime} minutes</span>
            </div>
            <p>${displayContent}</p>
            <div class="note-actions">
                <button class="edit-btn" data-id="${recipe._id}">Edit</button>
                <button class="delete-btn" data-id="${recipe._id}">Delete</button>
            </div>
        `;
        
        recipeElement.style.animationDelay = `${recipes.indexOf(recipe) * 0.1}s`;
        
        const editBtn = recipeElement.querySelector('.edit-btn');
        const deleteBtn = recipeElement.querySelector('.delete-btn');
        
        editBtn.addEventListener('click', () => editRecipe(recipe));
        deleteBtn.addEventListener('click', () => deleteRecipe(recipe._id));
        
        notesList.appendChild(recipeElement);
    });
}

async function saveRecipe() {
    const title = titleInput.value.trim();
    const rawContent = contentInput.value.trim();
    const category = categoryInput.value.trim();
    const cookTime = cookTimeInput.value.trim();
    
    if (!title || !rawContent) {
        alert('Please enter both recipe name and instructions');
        return;
    }
    
    const content = `CATEGORY:${category || 'Recipe'}\nCOOK_TIME:${cookTime || '30'}\n${rawContent}`;
    
    const recipeData = { title, content };
    let result;
    
    if (currentNoteId) {
        result = await api.updateNote(currentNoteId, recipeData);
        currentNoteId = null;
        saveButton.textContent = 'Save Recipe';
    } else {
        result = await api.createNote(recipeData);
    }
    
    if (result) {
        titleInput.value = '';
        contentInput.value = '';
        categoryInput.value = '';
        cookTimeInput.value = '';
        
        loadRecipes();
    }
}

function editRecipe(recipe) {
    let category = '';
    let cookTime = '';
    let content = recipe.content;
    
    if (recipe.content.includes('CATEGORY:')) {
        const contentParts = recipe.content.split('\n');
        for (const part of contentParts) {
            if (part.startsWith('CATEGORY:')) {
                category = part.replace('CATEGORY:', '').trim();
            }
            if (part.startsWith('COOK_TIME:')) {
                cookTime = part.replace('COOK_TIME:', '').trim();
            }
        }
        
        content = recipe.content
            .replace(/CATEGORY:.*\n/, '')
            .replace(/COOK_TIME:.*\n/, '');
    }
    
    titleInput.value = recipe.title;
    contentInput.value = content;
    categoryInput.value = category;
    cookTimeInput.value = cookTime;
    
    currentNoteId = recipe._id;
    saveButton.textContent = 'Update Recipe';
    
    titleInput.scrollIntoView({ behavior: 'smooth' });
}

async function deleteRecipe(id) {
    if (confirm('Are you sure you want to delete this recipe?')) {
        const success = await api.deleteNote(id);
        if (success) {
            loadRecipes();
        }
    }
}

if (import.meta.hot) {
    import.meta.hot.accept();
}
