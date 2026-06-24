import csv
import numpy as np
from sentence_transformers import SentenceTransformer
from sklearn.metrics.pairwise import cosine_similarity

class ProgramMatcher:
    def __init__(self, csv_path: str):
        """Load programs and pre-compute embeddings on startup."""
        print("Loading model...")
        # Lightweight but effective model — no GPU needed
        self.model = SentenceTransformer("all-MiniLM-L6-v2")

        print("Loading programs...")
        self.programs = self._load_programs(csv_path)

        print("Computing program embeddings...")
        self.program_embeddings = self._embed_programs()
        print(f"Ready — {len(self.programs)} programs loaded.")

    # ------------------------------------------------------------------
    # Data loading
    # ------------------------------------------------------------------

    def _load_programs(self, path: str) -> list[dict]:
        programs = []
        with open(path, newline="", encoding="utf-8") as f:
            for row in csv.DictReader(f):
                row["tuition_usd_year"] = float(row["tuition_usd_year"])
                row["min_gpa"]          = float(row["min_gpa"])
                row["duration_years"]   = float(row["duration_years"])
                row["scholarship_available"] = row["scholarship_available"].strip().lower() == "true"
                programs.append(row)
        return programs

    # ------------------------------------------------------------------
    # Embedding helpers
    # ------------------------------------------------------------------

    def _program_text(self, p: dict) -> str:
        """Combine the most descriptive fields into one string for embedding."""
        return (
            f"{p['program_name']} at {p['university_name']} in {p['country']}. "
            f"Fields: {p['field_tags']}. "
            f"{p['description']}"
        )

    def _embed_programs(self) -> np.ndarray:
        texts = [self._program_text(p) for p in self.programs]
        return self.model.encode(texts, convert_to_numpy=True)

    def _embed_profile(self, profile: dict) -> np.ndarray:
        """Turn the student profile into a single embedding."""
        text = (
            f"I am interested in {profile['interests']}. "
            f"My field of study is {profile['field']}. "
            f"My career goals are: {profile['career_goals']}."
        )
        return self.model.encode([text], convert_to_numpy=True)

    # ------------------------------------------------------------------
    # Hard filters
    # ------------------------------------------------------------------

    def _passes_filters(self, program: dict, profile: dict) -> bool:
        # GPA check
        if profile["gpa"] > 0 and profile["gpa"] < program["min_gpa"]:
            return False
        # Budget check
        if profile["budget"] > 0 and program["tuition_usd_year"] > profile["budget"]:
            return False
        # Country preference (empty list = no preference)
        if profile["countries"]:
            preferred = [c.lower() for c in profile["countries"]]
            if program["country"].lower() not in preferred:
                return False
        return True

    # ------------------------------------------------------------------
    # Explanation generation
    # ------------------------------------------------------------------

    def _explain(self, program: dict, profile: dict, score: float) -> str:
        reasons = []

        if profile["gpa"] >= program["min_gpa"]:
            reasons.append(f"your GPA meets the requirement (min {program['min_gpa']})")

        user_tags = set(profile["interests"].lower().split())
        prog_tags = set(program["field_tags"].lower().replace(",", " ").split())
        overlap   = user_tags & prog_tags
        if overlap:
            reasons.append(f"your interests overlap with {', '.join(list(overlap)[:3])}")

        if program["tuition_usd_year"] == 0:
            reasons.append("tuition is free")
        elif program["tuition_usd_year"] < 5000:
            reasons.append(f"very affordable tuition (${program['tuition_usd_year']:,.0f}/yr)")

        if program["scholarship_available"]:
            reasons.append("scholarships are available")

        if score > 0.7:
            reasons.append("strong semantic match to your profile")
        elif score > 0.5:
            reasons.append("good alignment with your stated goals")

        if not reasons:
            return "General match based on your profile."
        return "Match because: " + "; ".join(reasons) + "."

    # ------------------------------------------------------------------
    # Main match method
    # ------------------------------------------------------------------

    def match(self, profile: dict, top_n: int = 10) -> list[dict]:
        profile_embedding = self._embed_profile(profile)

        # Cosine similarity between profile and all programs
        scores = cosine_similarity(profile_embedding, self.program_embeddings)[0]

        # Pair each program with its score and filter
        ranked = []
        for i, program in enumerate(self.programs):
            if not self._passes_filters(program, profile):
                continue
            ranked.append((scores[i], program))

        # Sort by score descending
        ranked.sort(key=lambda x: x[0], reverse=True)

        # Build response
        results = []
        for score, program in ranked[:top_n]:
            results.append({
                "university":   program["university_name"],
                "program":      program["program_name"],
                "country":      program["country"],
                "city":         program["city"],
                "tuition":      program["tuition_usd_year"],
                "min_gpa":      program["min_gpa"],
                "duration":     program["duration_years"],
                "field_tags":   program["field_tags"],
                "scholarship":  program["scholarship_available"],
                "deadline":     program["deadline_month"],
                "url":          program["program_url"],
                "score":        round(float(score) * 100, 1),
                "explanation":  self._explain(program, profile, score),
            })

        return results
