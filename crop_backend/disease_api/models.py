from django.db import models


class CropImage(models.Model):

    image = models.ImageField(upload_to='crop_images/')

    disease_name = models.CharField(
        max_length=100,
        default="Unknown"
    )

    treatment = models.TextField(
        default="No treatment available"
    )

    created_at = models.DateTimeField(
        auto_now_add=True
    )


    def __str__(self):
        return self.disease_name
