from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile
import json

class UserProfileSerializer(serializers.ModelSerializer):
    countries = serializers.SerializerMethodField()

    class Meta:
        model = UserProfile
        fields = ['field_of_study', 'gpa', 'budget', 'interests', 'career_goals', 'countries']

    def get_countries(self, obj):
        return obj.countries_list

    def update(self, instance, validated_data):
        instance.field_of_study = validated_data.get('field_of_study', instance.field_of_study)
        instance.gpa = validated_data.get('gpa', instance.gpa)
        instance.budget = validated_data.get('budget', instance.budget)
        instance.interests = validated_data.get('interests', instance.interests)
        instance.career_goals = validated_data.get('career_goals', instance.career_goals)
        
        # Pull request data for countries, which might be in context
        request = self.context.get('request')
        if request and 'countries' in request.data:
            countries_list = request.data['countries']
            if isinstance(countries_list, list):
                instance.countries_list = countries_list
            elif isinstance(countries_list, str):
                try:
                    instance.countries_list = json.loads(countries_list)
                except Exception:
                    instance.countries = countries_list
                    
        instance.save()
        return instance
