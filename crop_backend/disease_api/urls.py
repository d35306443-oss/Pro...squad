from django.urls import path
from .views import CropImageUploadView

urlpatterns = [
    path("upload/", CropImageUploadView.as_view(), name="upload_image"),
]