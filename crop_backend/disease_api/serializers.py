from rest_framework import serializers
from .models import CropImage


class CropImageSerializer(serializers.ModelSerializer):

    class Meta:
        model = CropImage
        fields = "__all__"
        read_only_fields = (
            "disease_name",
            "treatment",
            "created_at",
        )