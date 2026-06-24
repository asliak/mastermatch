from django.contrib import admin
from .models import UserProfile, FavoriteProgram

@admin.register(UserProfile)
class UserProfileAdmin(admin.ModelAdmin):
    list_display = ('user', 'field_of_study', 'gpa', 'budget')
    search_fields = ('user__username', 'field_of_study', 'interests', 'career_goals')

@admin.register(FavoriteProgram)
class FavoriteProgramAdmin(admin.ModelAdmin):
    list_display = ('user', 'university_name', 'program_name', 'created_at')
    search_fields = ('user__username', 'university_name', 'program_name')

