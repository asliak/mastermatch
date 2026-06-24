# MasterMatch 🎓
> AI-powered master's program finder — EE 471 Final Project

## Project Structure
```
mastermatch/
├── app.py              # Flask backend & routes
├── matcher.py          # Matching algorithm (HuggingFace embeddings)
├── requirements.txt    # Python dependencies
├── data/
│   └── programs.csv    # 64 programs dataset
└── templates/
    └── index.html      # Frontend (form + results dashboard)
```

## Setup & Run

### 1. Create a virtual environment
```bash
python -m venv venv
source venv/bin/activate        # Mac/Linux
venv\Scripts\activate           # Windows
```

### 2. Install dependencies
```bash
pip install -r requirements.txt
```
> Note: First install downloads the sentence-transformer model (~90MB). This only happens once.

### 3. Run the app
```bash
python app.py
```

### 4. Open in browser
```
http://localhost:5000
```

## How It Works

1. **User fills profile form** → field, GPA, budget, interests, career goals, country preferences
2. **Hard filters** → removes programs where GPA or budget don't match
3. **Semantic matching** → HuggingFace `all-MiniLM-L6-v2` encodes both the student profile and each program description into vectors
4. **Cosine similarity** → measures how close the profile vector is to each program vector
5. **Ranked results** → top 10 matches shown with match score, explanation, and program details

## Syllabus Coverage

| Week | Topic | Used In |
|------|-------|---------|
| Week 3 | OOP in Python | `ProgramMatcher` class in `matcher.py` |
| Week 9 | HuggingFace Transformers | Sentence embeddings for semantic matching |
| Week 11 | Flask | Backend routing in `app.py` |
| Week 4 | Clean Coding | Structured, documented codebase |
| Week 6 | Docker | (optional) containerize with Dockerfile |

## Optional: Add Kaggle Rankings
Download `cwurData.csv` from kaggle.com/datasets/mylesoneill/world-university-rankings
and merge with programs.csv on `university_name` to add world ranking scores.
