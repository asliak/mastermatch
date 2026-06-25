from django.test import TestCase
from django.contrib.auth.models import User
from rest_framework.test import APIClient
from rest_framework import status
from rest_framework.authtoken.models import Token
from .models import FavoriteProgram

class SocialAuthTests(TestCase):
    def setUp(self):
        self.client = APIClient()

    def test_google_sandbox_auth_success(self):
        response = self.client.post('/api/auth/google/', {'id_token': 'sandbox-google-test_user'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertEqual(response.data['username'], 'test_user')
        self.assertEqual(response.data['email'], 'test_user@gmail.com')
        
        # Verify user and token were created
        self.assertTrue(User.objects.filter(username='test_user').exists())
        user = User.objects.get(username='test_user')
        self.assertTrue(Token.objects.filter(user=user).exists())

    def test_google_auth_missing_token(self):
        response = self.client.post('/api/auth/google/', {}, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)

    def test_apple_sandbox_auth_success(self):
        response = self.client.post('/api/auth/apple/', {'identity_token': 'sandbox-apple-clara'}, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertIn('token', response.data)
        self.assertEqual(response.data['username'], 'clara')
        self.assertEqual(response.data['email'], 'clara@apple.com')
        
        # Verify user was created
        self.assertTrue(User.objects.filter(username='clara').exists())

    def test_apple_auth_missing_token(self):
        response = self.client.post('/api/auth/apple/', {}, format='json')
        self.assertEqual(response.status_code, status.HTTP_400_BAD_REQUEST)
        self.assertIn('error', response.data)


class FavoriteTests(TestCase):
    def setUp(self):
        self.client = APIClient()
        self.user = User.objects.create_user(username='test_user', password='password123')
        self.token, _ = Token.objects.get_or_create(user=self.user)
        self.program_university = 'TU Delft'
        self.program_name = 'MSc Electrical Engineering'

    def test_anonymous_toggle_fails(self):
        response = self.client.post('/favorites/toggle/', {
            'university_name': self.program_university,
            'program_name': self.program_name
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_401_UNAUTHORIZED)
        self.assertFalse(FavoriteProgram.objects.filter(user=self.user).exists())

    def test_anonymous_list_redirects(self):
        response = self.client.get('/favorites/')
        self.assertEqual(response.status_code, status.HTTP_302_FOUND)

    def test_authenticated_toggle_creates_favorite(self):
        self.client.login(username='test_user', password='password123')
        response = self.client.post('/favorites/toggle/', {
            'university_name': self.program_university,
            'program_name': self.program_name
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()['success'])
        self.assertTrue(response.json()['favorited'])
        self.assertTrue(FavoriteProgram.objects.filter(
            user=self.user,
            university_name=self.program_university,
            program_name=self.program_name
        ).exists())

    def test_authenticated_toggle_removes_favorite(self):
        FavoriteProgram.objects.create(
            user=self.user,
            university_name=self.program_university,
            program_name=self.program_name
        )
        self.client.login(username='test_user', password='password123')
        response = self.client.post('/favorites/toggle/', {
            'university_name': self.program_university,
            'program_name': self.program_name
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.json()['success'])
        self.assertFalse(response.json()['favorited'])
        self.assertFalse(FavoriteProgram.objects.filter(
            user=self.user,
            university_name=self.program_university,
            program_name=self.program_name
        ).exists())

    def test_favorites_list_loads_correctly(self):
        FavoriteProgram.objects.create(
            user=self.user,
            university_name=self.program_university,
            program_name=self.program_name
        )
        from django.test import Client
        c = Client()
        c.login(username='test_user', password='password123')
        response = c.get('/favorites/')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'TU Delft')
        self.assertContains(response, 'MSc Electrical Engineering')
        self.assertContains(response, 'Netherlands')

    def test_api_favorites_endpoint(self):
        self.client.credentials(HTTP_AUTHORIZATION='Token ' + self.token.key)
        
        response = self.client.get('/api/favorites/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 0)
        
        response = self.client.post('/api/favorites/', {
            'university_name': self.program_university,
            'program_name': self.program_name
        }, format='json')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertTrue(response.data['success'])
        self.assertTrue(response.data['favorited'])
        
        response = self.client.get('/api/favorites/')
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(len(response.data), 1)
        self.assertEqual(response.data[0]['university'], self.program_university)
        self.assertEqual(response.data[0]['program'], self.program_name)


class StandalonePageViewsTests(TestCase):
    def setUp(self):
        self.user = User.objects.create_user(username='test_user', password='password123')
        
    def test_anonymous_profile_redirects(self):
        response = self.client.get('/profile/')
        self.assertEqual(response.status_code, 302)
        
    def test_authenticated_profile_loads(self):
        self.client.login(username='test_user', password='password123')
        response = self.client.get('/profile/')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'profile settings')

    def test_anonymous_calendar_redirects(self):
        response = self.client.get('/calendar/')
        self.assertEqual(response.status_code, 302)

    def test_authenticated_calendar_loads(self):
        self.client.login(username='test_user', password='password123')
        response = self.client.get('/calendar/')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'deadline calendar')

    def test_anonymous_notes_redirects(self):
        response = self.client.get('/notes/')
        self.assertEqual(response.status_code, 302)

    def test_authenticated_notes_loads(self):
        self.client.login(username='test_user', password='password123')
        response = self.client.get('/notes/')
        self.assertEqual(response.status_code, 200)
        self.assertContains(response, 'tasks & notes')



