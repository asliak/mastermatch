from django.shortcuts import render, redirect
from django.contrib.auth import login, authenticate, logout
from django.contrib.auth.models import User
from django.contrib.auth.forms import UserCreationForm
from django.http import JsonResponse
from django.views.decorators.csrf import ensure_csrf_cookie, csrf_exempt
from django.utils.decorators import method_decorator
from django.conf import settings

from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions
from rest_framework.authtoken.models import Token
from rest_framework.authentication import TokenAuthentication

import json
from .models import UserProfile, FavoriteProgram
from .serializers import UserProfileSerializer
from .matcher_instance import get_matcher

# ------------------------------------------------------------------
# Web HTML Views
# ------------------------------------------------------------------

def index(request):
    profile_data = {}
    favorites_data = []
    
    # Load matcher to get all loaded programs and dynamic counts
    matcher = get_matcher()
    num_programs = len(matcher.programs)
    num_countries = len(set(p['country'].strip() for p in matcher.programs))
    
    if request.user.is_authenticated:
        # Load user profile
        profile = request.user.profile
        profile_data = {
            "field": profile.field_of_study,
            "gpa": profile.gpa,
            "budget": profile.budget,
            "interests": profile.interests,
            "career_goals": profile.career_goals,
            "countries": profile.countries_list,
        }
        
        # Load user favorites
        favs = FavoriteProgram.objects.filter(user=request.user).order_by('-created_at')
        programs_by_key = {(p['university_name'], p['program_name']): p for p in matcher.programs}
        for f in favs:
            p = programs_by_key.get((f.university_name, f.program_name))
            if p:
                favorites_data.append({
                    "university": p["university_name"],
                    "program": p["program_name"],
                    "country": p["country"],
                    "city": p["city"],
                    "tuition": p["tuition_usd_year"],
                    "min_gpa": p["min_gpa"],
                    "duration": p["duration_years"],
                    "field_tags": p["field_tags"],
                    "scholarship": p["scholarship_available"],
                    "deadline": p["deadline_month"],
                    "url": p["program_url"],
                    "description": p["description"],
                })

    return render(request, "index.html", {
        "profile_data_json": json.dumps(profile_data),
        "profile": request.user.profile if request.user.is_authenticated else None,
        "num_programs": num_programs,
        "num_countries": num_countries,
        "favorites_data_json": json.dumps(favorites_data),
    })

def login_view(request):
    if request.user.is_authenticated:
        return redirect('index')
        
    error = None
    if request.method == "POST":
        username = request.POST.get("username", "").strip()
        password = request.POST.get("password", "")
        user = authenticate(request, username=username, password=password)
        if user is not None:
            login(request, user)
            return redirect('index')
        else:
            error = "Invalid username or password."
            
    google_client_id = getattr(settings, 'GOOGLE_CLIENT_ID', '')
    return render(request, "login.html", {
        "error": error,
        "google_client_id": google_client_id
    })

def register_view(request):
    if request.user.is_authenticated:
        return redirect('index')
        
    error = None
    if request.method == "POST":
        username = request.POST.get("username", "").strip()
        email = request.POST.get("email", "").strip()
        password = request.POST.get("password", "")
        password_confirm = request.POST.get("password_confirm", "")
        
        if not username or not password:
            error = "Username and password are required."
        elif password != password_confirm:
            error = "Passwords do not match."
        elif User.objects.filter(username=username).exists():
            error = "Username is already taken."
        else:
            try:
                user = User.objects.create_user(username=username, email=email, password=password)
                login(request, user)
                return redirect('index')
            except Exception as e:
                error = f"Error creating user: {str(e)}"
                
    google_client_id = getattr(settings, 'GOOGLE_CLIENT_ID', '')
    return render(request, "register.html", {
        "error": error,
        "google_client_id": google_client_id
    })

def logout_view(request):
    logout(request)
    return redirect('index')

# AJAX endpoint for matching (called by web frontend)
@csrf_exempt
def match_view(request):
    if request.method != "POST":
        return JsonResponse({"error": "POST method required"}, status=400)
        
    try:
        data = json.loads(request.body)
    except Exception:
        return JsonResponse({"error": "Invalid JSON"}, status=400)
        
    profile = {
        "interests":    data.get("interests", ""),
        "gpa":          float(data.get("gpa", 0) or 0),
        "budget":       float(data.get("budget", 999999) or 999999),
        "countries":    data.get("countries", []),
        "field":        data.get("field", ""),
        "career_goals": data.get("career_goals", ""),
    }
    
    # Auto-save profile if user is authenticated
    if request.user.is_authenticated:
        user_prof = request.user.profile
        user_prof.field_of_study = profile["field"]
        user_prof.gpa = profile["gpa"]
        user_prof.budget = profile["budget"]
        user_prof.interests = profile["interests"]
        user_prof.career_goals = profile["career_goals"]
        user_prof.countries_list = profile["countries"]
        user_prof.save()
        
    matcher = get_matcher()
    results = matcher.match(profile, top_n=20)
    
    # Add favorites status
    if request.user.is_authenticated:
        favorited_keys = set(
            FavoriteProgram.objects.filter(user=request.user)
            .values_list('university_name', 'program_name')
        )
        for r in results:
            r["is_favorited"] = (r["university"], r["program"]) in favorited_keys
    else:
        for r in results:
            r["is_favorited"] = False
            
    return JsonResponse(results, safe=False)


@csrf_exempt
def save_profile_view(request):
    if not request.user.is_authenticated:
        return JsonResponse({"error": "Authentication required"}, status=401)
        
    if request.method != "POST":
        return JsonResponse({"error": "POST method required"}, status=400)
        
    try:
        data = json.loads(request.body)
        profile = request.user.profile
        profile.field_of_study = data.get("field", "")
        profile.gpa = float(data.get("gpa", 0) or 0)
        profile.budget = float(data.get("budget", 999999) or 999999)
        profile.interests = data.get("interests", "")
        profile.career_goals = data.get("career_goals", "")
        profile.countries_list = data.get("countries", [])
        profile.save()
        return JsonResponse({"success": True})
    except Exception as e:
        return JsonResponse({"error": str(e)}, status=400)


# ------------------------------------------------------------------
# REST API Views (for Mobile Client)
# ------------------------------------------------------------------

class APIRegisterView(APIView):
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        username = request.data.get("username", "").strip()
        email = request.data.get("email", "").strip()
        password = request.data.get("password", "")
        
        if not username or not password:
            return Response({"error": "Username and password are required."}, status=status.HTTP_400_BAD_REQUEST)
            
        if User.objects.filter(username=username).exists():
            return Response({"error": "Username is already taken."}, status=status.HTTP_400_BAD_REQUEST)
            
        try:
            user = User.objects.create_user(username=username, email=email, password=password)
            token, _ = Token.objects.get_or_create(user=user)
            return Response({
                "token": token.key,
                "username": user.username,
                "email": user.email
            }, status=status.HTTP_201_CREATED)
        except Exception as e:
            return Response({"error": f"Failed to create user: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)

class APILoginView(APIView):
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        username = request.data.get("username", "").strip()
        password = request.data.get("password", "")
        
        user = authenticate(username=username, password=password)
        if user is not None:
            token, _ = Token.objects.get_or_create(user=user)
            return Response({
                "token": token.key,
                "username": user.username,
                "email": user.email
            }, status=status.HTTP_200_OK)
        return Response({"error": "Invalid username or password."}, status=status.HTTP_400_BAD_REQUEST)

class APIProfileView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [TokenAuthentication]
    
    def get(self, request):
        serializer = UserProfileSerializer(request.user.profile)
        return Response(serializer.data)
        
    def post(self, request):
        serializer = UserProfileSerializer(request.user.profile, data=request.data, context={'request': request}, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

class APIMatchView(APIView):
    permission_classes = [permissions.AllowAny]
    
    # Support token auth optionally (if user is logged in on mobile, auto-save profile)
    def post(self, request):
        data = request.data
        
        profile = {
            "interests":    data.get("interests", ""),
            "gpa":          float(data.get("gpa", 0) or 0),
            "budget":       float(data.get("budget", 999999) or 999999),
            "countries":    data.get("countries", []),
            "field":        data.get("field", ""),
            "career_goals": data.get("career_goals", ""),
        }
        
        # If token was supplied, auto-save profile for the user
        auth_user = None
        auth_header = request.headers.get('Authorization', '')
        if auth_header.startswith('Token '):
            token_key = auth_header.split(' ')[1]
            try:
                token = Token.objects.get(key=token_key)
                auth_user = token.user
                user_prof = auth_user.profile
                user_prof.field_of_study = profile["field"]
                user_prof.gpa = profile["gpa"]
                user_prof.budget = profile["budget"]
                user_prof.interests = profile["interests"]
                user_prof.career_goals = profile["career_goals"]
                user_prof.countries_list = profile["countries"]
                user_prof.save()
            except Token.DoesNotExist:
                pass # Invalid token, do not save but still allow matching
                
        matcher = get_matcher()
        results = matcher.match(profile, top_n=20)
        
        # Add favorites status
        if auth_user:
            favorited_keys = set(
                FavoriteProgram.objects.filter(user=auth_user)
                .values_list('university_name', 'program_name')
            )
            for r in results:
                r["is_favorited"] = (r["university"], r["program"]) in favorited_keys
        else:
            for r in results:
                r["is_favorited"] = False
                
        return Response(results)


# ------------------------------------------------------------------
# Social OAuth Authentication Views (Google & Apple)
# ------------------------------------------------------------------
import requests

class APIGoogleAuthView(APIView):
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        id_token = request.data.get("id_token", "")
        if not id_token:
            return Response({"error": "id_token is required"}, status=status.HTTP_400_BAD_REQUEST)
            
        username = None
        email = None
        
        # Check for Sandbox Mode
        if id_token.startswith("sandbox-google-"):
            username = id_token.replace("sandbox-google-", "").strip()
            email = f"{username}@gmail.com"
        else:
            # Real Google Auth Validation
            try:
                res = requests.get(f"https://oauth2.googleapis.com/tokeninfo?id_token={id_token}", timeout=10)
                if res.status_code == 200:
                    info = res.json()
                    email = info.get("email")
                    username = email.split("@")[0] if email else None
                else:
                    return Response({"error": "Invalid Google token"}, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                return Response({"error": f"Google connection error: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
                
        if not username:
            return Response({"error": "Could not retrieve user info from token"}, status=status.HTTP_400_BAD_REQUEST)
            
        user, _ = User.objects.get_or_create(username=username, defaults={"email": email})
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            "token": token.key,
            "username": user.username,
            "email": user.email
        }, status=status.HTTP_200_OK)

class APIAppleAuthView(APIView):
    permission_classes = [permissions.AllowAny]
    
    def post(self, request):
        identity_token = request.data.get("identity_token", "")
        if not identity_token:
            return Response({"error": "identity_token is required"}, status=status.HTTP_400_BAD_REQUEST)
            
        username = None
        email = None
        
        # Check for Sandbox Mode
        if identity_token.startswith("sandbox-apple-"):
            username = identity_token.replace("sandbox-apple-", "").strip()
            email = f"{username}@apple.com"
        else:
            # Real Apple Auth validation (JWT parsing)
            try:
                parts = identity_token.split(".")
                if len(parts) == 3:
                    payload_b64 = parts[1]
                    payload_b64 += "=" * ((4 - len(payload_b64) % 4) % 4)
                    import base64
                    payload = json.loads(base64.b64decode(payload_b64).decode("utf-8"))
                    email = payload.get("email")
                    sub = payload.get("sub")
                    username = email.split("@")[0] if email else f"apple_user_{sub[:8]}"
                else:
                    return Response({"error": "Invalid Apple token structure"}, status=status.HTTP_400_BAD_REQUEST)
            except Exception as e:
                return Response({"error": f"Apple token decoding error: {str(e)}"}, status=status.HTTP_400_BAD_REQUEST)
                
        if not username:
            return Response({"error": "Could not retrieve user info"}, status=status.HTTP_400_BAD_REQUEST)
            
        user, _ = User.objects.get_or_create(username=username, defaults={"email": email or ""})
        token, _ = Token.objects.get_or_create(user=user)
        return Response({
            "token": token.key,
            "username": user.username,
            "email": user.email
        }, status=status.HTTP_200_OK)

# Web social auth login endpoint (registers session for index page)
@csrf_exempt
def web_social_auth_view(request):
    try:
        if request.method != "POST":
            return JsonResponse({"error": "POST required"}, status=400)
            
        try:
            data = json.loads(request.body)
        except Exception:
            return JsonResponse({"error": "Invalid JSON"}, status=400)
            
        provider = data.get("provider", "")
        token = data.get("token", "")
        
        if not provider or not token:
            return JsonResponse({"error": "provider and token are required"}, status=400)
            
        username = None
        email = None
        
        if provider == "google":
            if token.startswith("sandbox-google-"):
                username = token.replace("sandbox-google-", "").strip()
                email = f"{username}@gmail.com"
            else:
                try:
                    res = requests.get(f"https://oauth2.googleapis.com/tokeninfo?id_token={token}", timeout=10)
                    if res.status_code == 200:
                        info = res.json()
                        email = info.get("email")
                        username = email.split("@")[0] if email else None
                except Exception as ex:
                    return JsonResponse({"error": f"Failed calling Google API: {str(ex)}"}, status=400)
        elif provider == "apple":
            if token.startswith("sandbox-apple-"):
                username = token.replace("sandbox-apple-", "").strip()
                email = f"{username}@apple.com"
            else:
                try:
                    parts = token.split(".")
                    if len(parts) == 3:
                        payload_b64 = parts[1]
                        payload_b64 += "=" * ((4 - len(payload_b64) % 4) % 4)
                        import base64
                        payload = json.loads(base64.b64decode(payload_b64).decode("utf-8"))
                        email = payload.get("email")
                        sub = payload.get("sub")
                        username = email.split("@")[0] if email else f"apple_user_{sub[:8]}"
                except Exception as ex:
                    return JsonResponse({"error": f"Failed parsing Apple Token: {str(ex)}"}, status=400)
                     
        if not username:
            return JsonResponse({"error": "Invalid credentials or token info"}, status=400)
            
        user, _ = User.objects.get_or_create(username=username, defaults={"email": email or ""})
        login(request, user)
        return JsonResponse({"success": True, "username": user.username})
    except Exception as e:
        import traceback
        tb = traceback.format_exc()
        return JsonResponse({"error": f"Server crash: {str(e)}", "traceback": tb}, status=500)



# ── Favorites Endpoints (Web AJAX & Listing) ──────────────────────
@csrf_exempt
def toggle_favorite_view(request):
    if not request.user.is_authenticated:
        return JsonResponse({"error": "You must be logged in to favorite programs."}, status=401)
        
    if request.method != "POST":
        return JsonResponse({"error": "POST method required"}, status=400)
        
    try:
        data = json.loads(request.body)
    except Exception:
        return JsonResponse({"error": "Invalid JSON"}, status=400)
        
    university_name = data.get("university_name", "").strip()
    program_name = data.get("program_name", "").strip()
    
    if not university_name or not program_name:
        return JsonResponse({"error": "university_name and program_name are required"}, status=400)
        
    fav, created = FavoriteProgram.objects.get_or_create(
        user=request.user,
        university_name=university_name,
        program_name=program_name
    )
    
    if not created:
        fav.delete()
        favorited = False
    else:
        favorited = True
        
    return JsonResponse({"success": True, "favorited": favorited})


def favorites_list_view(request):
    if not request.user.is_authenticated:
        return redirect('login')
        
    favs = FavoriteProgram.objects.filter(user=request.user).order_by('-created_at')
    matcher = get_matcher()
    programs_by_key = {(p['university_name'], p['program_name']): p for p in matcher.programs}
    
    favorites_data = []
    for f in favs:
        p = programs_by_key.get((f.university_name, f.program_name))
        if p:
            favorites_data.append({
                "university": p["university_name"],
                "program": p["program_name"],
                "country": p["country"],
                "city": p["city"],
                "tuition": p["tuition_usd_year"],
                "min_gpa": p["min_gpa"],
                "duration": p["duration_years"],
                "field_tags": p["field_tags"],
                "tags": [t.strip() for t in p["field_tags"].split(",")][:3],
                "scholarship": p["scholarship_available"],
                "deadline": p["deadline_month"],
                "url": p["program_url"],
                "description": p["description"],
                "is_favorited": True,
            })
            
    return render(request, "favorites.html", {
        "favorites": favorites_data,
        "profile": request.user.profile if hasattr(request.user, 'profile') else None
    })


def profile_page_view(request):
    if not request.user.is_authenticated:
        return redirect('login')
        
    profile = request.user.profile if hasattr(request.user, 'profile') else None
    profile_data = {}
    if profile:
        profile_data = {
            "field": profile.field_of_study,
            "gpa": profile.gpa,
            "budget": profile.budget,
            "interests": profile.interests,
            "career_goals": profile.career_goals,
            "countries": profile.countries_list,
        }
        
    return render(request, "profile.html", {
        "profile": profile,
        "profile_data_json": json.dumps(profile_data),
    })


def calendar_page_view(request):
    if not request.user.is_authenticated:
        return redirect('login')
        
    favs = FavoriteProgram.objects.filter(user=request.user).order_by('-created_at')
    matcher = get_matcher()
    programs_by_key = {(p['university_name'], p['program_name']): p for p in matcher.programs}
    
    favorites_data = []
    for f in favs:
        p = programs_by_key.get((f.university_name, f.program_name))
        if p:
            favorites_data.append({
                "university": p["university_name"],
                "program": p["program_name"],
                "country": p["country"],
                "city": p["city"],
                "deadline": p["deadline_month"],
            })
            
    return render(request, "calendar.html", {
        "favorites_data_json": json.dumps(favorites_data),
    })


def notes_page_view(request):
    if not request.user.is_authenticated:
        return redirect('login')
        
    favs = FavoriteProgram.objects.filter(user=request.user).order_by('-created_at')
    matcher = get_matcher()
    programs_by_key = {(p['university_name'], p['program_name']): p for p in matcher.programs}
    
    favorites_data = []
    for f in favs:
        p = programs_by_key.get((f.university_name, f.program_name))
        if p:
            favorites_data.append({
                "university": p["university_name"],
                "program": p["program_name"],
                "country": p["country"],
                "city": p["city"],
                "deadline": p["deadline_month"],
            })
            
    return render(request, "notes.html", {
        "favorites": favorites_data,
    })



# ── REST API Favorites Endpoint (Mobile Client) ───────────────────
class APIFavoritesView(APIView):
    permission_classes = [permissions.IsAuthenticated]
    authentication_classes = [TokenAuthentication]
    
    def get(self, request):
        favs = FavoriteProgram.objects.filter(user=request.user).order_by('-created_at')
        matcher = get_matcher()
        programs_by_key = {(p['university_name'], p['program_name']): p for p in matcher.programs}
        
        favorites_data = []
        for f in favs:
            p = programs_by_key.get((f.university_name, f.program_name))
            if p:
                favorites_data.append({
                    "university": p["university_name"],
                    "program": p["program_name"],
                    "country": p["country"],
                    "city": p["city"],
                    "tuition": p["tuition_usd_year"],
                    "min_gpa": p["min_gpa"],
                    "duration": p["duration_years"],
                    "field_tags": p["field_tags"],
                    "tags": [t.strip() for t in p["field_tags"].split(",")][:3],
                    "scholarship": p["scholarship_available"],
                    "deadline": p["deadline_month"],
                    "url": p["program_url"],
                    "description": p["description"],
                    "is_favorited": True,
                })
        return Response(favorites_data)
        
    def post(self, request):
        university_name = request.data.get("university_name", "").strip()
        program_name = request.data.get("program_name", "").strip()
        
        if not university_name or not program_name:
            return Response({"error": "university_name and program_name are required"}, status=status.HTTP_400_BAD_REQUEST)
            
        fav, created = FavoriteProgram.objects.get_or_create(
            user=request.user,
            university_name=university_name,
            program_name=program_name
        )
        
        if not created:
            fav.delete()
            favorited = False
        else:
            favorited = True
            
        return Response({"success": True, "favorited": favorited})

def temp_reset_admin_password_view(request):
    from django.contrib.auth.models import User
    try:
        user, created = User.objects.get_or_create(
            username='admin', 
            defaults={'email': 'admin@example.com', 'is_staff': True, 'is_superuser': True}
        )
        user.set_password('admin123')
        user.is_staff = True
        user.is_superuser = True
        user.save()
        return JsonResponse({"success": True, "message": "Admin password has been reset to admin123 successfully! You can now log in at /admin/."})
    except Exception as e:
        return JsonResponse({"success": False, "error": str(e)})

