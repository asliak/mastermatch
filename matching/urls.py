from django.urls import path
from . import views

urlpatterns = [
    # HTML web routes
    path('', views.index, name='index'),
    path('login/', views.login_view, name='login'),
    path('register/', views.register_view, name='register'),
    path('logout/', views.logout_view, name='logout'),
    path('match', views.match_view, name='match'), # Web AJAX match endpoint
    
    path('favorites/', views.favorites_list_view, name='favorites_list'),
    path('favorites/toggle/', views.toggle_favorite_view, name='toggle_favorite'),
    
    # REST API endpoints (Mobile Client)
    path('api/auth/register/', views.APIRegisterView.as_view(), name='api_register'),
    path('api/auth/login/', views.APILoginView.as_view(), name='api_login'),
    path('api/auth/google/', views.APIGoogleAuthView.as_view(), name='api_auth_google'),
    path('api/auth/apple/', views.APIAppleAuthView.as_view(), name='api_auth_apple'),
    path('api/profile/', views.APIProfileView.as_view(), name='api_profile'),
    path('api/match/', views.APIMatchView.as_view(), name='api_match'),
    path('api/favorites/', views.APIFavoritesView.as_view(), name='api_favorites'),
    path('auth/social-web/', views.web_social_auth_view, name='web_social_auth'),
]
