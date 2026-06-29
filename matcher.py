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

    def _calculate_hybrid_score(self, program: dict, profile: dict, raw_semantic_score: float) -> float:
        # 1. Semantic Score (0 to 100)
        min_raw = 0.15
        max_raw = 0.58
        if raw_semantic_score <= min_raw:
            s_sem = 0.0
        elif raw_semantic_score >= max_raw:
            s_sem = 100.0
        else:
            s_sem = (raw_semantic_score - min_raw) / (max_raw - min_raw) * 100.0

        # 2. Tag/Keyword Overlap Score (0 to 100)
        user_text = (profile["interests"] + " " + profile["field"]).lower()
        user_words = set(user_text.replace(",", " ").replace(";", " ").split())
        stop_words = {"and", "or", "in", "of", "to", "the", "a", "an", "for", "with", "is", "my", "i", "interested"}
        user_words = user_words - stop_words
        
        prog_text = (program["field_tags"] + " " + program["program_name"]).lower()
        prog_words = set(prog_text.replace(",", " ").replace(";", " ").split()) - stop_words
        
        overlap = user_words & prog_words
        s_tag = min(100.0, len(overlap) * 25.0)

        # 3. GPA Buffer Score (0 to 100)
        if profile["gpa"] > 0:
            gpa_diff = profile["gpa"] - program["min_gpa"]
            if gpa_diff < 0:
                s_gpa = 0.0
            else:
                # 50 base points for meeting requirement, up to 50 additional points for exceeding by 0.5+ GPA
                s_gpa = 50.0 + min(50.0, gpa_diff * 100.0)
        else:
            s_gpa = 75.0

        # 4. Budget Buffer Score (0 to 100)
        if profile["budget"] > 0 and profile["budget"] >= program["tuition_usd_year"]:
            if program["tuition_usd_year"] == 0:
                s_budget = 100.0
            else:
                s_budget = (1.0 - program["tuition_usd_year"] / profile["budget"]) * 100.0
        else:
            s_budget = 75.0

        # Weighting: 50% Semantic, 20% Tag, 15% GPA, 15% Budget
        final_score = (0.50 * s_sem) + (0.20 * s_tag) + (0.15 * s_gpa) + (0.15 * s_budget)
        
        # Clip to standard display bounds [30.0, 98.0]
        final_score = max(30.0, min(98.0, final_score))
        return round(final_score, 1)

    # ------------------------------------------------------------------
    # Explanation generation
    # ------------------------------------------------------------------

    def _explain(self, program: dict, profile: dict, scaled_score: float) -> str:
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

        if scaled_score > 85.0:
            reasons.append("strong semantic match to your profile")
        elif scaled_score > 65.0:
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

        # Build results with hybrid score
        hybrid_ranked = []
        for raw_sem_score, program in ranked:
            h_score = self._calculate_hybrid_score(program, profile, float(raw_sem_score))
            hybrid_ranked.append((h_score, program))

        # Sort by hybrid score descending
        hybrid_ranked.sort(key=lambda x: x[0], reverse=True)

        # Build response
        results = []
        for score, program in hybrid_ranked[:top_n]:
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
                "score":        score,
                "explanation":  self._explain(program, profile, score),
            })

        return results


