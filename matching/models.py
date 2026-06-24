from django.db import models
from django.contrib.auth.models import User
from django.db.models.signals import post_save
from django.dispatch import receiver
import json

class UserProfile(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    field_of_study = models.CharField(max_length=200, blank=True, default='')
    gpa = models.FloatField(default=0.0)
    budget = models.FloatField(default=999999.0)
    interests = models.CharField(max_length=500, blank=True, default='')
    career_goals = models.TextField(blank=True, default='')
    countries = models.TextField(blank=True, default='[]')  # Stores JSON list of countries

    def __str__(self):
        return f"{self.user.username}'s Profile"

    @property
    def countries_list(self):
        try:
            return json.loads(self.countries)
        except Exception:
            return []

    @countries_list.setter
    def countries_list(self, val):
        self.countries = json.dumps(val)

# Signal receivers to automatically manage UserProfile lifecycle
@receiver(post_save, sender=User)
def create_user_profile(sender, instance, created, **kwargs):
    if created:
        UserProfile.objects.create(user=instance)

@receiver(post_save, sender=User)
def save_user_profile(sender, instance, **kwargs):
    if hasattr(instance, 'profile'):
        instance.profile.save()


class FavoriteProgram(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='favorites')
    university_name = models.CharField(max_length=255)
    program_name = models.CharField(max_length=255)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        unique_together = ('user', 'university_name', 'program_name')

    def __str__(self):
        return f"{self.user.username} - {self.program_name} at {self.university_name}"

